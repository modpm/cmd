module cmd.fish_completion;

import std.algorithm;
import std.array;
import std.conv;
import std.regex;
import std.string;

import cmd.command;
import cmd.flag;
import cmd.program;
import cmd.value_type;

/** Generator of fish completion scripts. */
package final class FishCompletion {
    /**
     * Generates a fish completion script for the program and all its subcommands.
     *
     * Params:
     *   program = Program to generate the script for.
     */
    package static string generate(const(Program) program) {
        string quote(string text) {
            return "'" ~ text.replace("\\", "\\\\").replace("'", "\\'") ~ "'";
        }

        string[] names(const(Flag) flag) {
            string[] result;
            if (flag.shortName !is null)
                result ~= "-" ~ flag.shortName;
            if (flag.longName !is null)
                result ~= "--" ~ flag.longName;
            return result;
        }

        string entry(string kind, string name, string description) {
            return "printf '%s\\t%s\\t%s\\n' " ~ kind ~ " " ~ quote(name) ~ " " ~ quote(description);
        }

        string value(const(ValueType) type) {
            final switch (type.kind) {
                case ValueType.Kind.file:
                    return "echo file";
                case ValueType.Kind.dir:
                    return "echo dir";
                case ValueType.Kind.choice:
                    return "printf '%s\\n' words " ~ type.choices.map!(c => quote(c)).join(" ");
                case ValueType.Kind.text:
                case ValueType.Kind.integer:
                    return null;
            }
        }

        auto load = appender!string;
        auto option = appender!string;
        auto argument = appender!string;

        void visit(const(Command) cmd, string path) {
            string[] lines;
            foreach (sub; cmd.subcommands)
                lines ~= entry("s", sub.name(), sub.description());

            bool[string] seen;
            void addFlag(string kind, const(Flag) flag) {
                foreach (name; names(flag))
                    if (name !in seen) {
                        seen[name] = true;
                        lines ~= entry(kind, name, flag.description);
                    }
            }
            if (program.helpOption() !is null)
                addFlag("f", program.helpOption());
            if (program.versionOption() !is null)
                addFlag("f", program.versionOption());
            foreach (flag; cmd.flags)
                addFlag("f", flag);
            foreach (opt; cmd.options)
                addFlag("o", opt);

            load.put("        case " ~ quote(path) ~ "\n" ~ lines.map!(l => "            " ~ l ~ "\n").join());

            foreach (opt; cmd.options) {
                const code = value(opt.valueType);
                if (code !is null)
                    option.put(
                        "        case " ~ names(opt).map!(n => quote(path ~ ":" ~ n)).join(" ") ~ "\n"
                        ~ "            " ~ code ~ "\n"
                    );
            }

            if (cmd.arguments.any!(a => value(a.valueType) !is null)) {
                argument.put("        case " ~ quote(path) ~ "\n            switch $argv[2]\n");
                foreach (i, arg; cmd.arguments) {
                    const pattern = arg.variadic && i + 1 == cmd.arguments.length ? "'*'" : i.to!string;
                    const code = value(arg.valueType);
                    argument.put("                case " ~ pattern ~ "\n" ~ (code is null ? "" : "                    " ~ code ~ "\n"));
                }
                argument.put("            end\n");
            }

            foreach (sub; cmd.subcommands)
                visit(sub, path.empty() ? sub.name() : path ~ " " ~ sub.name());
        }

        visit(program, "");

        return `# fish completion for @PROGRAM@

function @FN@_load
    switch $argv[1]
@LOAD@
    end
end

function @FN@_option
    switch $argv[1]
@OPTION@
    end
end

function @FN@_argument
    switch $argv[1]
@ARGUMENT@
    end
end

function @FN@_names
    set -l kind $argv[1]
    for entry in $argv[2..-1]
        set -l parts (string split \t -- $entry)
        if test "$parts[1]" = "$kind"
            echo $parts[2]
        end
    end
end

function @FN@
    set -l words (commandline -opc)
    set -e words[1]
    set -l cur (commandline -ct)
    set -l cmd ''
    set -l ended 0
    set -l pending ''
    set -l npos 0
    set -l entries (@FN@_load $cmd)
    set -l subs (@FN@_names s $entries)
    set -l opts (@FN@_names o $entries)

    for w in $words
        if test -n "$pending"
            set pending ''
            continue
        end
        if test $ended -eq 0
            if test "$w" = --
                set ended 1
                continue
            end
            if string match -q -- '-*' $w
                if test (count $subs) -eq 0; and not string match -q -- '*=*' $w; and contains -- $w $opts
                    set pending $w
                end
                continue
            end
        end
        if test (count $subs) -gt 0
            contains -- $w $subs; or return
            set cmd (string trim -- "$cmd $w")
            set entries (@FN@_load $cmd)
            set subs (@FN@_names s $entries)
            set opts (@FN@_names o $entries)
        else
            set npos (math $npos + 1)
        end
    end

    set -l opt ''
    set -l pre ''
    set -l prefix $cur
    if test -n "$pending"
        set opt $pending
    else if test $ended -eq 0; and string match -q -- '-*' $cur
        if test (count $subs) -eq 0; and string match -q -- '-*=*' $cur
            set opt (string replace -r -- '=.*' '' $cur)
            set prefix (string replace -r -- '^[^=]*=' '' $cur)
            contains -- $opt $opts; or return
            set pre $opt=
        else
            for e in $entries
                set -l parts (string split \t -- $e)
                if test "$parts[1]" != s
                    printf '%s\t%s\n' $parts[2] $parts[3]
                end
            end
            return
        end
    end

    set -l spec
    if test -n "$opt"
        set spec (@FN@_option "$cmd:$opt")
    else if test (count $subs) -gt 0
        for e in $entries
            set -l parts (string split \t -- $e)
            if test "$parts[1]" = s
                printf '%s\t%s\n' $parts[2] $parts[3]
            end
        end
        return
    else
        set spec (@FN@_argument "$cmd" $npos)
    end

    switch "$spec[1]"
        case file
            for p in (__fish_complete_path $prefix)
                printf '%s\n' $pre$p
            end
        case dir
            for p in (__fish_complete_directories $prefix)
                printf '%s\n' $pre$p
            end
        case words
            for v in $spec[2..-1]
                printf '%s\n' $pre$v
            end
    end
end

complete -c @NAME@ -f -a '(@FN@)'
`
            .replace("@FN@", "__" ~ program.name().replaceAll(regex("[^A-Za-z0-9_]"), "_"))
            .replace("@NAME@", quote(program.name()))
            .replace("@PROGRAM@", program.name())
            .replace("@LOAD@", load.data.stripRight())
            .replace("@OPTION@", option.data.stripRight())
            .replace("@ARGUMENT@", argument.data.stripRight());
    }
}
