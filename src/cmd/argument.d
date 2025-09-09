module cmd.argument;

import std.string;

/** Represents a command-line argument. */
public class Argument {
    /** Name of the argument. */
    public const string name;

    /** Description of the argument. */
    public const string description;

    /** Whether the argument is required. */
    public const bool required;

    /** Whether the argument accepts multiple values. */
    public const bool variadic;

    /** Default value of the argument, or `null`. */
    public const string defaultValue;

    /**
     * Constructs an argument.
     *
     * Params:
     *   name = Name of the argument, must be non-empty.
     *   required = Whether the argument is required.
     *   variadic = Whether the argument accepts multiple values.
     *   description = Description of the argument.
     *   defaultValue = Default value, or `null`.
     *
     * Throws:
     *   AssertionError if name is empty, or if argument is required and default value is not `null`.
     */
    public this(string name, bool required, bool variadic, string description, string defaultValue = null) @safe {
        assert(name.length > 0, "Argument name must be non-empty");
        if (required)
            assert(defaultValue is null, "Required argument cannot have a default value");
        this.name = name;
        this.required = required;
        this.variadic = variadic;
        this.description = description;
        this.defaultValue = defaultValue;
    }

    /**
     * Creates an argument from a formatted string.
     *
     * Format must be enclosed in `<>` (required) or `[]` (optional). Name may end with `...` to indicate variadic
     * argument.
     *
     * Params:
     *   format = Formatted string.
     *   description = Description of the argument.
     *   defaultValue = Default value, or `null`.
     *
     * Throws:
     *   AssertionError if format is not enclosed in `<>` or `[]`.
     */
    public static Argument fromString(string format, string description, string defaultValue = null) @safe {
        assert(
            (format.startsWith("<") && format.endsWith(">"))
            || (format.startsWith("[") && format.endsWith("]")),
            "Argument format must be enclosed in <> or []"
        );

        const isRequired = format.startsWith("<");
        const namePart = format[1..$ - 1].strip();
        const isVariadic = namePart.endsWith("...");

        return new Argument(
            isVariadic ? namePart[0..$ - 3].strip() : namePart,
            isRequired,
            isVariadic,
            description,
            defaultValue
        );
    }

    /** Returns formatted name, e.g., "<file>" or "[files...]". */
    public string formattedName() const nothrow @safe {
        const auto namePart = name ~ (variadic ? "..." : "");
        return required ? "<" ~ namePart ~ ">" : "[" ~ namePart ~ "]";
    }
}
