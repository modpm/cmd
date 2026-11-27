module cmd.nu_completion;

import std.algorithm;
import std.array;
import std.conv;
import std.regex;
import std.string;

import cmd.command;
import cmd.flag;
import cmd.program;
import cmd.value_type;

/** Generator of nushell completion scripts. */
package final class NuCompletion {
    /**
     * Generates a nushell completion script for the program and all its subcommands.
     *
     * Params:
     *   program = Program to generate the script for.
     */
    package static string generate(const(Program) program) {
        string quote(string text) {
            return "\"" ~ text.replace("\\", "\\\\").replace("\"", "\\\"") ~ "\"";
        }

        string line(string text) {
            return text.replace("\r", "").replace("\n", " ");
        }

        string label(string text) {
            return text.replaceAll(regex("[^A-Za-z0-9_]"), "_");
        }

        auto completers = appender!string;
        auto externs = appender!string;

        string type(string owner, string param, const(ValueType) valueType, bool dynamic, string parameter) {
            if (dynamic) {
                const name = "nu-complete " ~ owner ~ " " ~ param;
                completers.put(
                    "    def " ~ quote(name) ~ " [context: string] {\n"
                    ~ "        let prefix = ($context | split row \" \" | last)\n"
                    ~ "        try { run-external " ~ quote(program.name()) ~ " \"completion\" \"suggest\" \"--\" " ~ quote(parameter)
                    ~ " $prefix | lines } catch { [] }\n"
                    ~ "    }\n\n"
                );
                final switch (valueType.kind) {
                    case ValueType.Kind.file:
                        return "path@" ~ quote(name);
                    case ValueType.Kind.dir:
                        return "directory@" ~ quote(name);
                    case ValueType.Kind.integer:
                        return "int@" ~ quote(name);
                    case ValueType.Kind.choice:
                    case ValueType.Kind.text:
                        return "string@" ~ quote(name);
                }
            }
            final switch (valueType.kind) {
                case ValueType.Kind.file:
                    return "path";
                case ValueType.Kind.dir:
                    return "directory";
                case ValueType.Kind.choice:
                    const name = "nu-complete " ~ owner ~ " " ~ param;
                    completers.put(
                        "    def " ~ quote(name) ~ " [] {\n"
                        ~ "        [" ~ valueType.choices.map!(c => quote(c)).join(" ") ~ "]\n"
                        ~ "    }\n\n"
                    );
                    return "string@" ~ quote(name);
                case ValueType.Kind.integer:
                    return "int";
                case ValueType.Kind.text:
                    return "string";
            }
        }

        string flagSpec(const(Flag) flag) {
            if (flag.longName is null)
                return "-" ~ flag.shortName;
            return "--" ~ flag.longName ~ (flag.shortName is null ? "" : "(-" ~ flag.shortName ~ ")");
        }

        void visit(const(Command) cmd, string path) {
            string[] params;
            bool[string] seen;

            void add(const(Flag) flag, string valueType) {
                const key = flag.longName !is null ? flag.longName : flag.shortName;
                if (key in seen)
                    return;
                seen[key] = true;
                params ~= "        " ~ flagSpec(flag) ~ (valueType is null ? "" : ": " ~ valueType)
                    ~ (flag.description.empty() ? "" : " # " ~ line(flag.description));
            }

            const relative = path[program.name().length..$].strip();

            if (program.helpOption() !is null)
                add(program.helpOption(), null);
            if (program.versionOption() !is null)
                add(program.versionOption(), null);
            foreach (flag; cmd.flags)
                add(flag, null);
            foreach (opt; cmd.options)
                add(opt, type(
                    path,
                    opt.longName !is null ? opt.longName : opt.shortName,
                    opt.valueType,
                    opt.hasCompleter(),
                    relative ~ ":" ~ (opt.longName !is null ? "--" ~ opt.longName : "-" ~ opt.shortName)
                ));

            foreach (i, arg; cmd.arguments) {
                const name = label(arg.name);
                const valueType = type(path, name, arg.valueType, arg.hasCompleter(), relative ~ ":" ~ i.to!string);
                params ~= "        "
                    ~ (arg.variadic ? "..." ~ name ~ ": " : arg.required ? name ~ ": " : name ~ "?: ")
                    ~ valueType
                    ~ (arg.description.empty() ? "" : " # " ~ line(arg.description));
            }

            if (!cmd.description().empty())
                externs.put("    # " ~ line(cmd.description()) ~ "\n");
            externs.put("    export extern " ~ quote(path) ~ " [\n" ~ params.join("\n") ~ "\n    ]\n\n");

            foreach (sub; cmd.subcommands)
                visit(sub, path ~ " " ~ sub.name());
        }

        visit(program, program.name());

        const module_ = "completions-" ~ label(program.name());
        return "# nushell completion for " ~ program.name() ~ "\n\n"
            ~ "module " ~ module_ ~ " {\n"
            ~ completers.data
            ~ externs.data.stripRight() ~ "\n"
            ~ "}\n\n"
            ~ "use " ~ module_ ~ " *\n";
    }
}
