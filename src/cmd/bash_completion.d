module cmd.bash_completion;

import std.algorithm;
import std.array;
import std.conv;
import std.regex;
import std.string;

import cmd.command;
import cmd.flag;
import cmd.program;
import cmd.value_type;

/** Generator of bash completion scripts. */
package final class BashCompletion {
    /**
     * Generates a bash completion script for the program and all its subcommands.
     *
     * Params:
     *   program = Program to generate the script for.
     */
    package static string generate(const(Program) program) {
        string quote(string text) {
            return "'" ~ text.replace("'", "'\\''") ~ "'";
        }

        string[] names(const(Flag) flag) {
            string[] result;
            if (flag.shortName !is null)
                result ~= "-" ~ flag.shortName;
            if (flag.longName !is null)
                result ~= "--" ~ flag.longName;
            return result;
        }

        string assignment(const(ValueType) type) {
            final switch (type.kind) {
                case ValueType.Kind.file:
                    return "kind=file";
                case ValueType.Kind.dir:
                    return "kind=dir";
                case ValueType.Kind.choice:
                    return "kind=words; values=" ~ quote(type.choices.join(" "));
                case ValueType.Kind.text:
                case ValueType.Kind.integer:
                    return null;
            }
        }

        string[] globalFlags;
        if (program.helpOption() !is null)
            globalFlags ~= names(program.helpOption());
        if (program.versionOption() !is null)
            globalFlags ~= names(program.versionOption());

        const versionNames = program.versionOption() !is null ? names(program.versionOption()).join(" ") : "";

        auto load = appender!string;
        auto option = appender!string;
        auto argument = appender!string;

        void visit(const(Command) cmd, string path) {
            string[] flagNames = globalFlags.dup;
            foreach (flag; cmd.flags)
                foreach (name; names(flag))
                    if (!flagNames.canFind(name))
                        flagNames ~= name;
            string[] optionNames;
            foreach (opt; cmd.options)
                optionNames ~= names(opt);

            load.put(
                "        " ~ quote(path) ~ ")\n"
                ~ "            subs=" ~ quote(cmd.subcommands.map!(c => c.name()).join(" ")) ~ "\n"
                ~ "            flags=" ~ quote(flagNames.join(" ")) ~ "\n"
                ~ "            opts=" ~ quote(optionNames.join(" ")) ~ "\n"
                ~ "            ;;\n"
            );

            foreach (opt; cmd.options) {
                const assign = assignment(opt.valueType);
                if (assign !is null)
                    option.put(
                        "        " ~ names(opt).map!(n => quote(path ~ ":" ~ n)).join("|") ~ ") " ~ assign ~ " ;;\n"
                    );
            }

            if (cmd.arguments.any!(a => assignment(a.valueType) !is null)) {
                argument.put("        " ~ quote(path) ~ ")\n            case \"$2\" in\n");
                foreach (i, arg; cmd.arguments) {
                    const pattern = arg.variadic && i + 1 == cmd.arguments.length ? "*" : i.to!string;
                    const assign = assignment(arg.valueType);
                    argument.put("                " ~ pattern ~ ") " ~ (assign is null ? "" : assign ~ " ") ~ ";;\n");
                }
                argument.put("            esac\n            ;;\n");
            }

            foreach (sub; cmd.subcommands)
                visit(sub, path.empty() ? sub.name() : path ~ " " ~ sub.name());
        }

        visit(program, "");

        return `# bash completion for @PROGRAM@

@FN@_load() {
    case "$1" in
@LOAD@
    esac
}

@FN@_option() {
    case "$1" in
@OPTION@
    esac
}

@FN@_argument() {
    case "$1" in
@ARGUMENT@
    esac
}

@FN@() {
    local cur cword cmd="" end=0 pending="" opt="" npos=0 eq=0 split=0 i last w prefix pre=""
    local subs flags opts kind values
    local -a words=()

    COMPREPLY=()
    for ((i = 0; i <= COMP_CWORD; i++)); do
        w=${COMP_WORDS[i]}
        last=$((${#words[@]} - 1))
        if [[ $w == = && $last -ge 0 ]]; then
            words[last]+='='
            eq=1
            split=1
        elif ((eq)); then
            words[last]+=$w
            eq=0
        else
            words+=("$w")
            split=0
        fi
    done
    cword=$((${#words[@]} - 1))
    cur=${words[cword]}

    @FN@_load ""
    for ((i = 1; i < cword; i++)); do
        w=${words[i]}
        if [[ -n $pending ]]; then
            pending=""
            continue
        fi
        if ((!end)); then
            if [[ $w == -- ]]; then
                end=1
                continue
            fi
            if [[ $w == -* ]]; then
                [[ " @VERSION@ " == *" $w "* ]] && return 0
                if [[ -z $subs && $w != *=* && " $opts " == *" $w "* ]]; then
                    pending=$w
                fi
                continue
            fi
        fi
        if [[ -n $subs ]]; then
            [[ " $subs " == *" $w "* ]] || return 0
            cmd=${cmd:+$cmd }$w
            @FN@_load "$cmd"
        else
            npos=$((npos + 1))
        fi
    done

    prefix=$cur
    if [[ -n $pending ]]; then
        opt=$pending
    elif ((!end)) && [[ $cur == -* ]]; then
        if [[ -z $subs && $cur == -*=* ]]; then
            opt=${cur%%=*}
            prefix=${cur#*=}
            [[ " $opts " == *" $opt "* ]] || return 0
            ((split)) || pre=$opt=
        else
            COMPREPLY=($(compgen -W "$flags $opts" -- "$cur"))
            return 0
        fi
    fi

    if [[ -n $opt ]]; then
        @FN@_option "$cmd:$opt"
    elif [[ -n $subs ]]; then
        COMPREPLY=($(compgen -W "$subs" -- "$cur"))
        return 0
    else
        @FN@_argument "$cmd" "$npos"
    fi

    case $kind in
        file)
            type compopt >/dev/null 2>&1 && compopt -o filenames
            while IFS= read -r w; do
                COMPREPLY+=("$w")
            done < <(compgen -f -- "$prefix")
            ;;
        dir)
            type compopt >/dev/null 2>&1 && compopt -o filenames
            while IFS= read -r w; do
                COMPREPLY+=("$w")
            done < <(compgen -d -- "$prefix")
            ;;
        words)
            COMPREPLY=($(compgen -W "$values" -- "$prefix"))
            ;;
    esac

    if [[ -n $pre ]]; then
        COMPREPLY=("${COMPREPLY[@]/#/$pre}")
    fi
}

complete -F @FN@ @NAME@
`
            .replace("@FN@", "_" ~ program.name().replaceAll(regex("[^A-Za-z0-9_]"), "_"))
            .replace("@NAME@", quote(program.name()))
            .replace("@PROGRAM@", program.name())
            .replace("@VERSION@", versionNames)
            .replace("@LOAD@", load.data.stripRight())
            .replace("@OPTION@", option.data.stripRight())
            .replace("@ARGUMENT@", argument.data.stripRight());
    }
}
