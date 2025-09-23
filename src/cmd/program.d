module cmd.program;

import core.stdc.stdlib;
import std.array;
import std.stdio;

import cmd.argument;
import cmd.command;
import cmd.flag;
import cmd.option;
import cmd.parsed_args;

/** Represents a command-line program. */
public class Program : Command {
    private string versionStr;
    private Flag versionOptionFlag;
    private Flag helpOptionFlag;

    /**
     * Constructs a new program with the given name.
     *
     * Params:
     *   name = Name of the program.
     *
     * Throws:
     *   AssertionError if the name is empty.
     */
    public this(string name) @safe {
        super(name);
        this.chain = [this];
    }

    /** Sets the version of the program. */
    public Program versionString(string ver) nothrow @safe {
        this.versionStr = ver;
        return this;
    }

    /** Gets the version of the program. */
    public string versionString() const nothrow @safe {
        return versionStr;
    }

    /** Sets the version flag for the program and enables getting the version with it. */
    public Program versionOption(Flag flag) @safe {
        assert(versionStr !is null, "Version is not set");
        versionOptionFlag = flag;
        flags ~= flag;
        return this;
    }

    /** Sets the version flag for the program from formatted string and enables getting the version with it. */
    public Program versionOption(string format, string description) @safe {
        return versionOption(Flag.fromString(format, description));
    }

    /** Gets the version flag for the program. */
    public const(Flag) versionOption() const nothrow @safe {
        return versionOptionFlag;
    }

    /** Prints the version and returns 0. */
    public const(int) printVersion() const {
        assert(versionStr !is null, "Version is not set");
        writeln(versionStr);
        return 0;
    }

    /** Sets the help flag for the program from formatted string and enables getting command help with it. */
    public Program helpOption(string format, string description) @safe {
        return helpOption(Flag.fromString(format, description));
    }


    /** Sets the help flag for the program and enables getting command help with it. */
    public Program helpOption(Flag flag) nothrow @safe {
        helpOptionFlag = flag;
        flags ~= flag;
        return this;
    }

    /** Gets the help flag for the program. */
    public const(Flag) helpOption() const nothrow @safe {
        return helpOptionFlag;
    }

    /** Sets the description of the command */
    public override Program description(string desc) nothrow @safe {
        super.description(desc);
        return this;
    }

    /**
     * Adds a subcommand.
     *
     * Throws:
     *   AssertionError if subcommand already has a chain, if this command has arguments, or if a subcommand with the
     *   same name already exists.
     */
    public override Program add(Command cmd) @safe {
        super.add(cmd);
        return this;
    }

    /**
     * Adds a subcommand.
     *
     * Throws:
     *   AssertionError if subcommand already has a chain, if this command has arguments, or if a subcommand with the
     *   same name already exists.
     */
    public override Program command(Command cmd) @safe {
        super.command(cmd);
        return this;
    }

    /**
     * Adds an option.
     *
     * Throws:
     *   AssertionError if an option with the same short or long name already exists.
     */
    public override Program add(Option option) @safe {
        super.add(option);
        return this;
    }

    /**
     * Adds a flag.
     *
     * Throws:
     *   AssertionError if a flag with the same short or long name already exists.
     */
    public override Program add(Flag flag) @safe {
        super.add(flag);
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
    public override Program option(string format, string description, string defaultValue = null) @safe {
        super.option(format, description, defaultValue);
        return this;
    }

    /**
     * Adds an argument.
     *
     * Throws:
     *   AssertionError if the command has subcommands or an argument with the same name already exists.
     */
    public override Program add(Argument arg) @safe {
        super.add(arg);
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
    public override Program argument(string format, string description, string defaultValue = null) @safe {
        super.argument(format, description, defaultValue);
        return this;
    }

    /**
     * Sets the action delegate to be executed for this command. The default action is to print help for the command.
     *
     * Params:
     *   action = Delegate to execute when command runs.
     */
    public override Program action(int delegate(ParsedArgs) dg) @safe {
        super.action(dg);
        return this;
    }

    /**
     * Gets the parsed arguments.
     */
    public ParsedArgs parse(string[] args) const {
        return super.parse(args[1..$], this);
    }

    /**
     * Runs the program with the given arguments.
     *
     * Params:
     *   args = Command-line arguments array.
     */
    public noreturn run(string[] args) const {
        exit(super.run(args[1..$], this));
    }
}
