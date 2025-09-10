module cmd.command;

import core.stdc.stdlib;
import std.algorithm;
import std.array;
import std.stdio;
import std.string;
import std.range : repeat;

import cmd.argument;
import cmd.flag;
import cmd.option;
import cmd.parsed_args;
import cmd.program;

/** Represents a command-line command. */
public class Command {
    private const string _name;
    private string _description;
    package Flag[] flags;
    package Option[] options;
    package Argument[] arguments;
    package Command[] subcommands;
    public Command[] chain = null;
    private int delegate(ParsedArgs) _action;

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
        assert(name.length > 0, "Command name must be non-empty");
        this._name = name;
        this._action = (args) => args.command.printHelp();
    }

    /** Gets the name of the command. */
    public string name() const nothrow @safe {
        return this._name;
    }

    /** Sets the description of the command */
    public Command description(string description) nothrow @safe {
        this._description = description;
        return this;
    }

    /** Gets the description of the command */
    public string description() const nothrow @safe {
        return this._description;
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
        this._action = action;
        return this;
    }

    /**
     * Gets the usage string for this command.
     *
     * Throws:
     *   AssertionError if command chain is null or empty, or if first command is not a Program.
     */
    public string usage() const {
        assert(chain !is null, "Command chain is not initialised");
        assert(!chain.empty(), "Command chain is empty. The command should have at least itself in its chain.");
        Program program = cast(Program) chain[0];
        assert(program !is null, "First command in chain must be Program");

        Appender!string sb;
        sb.put(program.name());
        if (program.versionOption() || program.helpOption())
            sb.put(chain.length > 1 ? " [global options]" : " [options]");
        if (chain.length > 1)
            sb.put(" " ~ chain[1..$].map!(c => c.name()).array.join(" "));
        if (!subcommands.empty())
            sb.put(" <command> ...");
        else {
            if (!options.empty() || !flags.empty())
                sb.put(" " ~ (options.any!(o => o.required) ? "<options>" : "[options]"));
            foreach (arg; arguments)
                sb.put(" " ~ arg.formattedName());
        }
        return sb.data;
    }

    /** Prinths help for the command. */
    public int printHelp() const {
        writeln("\x1b[1mUsage:\x1b[0m");
        writeln("  " ~ usage());

        if (description() !is null) {
            writeln();
            writeln("\x1b[1mDescription:\x1b[0m");
            writeln("  " ~ description());
        }

        size_t longest = 0;
        foreach (cmd; subcommands)
            longest = max(longest, cmd.name().length);

        foreach (arg; arguments)
            longest = max(longest, arg.name.length);

        auto allOpts = cast(Flag[]) (flags ~ cast(Flag[]) options);
        foreach (opt; allOpts)
                longest = max(longest, opt.paddedName().length);

        if (subcommands !is null) {
            writeln();
            writeln("\x1b[1mCommands:\x1b[0m");

            foreach (cmd; (cast(Command[]) subcommands).dup.sort!((a, b) {
                return a.name() < b.name();
            }))
                writeln("  " ~ cmd.name() ~ ' '.repeat(longest - cmd.name().length + 2).array ~ "\x1b[2m"
                        ~ cmd.description() ~ "\x1b[0m");
        }

        if (arguments !is null) {
            writeln();
            writeln("\x1b[1mArguments:\x1b[0m");

            foreach (arg; arguments)
                writeln("  " ~ arg.name ~ ' '.repeat(longest - arg.name.length + 2).array ~ "\x1b[2m"
                        ~ arg.description ~ "\x1b[0m");
        }

        if (!flags.empty() || !options.empty()) {
            writeln();
            writeln("\x1b[1mOptions:\x1b[0m");

            foreach (opt; allOpts.sort!((a, b) {
                auto nameA = a.longName !is null ? a.longName : a.shortName;
                auto nameB = b.longName !is null ? b.longName : b.shortName;
                return nameA < nameB;
            }))
                writeln("  " ~ opt.paddedName() ~ ' '.repeat(longest - opt.paddedName().length + 2).array ~ "\x1b[2m"
                        ~ opt.description ~ "\x1b[0m");
        }

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
            auto index = args.countUntil!(a => a.front() != '-');
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
            if (arg.front() == '-') {
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

    package int run(const(string[]) args, const(Program) program) const {
        return _action(parse(args, program));
    }
}
