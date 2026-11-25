module cmd.pwsh_completion;

import std.algorithm;
import std.array;
import std.conv;
import std.string;

import cmd.command;
import cmd.flag;
import cmd.program;
import cmd.value_type;

/** Generator of PowerShell completion scripts. */
package final class PwshCompletion {
    /**
     * Generates a PowerShell completion script for the program and all its subcommands.
     *
     * Params:
     *   program = Program to generate the script for.
     */
    package static string generate(const(Program) program) {
        string quote(string text) {
            string result = "'";
            foreach (dchar c; text.replace("\r", "").replace("\n", " "))
                result ~= c.to!string ~ ("‘’‚‛'".canFind(c) ? c.to!string : "");
            return result ~ "'";
        }

        string[] names(const(Flag) flag) {
            string[] result;
            if (flag.shortName !is null)
                result ~= "-" ~ flag.shortName;
            if (flag.longName !is null)
                result ~= "--" ~ flag.longName;
            return result;
        }

        string[] value(const(ValueType) type) {
            final switch (type.kind) {
                case ValueType.Kind.file:
                    return ["file"];
                case ValueType.Kind.dir:
                    return ["dir"];
                case ValueType.Kind.choice:
                    return ["words"] ~ type.choices.dup;
                case ValueType.Kind.text:
                case ValueType.Kind.integer:
                    return null;
            }
        }

        string[] versionNames;
        if (program.versionOption() !is null)
            versionNames = names(program.versionOption());

        auto data = appender!string;
        auto values = appender!string;

        void visit(const(Command) cmd, string path) {
            string[string] subs;
            string[] subOrder;
            foreach (sub; cmd.subcommands) {
                subOrder ~= sub.name();
                subs[sub.name()] = sub.description();
            }

            string[] flagEntries;
            string[] optionEntries;
            bool[string] seen;
            void addFlag(ref string[] entries, const(Flag) flag) {
                foreach (name; names(flag))
                    if (name !in seen) {
                        seen[name] = true;
                        entries ~= "            " ~ quote(name) ~ " = " ~ quote(flag.description.empty() ? name : flag.description);
                    }
            }
            if (program.helpOption() !is null)
                addFlag(flagEntries, program.helpOption());
            if (program.versionOption() !is null)
                addFlag(flagEntries, program.versionOption());
            foreach (flag; cmd.flags)
                addFlag(flagEntries, flag);
            foreach (opt; cmd.options)
                addFlag(optionEntries, opt);

            string table(string[] entries) {
                return entries.empty() ? "[ordered]@{}" : "[ordered]@{\n" ~ entries.join("\n") ~ "\n        }";
            }

            data.put(
                "    " ~ quote(path) ~ " = @{\n"
                ~ "        Subs = " ~ table(subOrder.map!(n => "            " ~ quote(n) ~ " = " ~ quote(subs[n].empty() ? n : subs[n])).array) ~ "\n"
                ~ "        Flags = " ~ table(flagEntries) ~ "\n"
                ~ "        Opts = " ~ table(optionEntries) ~ "\n"
                ~ "    }\n"
            );

            foreach (opt; cmd.options) {
                const spec = value(opt.valueType);
                if (spec !is null)
                    foreach (name; names(opt))
                        values.put("    " ~ quote(path ~ ":" ~ name) ~ " = @(" ~ spec.map!(s => quote(s)).join(", ") ~ ")\n");
            }

            foreach (i, arg; cmd.arguments) {
                const spec = value(arg.valueType);
                const index = arg.variadic && i + 1 == cmd.arguments.length ? "*" : i.to!string;
                if (spec !is null)
                    values.put("    " ~ quote(path ~ ":" ~ index) ~ " = @(" ~ spec.map!(s => quote(s)).join(", ") ~ ")\n");
            }

            foreach (sub; cmd.subcommands)
                visit(sub, path.empty() ? sub.name() : path ~ " " ~ sub.name());
        }

        visit(program, "");

        return `# PowerShell completion for @PROGRAM@

$data = @{
@DATA@}

$values = @{
@VALUES@}

$versionNames = @(@VERSION@)

Register-ArgumentCompleter -Native -CommandName @NAME@ -ScriptBlock {
    param($wordToComplete, $commandAst, $cursorPosition)

    $Result = [System.Management.Automation.CompletionResult]
    $nothing = {
        if ($wordToComplete) { $Result::new($wordToComplete, $wordToComplete, 'ParameterValue', $wordToComplete) }
        else { $Result::new(' ', ' ', 'ParameterValue', ' ') }
    }
    $matching = {
        param($table, $type, $prefix)
        foreach ($name in $table.Keys) {
            if ($name.StartsWith($prefix, [System.StringComparison]::OrdinalIgnoreCase)) {
                $Result::new($name, $name, $type, $table[$name])
            }
        }
    }

    $words = @($commandAst.CommandElements | Select-Object -Skip 1 |
        Where-Object { $_.Extent.EndOffset -lt $cursorPosition } |
        ForEach-Object {
            if ($_ -is [System.Management.Automation.Language.StringConstantExpressionAst]) { $_.Value }
            else { $_.Extent.Text }
        })

    $cmd = ''
    $node = $data['']
    $ended = $false
    $pending = $null
    $npos = 0
    foreach ($w in $words) {
        if ($pending) {
            $pending = $null
            continue
        }
        if (-not $ended) {
            if ($w -eq '--') {
                $ended = $true
                continue
            }
            if ($w.StartsWith('-')) {
                if ($versionNames -contains $w) { return & $nothing }
                if ($node.Subs.Count -eq 0 -and -not $w.Contains('=') -and $node.Opts.Contains($w)) {
                    $pending = $w
                }
                continue
            }
        }
        if ($node.Subs.Count -gt 0) {
            if (-not $node.Subs.Contains($w)) { return & $nothing }
            $cmd = if ($cmd) { "$cmd $w" } else { $w }
            $node = $data[$cmd]
        }
        else {
            $npos++
        }
    }

    $prefix = $wordToComplete
    $pre = ''
    $opt = $null
    if ($pending) {
        $opt = $pending
    }
    elseif (-not $ended -and $wordToComplete.StartsWith('-')) {
        if ($node.Subs.Count -eq 0 -and $wordToComplete -match '^(-[^=]*)=(.*)$') {
            $opt = $Matches[1]
            $prefix = $Matches[2]
            if (-not $node.Opts.Contains($opt)) { return & $nothing }
            $pre = "$opt="
        }
        else {
            $found = @((& $matching $node.Flags 'ParameterName' $wordToComplete) + (& $matching $node.Opts 'ParameterName' $wordToComplete))
            if ($found.Count -eq 0) { return & $nothing }
            return $found
        }
    }

    if ($opt) {
        $spec = $values["${cmd}:$opt"]
    }
    elseif ($node.Subs.Count -gt 0) {
        $found = @(& $matching $node.Subs 'ParameterValue' $wordToComplete)
        if ($found.Count -eq 0) { return & $nothing }
        return $found
    }
    else {
        $spec = $values["${cmd}:$npos"]
        if (-not $spec) { $spec = $values["${cmd}:*"] }
    }

    $found = @()
    $kind = if ($spec) { $spec[0] }
    switch ($kind) {
        { $_ -in 'file', 'dir' } {
            $line = $(if ($_ -eq 'dir') { 'Set-Location ' } else { 'Get-Item ' }) + $prefix
            foreach ($m in [System.Management.Automation.CommandCompletion]::CompleteInput($line, $line.Length, $null).CompletionMatches) {
                $text = $m.CompletionText
                if ($pre) {
                    $text = if ($text -match '^[''"]') { $text.Substring(0, 1) + $pre + $text.Substring(1) } else { $pre + $text }
                }
                $found += $Result::new($text, $m.ListItemText, $m.ResultType, $m.ToolTip)
            }
        }
        'words' {
            foreach ($v in $spec[1..($spec.Count - 1)]) {
                if ($v.StartsWith($prefix, [System.StringComparison]::OrdinalIgnoreCase)) {
                    $found += $Result::new($pre + $v, $v, 'ParameterValue', $v)
                }
            }
        }
    }
    if ($found.Count -eq 0) { return & $nothing }
    $found
}.GetNewClosure()
`
            .replace("@PROGRAM@", program.name())
            .replace("@NAME@", quote(program.name()))
            .replace("@DATA@", data.data)
            .replace("@VALUES@", values.data)
            .replace("@VERSION@", versionNames.map!(n => quote(n)).join(", "));
    }
}
