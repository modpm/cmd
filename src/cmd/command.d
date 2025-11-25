module cmd.command;

import core.stdc.stdlib;
import std.algorithm;
import std.array;
import std.range : repeat;
import std.stdio;
import std.string;

import cmd.ansi;
import cmd.argument;
import cmd.document;
import cmd.flag;
import cmd.option;
import cmd.parsed_args;
import cmd.program;

/** Represents a command-line command. */
public class Command {
    private const string nameStr;
    private string descriptionStr;
    package Flag[] flags;
    package Option[] options;
    package Argument[] arguments;
    package Command[] subcommands;

    /** Chain of commands leading to this command. */
    public Command[] chain = null;
    private int delegate(ParsedArgs) actionDg;

    /**
     * Constructs a new command with the given name.
     *
     * Params:
     *   name = Name of the command.
     *
     * Throws:
     *   AssertionError if the name is empty.
     */
    public this(string name) @safe {
        assert(!name.empty(), "Command name must be non-empty");
        this.nameStr = name;
        this.actionDg = (args) => args.command.printHelp();
    }

    /** Gets the name of the command. */
    public string name() const nothrow @safe {
        return this.nameStr;
    }

    /** Sets the description of the command */
    public Command description(string description) nothrow @safe {
        this.descriptionStr = description;
        return this;
    }

    /** Gets the description of the command */
    public string description() const nothrow @safe {
        return this.descriptionStr;
    }

    /**
     * Searches for a subcommand with the specified name.
     *
     * This function can search either the immediate subcommands of this command
     * or recursively within a specified subcommand tree.
     *
     * Params:
     *   name  = The name of the subcommand to search for.
     *   root  = Optional. The command node to start the search from.
     *           - If `null`, the search is performed only among this command’s immediate subcommands.
     *           - If non-`null`, the search is recursive starting from `root` and checks all nested subcommands.
     *
     * Returns:
     *   The first `Command` matching the specified name, or `null` if no match is found.
     */
    public const(Command) findCommand(string name, const(Command) root = null) const nothrow @safe {
        if (root !is null && root.name() == name) return root;
        foreach (cmd; root is null ? subcommands : root.subcommands) {
            if (cmd.name() == name) return cmd;
            if (root !is null) {
                const Command found = findCommand(name, cmd);
                if (found !is null) return found;
            }
        }
        return null;
    }

    private const(Option) findOption(string query) const nothrow @safe {
        foreach (opt; options)
            if (opt.matches(query))
                return opt;
        return null;
    }

    private const(Flag) findFlag(string query) const nothrow @safe {
        foreach (flag; flags)
            if (flag.matches(query))
                return flag;
        return null;
    }

    private const(Argument) findArgument(string query) const nothrow @safe {
        foreach (arg; arguments)
            if (arg.name == query)
                return arg;
        return null;
    }

    /**
     * Adds a subcommand.
     *
     * Throws:
     *   AssertionError if subcommand already has a chain, if this command has arguments, or if a subcommand with the
     *   same name already exists.
     */
    public Command add(Command cmd) @safe {
        assert(cmd.chain is null, "Subcommand already has a command chain");
        assert(arguments.empty(), "Cannot add subcommands to a command that has arguments");
        assert(findCommand(cmd.name()) is null, "Command '" ~ cmd.name() ~ "' already exists");
        cmd.chain = this.chain ~ cmd;
        subcommands ~= cmd;
        return this;
    }

    /**
     * Adds a subcommand.
     *
     * Throws:
     *   AssertionError if subcommand already has a chain, if this command has arguments, or if a subcommand with the
     *   same name already exists.
     */
    public Command command(Command cmd) @safe {
        return add(cmd);
    }

    /**
     * Adds an option.
     *
     * Throws:
     *   AssertionError if an option with the same short or long name already exists.
     */
    public Command add(Option option) @safe {
        assert(findOption(option.shortName) is null, "Option '-" ~ option.shortName ~ "' already exists");
        assert(findOption(option.longName) is null, "Option '--" ~ option.longName ~ "' already exists");
        options ~= option;
        return this;
    }

    /**
     * Adds a flag.
     *
     * Throws:
     *   AssertionError if a flag with the same short or long name already exists.
     */
    public Command add(Flag flag) @safe {
        assert(findFlag(flag.shortName) is null, "Option '-" ~ flag.shortName ~ "' already exists");
        assert(findFlag(flag.longName) is null, "Option '--" ~ flag.longName ~ "' already exists");
        flags ~= flag;
        return this;
    }

    /**
     * Adds an option or flag from formatted string.
     *
     * Params:
     *   format = Formatted string defining option or flag.
     *   description = Description of the option or flag.
     *   defaultValue = Default value for option, or `null`.
     */
    public Command option(string format, string description, string defaultValue = null) @safe {
        if (format.canFind("<") || format.canFind("["))
            add(Option.fromString(format, description, defaultValue));
        else
            add(Flag.fromString(format, description));
        return this;
    }

    /**
     * Adds an argument.
     *
     * Throws:
     *   AssertionError if the command has subcommands or an argument with the same name already exists.
     */
    public Command add(Argument arg) @safe {
        assert(subcommands.empty(), "Cannot add arguments to a command that has subcommands");
        assert(findArgument(arg.name) is null, "Argument '" ~ arg.name ~ "' already exists");
        arguments ~= arg;
        return this;
    }

    /**
     * Adds an argument from formatted string.
     *
     * Params:
     *   format = Formatted string defining the argument.
     *   description = Description of the argument.
     *   defaultValue = Default value of the argument, or `null`.
     *
     * Throws:
     *   AssertionError if the argument format is invalid or an argument with the same name already exists.
     */
    public Command argument(string format, string description, string defaultValue = null) @safe {
        return add(Argument.fromString(format, description, defaultValue));
    }

    /**
     * Sets the action delegate to be executed for this command. The default action is to print help for the command.
     *
     * Params:
     *   action = Delegate to execute when command runs.
     */
    public Command action(int delegate(ParsedArgs) action) nothrow @safe {
        this.actionDg = action;
        return this;
    }

    /**
     * Gets the usage string for this command.
     *
     * Params:
     *   colors = Whether to use colors in the usage string.
     * Throws:
     *   AssertionError if command chain is null or empty, or if first command is not a Program.
     */
    public string usage(bool colors = false) const {
        assert(chain !is null, "Command chain is not initialised");
        assert(!chain.empty(), "Command chain is empty. The command should have at least itself in its chain.");
        Program program = cast(Program) chain[0];
        assert(program !is null, "First command in chain must be Program");

        Appender!string sb;
        sb.put(program.name());
        if (program.versionOption() || program.helpOption())
            sb.put(" "
                ~ "[".brightBlack() ~ ((chain.length > 1 ? "global " : "") ~ "options").dim() ~ "]".brightBlack());
        if (chain.length > 1)
            sb.put(" " ~ chain[1..$].map!(c => c.name()).array.join(" "));
        if (!subcommands.empty())
            sb.put(" " ~ "<".brightBlack() ~ "command".dim() ~ ">".brightBlack() ~ " " ~ "...".brightBlack());
        else {
            if (!options.empty() || !flags.empty())
                sb.put(" " ~ (options.any!(o => o.required)
                    ? "<".brightBlack() ~ "options".dim() ~ ">".brightBlack()
                    : "[".brightBlack() ~ "options".dim() ~ "]".brightBlack()
                ));
            foreach (arg; arguments)
                sb.put(" " ~ arg.formattedName(colors));
        }
        return colors ? sb.data : sb.data.stripAnsi();
    }

    /** Prints help for the command. */
    public int printHelp() const {
        auto doc = new Document();
        doc.add("Usage:".bold(), usage(true));
        
        if (descriptionStr !is null)
            doc.add("Description:".bold(), descriptionStr);

        if (subcommands !is null) {
            auto s = new Section("Commands:".bold());
            doc.add(s);

            foreach (cmd; (cast(Command[]) subcommands).dup.sort!((a, b) {
                return a.name() < b.name();
            })) s.add(cmd.name(), cmd.description());
        }

        if (arguments !is null) {
            auto s = new Section("Arguments:".bold());
            doc.add(s);

            foreach (arg; arguments)
                s.add(arg.name, arg.description);
        }

        if (!flags.empty() || !options.empty()) {
            auto s = new Section("Options:".bold());
            doc.add(s);

            foreach (opt; (cast(Flag[]) (flags ~ cast(Flag[]) options)).sort!((a, b) {
                auto nameA = a.longName !is null ? a.longName : a.shortName;
                auto nameB = b.longName !is null ? b.longName : b.shortName;
                return nameA < nameB;
            })) {
                if (Option o = cast(Option) opt)
                    s.add(o.formattedName(colors: true, padded: true), opt.description);
                else s.add(opt.formattedName(padded: true), opt.description);
            }
        }

        doc.print();
        return 0;
    }

    /** Prints an error message to stderr. */
    public void error(string description) const {
        stderr.writeln("error: " ~ description);
    }

    /** Prints an error message to stderr and exits with status. */
    public noreturn error(string description, int status) const {
        this.error(description);
        exit(status);
    }

    package ParsedArgs parse(const(string[]) args, const(Program) program) const {
        if (!subcommands.empty()) {
            auto index = args.countUntil!(a => !a.empty() && a.front() != '-');
            if (index >= 0) {
                const(Command) cmd = findCommand(args[index]);
                if (cmd is null)
                    error("unknown command '" ~ args[index] ~ "'", 2);
                return cmd.parse(args[0..index] ~ args[index + 1..$], program);
            }
        }

        ParsedArgs parsedArgs = new ParsedArgs(this, program);
        size_t argIndex = 0;

        string[][const(Option)] parsedOptions = new string[][Option];
        string[] variadic = [];

        for (size_t i = 0; i < args.length; ++i) {
            string arg = args[i];
            if (!arg.empty() && arg.front() == '-') {
                if (program.versionOption() !is null && program.versionOption().matches(arg))
                    exit(program.printVersion());
                if (program.helpOption() !is null && program.helpOption().matches(arg))
                    exit(printHelp());

                const(Flag) flag = findFlag(arg);
                if (flag !is null) {
                    parsedArgs.setFlag(flag);
                    continue;
                }

                const auto equalsIndex = arg.indexOf('=');
                const string optName = equalsIndex >= 0 ? arg[0..equalsIndex] : arg;
                const(Option) option = findOption(optName);
                if (option !is null) {
                    string value;
                    if (equalsIndex >= 0)
                        value =arg[equalsIndex + 1..$];
                    else if (i + 1 < args.length)
                        value = args[++i];
                    else
                        error("missing value for option '" ~ optName ~ "'", 2);

                    if (option in parsedOptions)
                        parsedOptions[option] ~= value;
                    else
                        parsedOptions[option] = [value];
                    continue;
                }
                else program.error("unknown option '" ~ optName ~ "'", 2);
            }

            if (argIndex + 1 > arguments.length) {
                if (!variadic.empty()) {
                    variadic ~= arg;
                    continue;
                }
                error("unexpected argument '" ~ arg ~ "'", 2);
            }

            const(Argument) argument = arguments[argIndex++];
            if (argument.variadic)
                variadic ~= arg;
            else
                parsedArgs.setArgument(argument, arg);
        }

        if (!variadic.empty())
            parsedArgs.setArgumentList(variadic);

        foreach (opt, value; parsedOptions) {
            parsedArgs.setOption(opt, value);
        }

        foreach (opt; options) {
            if (parsedArgs.hasOption(opt)) continue;
            if (opt.required)
                error("missing required option '" ~ opt.formattedName() ~ "'", 2);
            if (opt.defaultValue !is null)
                parsedArgs.setOption(opt, [opt.defaultValue]);
        }

        foreach (arg; arguments) {
            if (arg.variadic) {
                if (parsedArgs.variadic !is null && !parsedArgs.variadic.empty())
                    continue;
                if (arg.required)
                    error("missing required argument '" ~ arg.name ~ "'", 2);
                if (arg.defaultValue !is null)
                    parsedArgs.setArgumentList([arg.defaultValue]);
            }
            else {
                if (parsedArgs.hasArgument(arg)) continue;
                if (arg.required)
                    error("missing required argument '" ~ arg.name ~ "'", 2);
                if (arg.defaultValue !is null)
                    parsedArgs.setArgument(arg, arg.defaultValue);
            }
        }

        return parsedArgs;
    }

    public int run(const(string[]) args, const(Program) program) const {
        auto parsed = parse(args, program);
        return parsed.command.actionDg(parsed);
    }
}
