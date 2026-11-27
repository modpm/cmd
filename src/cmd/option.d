module cmd.option;

import std.string;

import cmd.ansi;
import cmd.flag;
import cmd.value_type;

/** Represents a command-line option with a parameter. */
public final class Option : Flag {
    /** Name of the parameter. */
    public const string paramName;

    /** Type of the parameter value. */
    public const ValueType valueType;

    /** Whether the option is required. */
    public const bool required;

    /** Default value of the parameter, or `null`. */
    public const string defaultValue;

    private string environmentVariableName;

    private string[] delegate(string) completerDg;

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
     *   valueType = Type of the parameter value.
     *
     * Throws:
     *   AssertError if option is required and default value is not `null`, or if the default value is not valid
     *   for the value type.
     */
    public this(string shortName, string longName, string paramName, string description, bool required,
        string defaultValue = null, ValueType valueType = ValueType.init) @safe {
        if (required)
            assert(defaultValue is null, "Required option cannot have a default value");
        assert(defaultValue is null || valueType.accepts(defaultValue), "Default value does not match the value type");

        super(shortName, longName, description);
        this.paramName = paramName;
        this.required = required;
        this.defaultValue = defaultValue;
        this.valueType = valueType;
    }

    /**
     * Creates an option from a formatted string.
     *
     * Format may include short name `-x` and/or long name `--name`, followed by parameter in `<>` (required) or `[]`
     * (optional). Example: "-o, --output <file>". The parameter name may be followed by `:` and a value type, e.g.,
     * "-p, --port <port:int>" or "--format <format:json|yaml>".
     *
     * Params:
     *   format = Formatted string.
     *   description = Description of the option.
     *   defaultValue = Default value of the parameter, or `null`.
     *
     * Throws:
     *   AssertError if format does not contain 2 or 3 parts, if parameter part is not enclosed in `<>` or `[]`, if
     *   the parameter name is empty, or if the value type is unknown.
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

        const param = paramPart[1..$ - 1].strip();
        const separator = param.indexOf(':');
        assert(separator != 0, "Parameter name must be non-empty");

        return new Option(
            shortOpt,
            longOpt,
            separator < 0 ? param : param[0..separator].strip(),
            description,
            paramPart.startsWith("<"),
            defaultValue,
            separator < 0 ? ValueType.init : ValueType.fromString(param[separator + 1..$].strip())
        );
    }

    /**
     * Sets the function that provides the suggestions for the parameter value in shell completion.
     *
     * Params:
     *   source = Function receiving the typed prefix of the value and returning the suggestions. The shell filters
     *            them by the prefix, so returning more than the matching ones is fine.
     */
    public Option completer(string[] delegate(string prefix) source) nothrow @safe {
        this.completerDg = source;
        return this;
    }

    /**
     * Sets the environment variable that provides the value if the option is not given. An empty variable counts as
     * not set.
     *
     * Params:
     *   name = Name of the environment variable.
     */
    public Option env(string name) nothrow @safe {
        this.environmentVariableName = name;
        return this;
    }

    package string environmentVariable() const nothrow @safe {
        return environmentVariableName;
    }

    package bool hasCompleter() const nothrow @safe {
        return completerDg !is null;
    }

    package string[] complete(string prefix) const {
        return completerDg(prefix);
    }

    /**
     * Returns formatted name with parameter placeholder, e.g., `-f, --foo <val>`.
     *
     * Params:
     *   colors = Whether to use colors.
     *   padded = Whether to add spaces at the start if there is no short option.
     */
    public string formattedName(bool colors, bool padded = false) const nothrow @safe {
        const label = valueType.label(paramName, colors);
        return super.formattedName(padded) ~ " " ~
            (colors
                ? required
                    ? "<".brightBlack() ~ label ~ ">".brightBlack()
                    : "[".brightBlack() ~ label ~ "]".brightBlack()
                : required
                    ? "<" ~ label ~ ">"
                    : "[" ~ label ~ "]"
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
