module cmd.option;

import std.string;

import cmd.ansi;
import cmd.flag;

/** Represents a command-line option with a parameter. */
public final class Option : Flag {
    /** Name of the parameter. */
    public const string paramName;

    /** Whether the option is required. */
    public const bool required;

    /** Default value of the parameter, or `null`. */
    public const string defaultValue;

    /**
     * Constructs an option.
     *
     * Params:
     *   shortName = Single-character short name, or `null`.
     *   longName = Long name, or `null`.
     *   paramName = Name of the parameter.
     *   description = Description of the option.
     *   required = Whether the option is required.
     *   defaultValue = Default value of the parameter, or `null`.
     *
     * Throws:
     *   AssertionError if option is required and default value is not `null`.
     */
    public this(string shortName, string longName, string paramName, string description, bool required,
        string defaultValue = null) @safe {
        super(shortName, longName, description);
        this.paramName = paramName;
        this.required = required;
        this.defaultValue = defaultValue;

        if (required)
            assert(defaultValue is null, "Required option cannot have a default value");
    }

    /**
     * Creates an option from a formatted string.
     *
     * Format may include short name `-x` and/or long name `--name`, followed by parameter in `<>` (required) or `[]`
     * (optional). Example: "-o, --output <file>".
     *
     * Params:
     *   format = Formatted string.
     *   description = Description of the option.
     *   defaultValue = Default value of the parameter, or `null`.
     *
     * Throws:
     *   AssertionError if format does not contain 2 or 3 parts, or if parameter part is not enclosed in `<>` or `[]`.
     */
    public static Option fromString(string format, string description, string defaultValue = null) @safe {
        auto parts = format.strip().split(" ");
        assert(parts.length == 2 || parts.length == 3, "Expected 2 or 3 parts in option format");

        string shortOpt = null;
        string longOpt = null;
        string paramPart = parts[$ - 1];

        assert(
            (paramPart.startsWith("<") && paramPart.endsWith(">"))
            || (paramPart.startsWith("[") && paramPart.endsWith("]")),
            "Parameter part must be enclosed in <> or []"
        );

        foreach (part; parts[0..$ - 1]) {
            part = part.strip();
            if (part.startsWith("--"))
                longOpt = part[2..$];
            else if (part.startsWith("-"))
                shortOpt = part[1..2];
        }

        return new Option(
            shortOpt, longOpt, paramPart[1..$ - 1].strip(), description, paramPart.startsWith("<"), defaultValue
        );
    }

    /**
     * Returns formatted name with parameter placeholder, e.g., `-f, --foo <val>`.
     *
     * Params:
     *   colors = Whether to use colors.
     *   padded = Whether to add spaces at the start if there is no short option.
     */
    public string formattedName(bool colors, bool padded = false) const nothrow @safe {
        return super.formattedName(padded) ~ " " ~
            (colors
                ? required
                    ? "<".brightBlack() ~ paramName.dim() ~ ">".brightBlack()
                    : "[".brightBlack() ~ paramName.dim() ~ "]".brightBlack()
                : required
                    ? "<" ~ paramName ~ ">"
                    : "[" ~ paramName ~ "]"
            );
    }

    /**
     * Returns formatted name with parameter placeholder, e.g., `-f, --foo <val>`.
     *
     * Params:
     *   padded = Whether to add spaces at the start if there is no short option.
     */
    public override string formattedName(bool padded = false) const nothrow @safe {
        return formattedName(colors: false, padded: padded);
    }

    public override hash_t toHash() const nothrow @safe {
        return formattedName().hashOf();
    }

    public override bool opEquals(Object o) const nothrow {
        if (auto other = cast(Option) o)
            return this.formattedName() == other.formattedName();
        return false;
    }
}
