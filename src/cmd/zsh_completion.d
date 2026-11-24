module cmd.zsh_completion;

import std.algorithm;
import std.array;
import std.conv;
import std.regex;
import std.string;

import cmd.command;
import cmd.flag;
import cmd.program;
import cmd.value_type;

/** Generator of zsh completion scripts. */
package final class ZshCompletion {
    /**
     * Generates a zsh completion script for the program and all its subcommands.
     *
     * Params:
     *   program = Program to generate the script for.
     */
    package static string generate(const(Program) program) {
        string quote(string text) {
            return "'" ~ text.replace("'", "'\\''") ~ "'";
        }

        string escape(string text) {
            return text.replace("\\", "\\\\").replace(":", "\\:").replace("[", "\\[").replace("]", "\\]");
        }

        string[] names(const(Flag) flag) {
            string[] result;
            if (flag.shortName !is null)
                result ~= "-" ~ flag.shortName;
            if (flag.longName !is null)
                result ~= "--" ~ flag.longName;
            return result;
        }

        string spec(string prefix, string[] spellings, string rest) {
            return spellings.length > 1
                ? quote(prefix) ~ "{" ~ spellings.join(",") ~ "}" ~ quote(rest)
                : quote(prefix ~ spellings[0] ~ rest);
        }

        string action(const(ValueType) type) {
            final switch (type.kind) {
                case ValueType.Kind.file:
                    return "_files";
                case ValueType.Kind.dir:
                    return "_files -/";
                case ValueType.Kind.choice:
                    return "(" ~ type.choices.map!(c => c.replace(" ", "\\ ")).join(" ") ~ ")";
                case ValueType.Kind.text:
                case ValueType.Kind.integer:
                    return " ";
            }
        }

        const root = "_" ~ program.name().replaceAll(regex("[^A-Za-z0-9_]"), "_");
        size_t counter = 0;
        auto functions = appender!string;

        string visit(const(Command) cmd, bool isRoot) {
            const name = isRoot ? root : root ~ "_" ~ (++counter).to!string;

            const(Flag)[] flags;
            void addFlag(const(Flag) flag) {
                if (!flags.any!(f => names(f) == names(flag)))
                    flags ~= flag;
            }
            if (program.helpOption() !is null)
                addFlag(program.helpOption());
            if (program.versionOption() !is null)
                addFlag(program.versionOption());
            foreach (flag; cmd.flags)
                addFlag(flag);

            string[] specs;
            foreach (flag; flags) {
                const global = flag is program.helpOption() || flag is program.versionOption();
                specs ~= spec(global ? "(- *)" : "*", names(flag), "[" ~ escape(flag.description) ~ "]");
            }
            foreach (opt; cmd.options)
                specs ~= spec(
                    "*",
                    names(opt).map!(n => n ~ "=").array,
                    "[" ~ escape(opt.description) ~ "]:" ~ escape(opt.paramName) ~ ":" ~ action(opt.valueType)
                );

            string[] dispatch;
            string[] listing;
            foreach (sub; cmd.subcommands) {
                const subName = visit(sub, false);
                const entry = sub.name().replace("\\", "\\\\").replace(":", "\\:");
                listing ~= quote(sub.description().empty() ? entry : entry ~ ":" ~ sub.description());
                dispatch ~= sub.name() ~ ") " ~ subName ~ " ;;";
            }

            if (!cmd.subcommands.empty()) {
                specs ~= quote("1: :->command");
                specs ~= quote("*:: :->args");
                functions.put(
                    name ~ "() {\n"
                    ~ "    local context state state_descr line\n"
                    ~ "    typeset -A opt_args\n\n"
                    ~ "    _arguments -C -s -S \\\n"
                    ~ specs.map!(s => "        " ~ s).join(" \\\n") ~ "\n\n"
                    ~ "    case $state in\n"
                    ~ "        command)\n"
                    ~ "            local -a commands=(\n"
                    ~ listing.map!(l => "                " ~ l).join("\n") ~ "\n"
                    ~ "            )\n"
                    ~ "            _describe -t commands 'command' commands\n"
                    ~ "            ;;\n"
                    ~ "        args)\n"
                    ~ "            case $line[1] in\n"
                    ~ dispatch.map!(d => "                " ~ d).join("\n") ~ "\n"
                    ~ "            esac\n"
                    ~ "            ;;\n"
                    ~ "    esac\n"
                    ~ "}\n\n"
                );
                return name;
            }

            foreach (i, arg; cmd.arguments) {
                const message = escape(arg.description.empty() ? arg.name : arg.description);
                const rest = message ~ ":" ~ action(arg.valueType);
                specs ~= quote(arg.variadic ? "*:" ~ rest : arg.required ? ":" ~ rest : "::" ~ rest);
            }
            functions.put(
                name ~ "() {\n"
                ~ (specs.empty()
                    ? "    return 1\n"
                    : "    _arguments -s -S \\\n" ~ specs.map!(s => "        " ~ s).join(" \\\n") ~ "\n")
                ~ "}\n\n"
            );
            return name;
        }

        visit(program, true);

        return "#compdef " ~ program.name() ~ "\n\n"
            ~ functions.data
            ~ "if [[ ${funcstack[1]} == " ~ root ~ " ]]; then\n"
            ~ "    " ~ root ~ " \"$@\"\n"
            ~ "else\n"
            ~ "    compdef " ~ root ~ " " ~ quote(program.name()) ~ "\n"
            ~ "fi\n";
    }
}
