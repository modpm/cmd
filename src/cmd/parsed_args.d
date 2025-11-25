module cmd.parsed_args;

import std.array;

import cmd.argument;
import cmd.command;
import cmd.flag;
import cmd.option;
import cmd.program;

/** Represents parsed command-line arguments for a command. */
public final class ParsedArgs {
    /** Command associated with the parsed arguments. */
    public const(Command) command;

    /** Program associated with the parsed arguments. */
    public const(Program) program;

    private uint[string] flags;
    private string[][string] options;
    private string[string] arguments;
    package string[] variadic;

    package this(const(Command) command, const(Program) program) nothrow @safe {
        this.command = command;
        this.program = program;
    }

    /** Checks whether the given flag name is present. */
    public bool hasFlag(string name) const nothrow @safe {
        foreach (prefix; ["", "-", "--"])
            if (auto p = prefix ~ name in flags)
                return *p > 0;
        return false;
    }

    /** Checks whether the given flag is present. */
    public bool hasFlag(Flag flag) const nothrow @safe {
        if (flag.longName !is null)
            return this.hasFlag("--" ~ flag.longName);
        return this.hasFlag("-" ~ flag.shortName);
    }
    
    /** Returns the number of times the flag with the given name was passed. */
    public uint flag(string name) const nothrow @safe {
        foreach (prefix; ["", "-", "--"]) {
            if (auto p = prefix ~ name in flags)
                return *p;
        }
        return 0;
    }
    
    /** Returns the number of times the given flag was passed. */
    public uint flag(const(Flag) flag) const nothrow @safe {
        if (flag.longName !is null)
            return this.flag("--" ~ flag.longName);
        return this.flag("-" ~ flag.shortName);
    }

    /** Checks whether an option with the given name is present. */
    public bool hasOption(string name) const nothrow @safe {
        return name in options || "-" ~ name in options || "--" ~ name in options;
    }

    /** Checks whether the given option is present. */
    public bool hasOption(const(Option) option) const nothrow @safe {
        if (option.longName !is null)
            return this.hasOption("--" ~ option.longName);
        return this.hasOption("-" ~ option.shortName);
    }

    /** Gets the first value for the option with the given name. */
    public string option(string name) const @safe {
        foreach (prefix; ["", "-", "--"])
            if (auto p = prefix ~ name in options)
                return (*p).front();
        throw new Exception("Option '" ~ name ~ "' not found");
    }

    /** Gets all values for the option with the given name. */
    public const(string[]) optionList(string name) const @safe {
        foreach (prefix; ["", "-", "--"])
            if (auto p = prefix ~ name in options)
                return *p;
        throw new Exception("Option '" ~ name ~ "' not found");
    }

    /** Gets all values for the given option. */
    public const(string[]) optionList(Option option) const @safe {
        if (option.shortName !is null)
            return this.optionList("-" ~ option.shortName);
        return this.optionList("--" ~ option.longName);
    }

    /** Checks whether an argument with the given name is present. */
    public bool hasArgument(string name) const nothrow @safe {
        if (name in arguments)
            return true;

        if (variadic is null || variadic.empty())
            return false;

        foreach (arg; command.arguments)
            if (arg.name == name && arg.variadic)
                return true;

        return false;
    }

    /** Checks whether the given argument is present. */
    public bool hasArgument(const(Argument) argument) const nothrow @safe {
        return hasArgument(argument.name);
    }

    /** Gets the first value for the argument with the given name. */
    public string argument(string name) const @safe {
        return argumentList(name).front();
    }

    /** Gets all values for the argument with the given name. */
    public const(string[]) argumentList(string name) const @safe {
        if (auto p = name in arguments)
            return [*p];

        if (variadic !is null && !variadic.empty())
            foreach (arg; command.arguments)
                if (arg.name == name && arg.variadic)
                    return variadic;

        throw new Exception("Argument '" ~ name ~ "' not found");
    }

    package void setOption(const(Option) option, string[] values) @safe {
        assert(!hasOption(option), "Option '" ~ option.formattedName() ~ "' already present");
        if (option.longName !is null)
            options["--" ~ option.longName] = values;
        if (option.shortName !is null)
            options["-" ~ option.shortName] = values;
    }

    package void setFlag(const(Flag) flag, uint count) nothrow @safe {
        if (flag.longName !is null)
            flags["--" ~ flag.longName] = count;
        if (flag.shortName !is null)
            flags["-" ~ flag.shortName] = count;
    }

    package void setArgument(const(Argument) argument, string value) @safe {
        assert(!hasArgument(argument), "Argument '" ~ argument.name ~ "' already present");
        arguments[argument.name] = value;
    }

    package void setArgumentList(string[] values) @safe {
        assert(variadic is null || variadic.empty(), "Argument list already set");
        variadic = values;
    }
}
