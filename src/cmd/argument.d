module cmd.argument;

import std.string;

import cmd.ansi;
import cmd.value_type;

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

    /** Type of the argument value. */
    public const ValueType valueType;

    /**
     * Constructs an argument.
     *
     * Params:
     *   name = Name of the argument, must be non-empty.
     *   required = Whether the argument is required.
     *   variadic = Whether the argument accepts multiple values.
     *   description = Description of the argument.
     *   defaultValue = Default value, or `null`.
     *   valueType = Type of the argument value.
     *
     * Throws:
     *   AssertError if name is empty, if argument is required and default value is not `null`, or if the default
     *   value is not valid for the value type.
     */
    public this(string name, bool required, bool variadic, string description, string defaultValue = null,
        ValueType valueType = ValueType.init) @safe {
        assert(!name.empty(), "Argument name must be non-empty");
        if (required)
            assert(defaultValue is null, "Required argument cannot have a default value");
        assert(defaultValue is null || valueType.accepts(defaultValue), "Default value does not match the value type");
        this.name = name;
        this.required = required;
        this.variadic = variadic;
        this.description = description;
        this.defaultValue = defaultValue;
        this.valueType = valueType;
    }

    /**
     * Creates an argument from a formatted string.
     *
     * Format must be enclosed in `<>` (required) or `[]` (optional). Name may be followed by `:` and a value type, e.g.,
     * "<count:int>" or "<format:json|yaml>", and may end with `...` to indicate variadic argument, e.g.,
     * "<files:file...>".
     *
     * Params:
     *   format = Formatted string.
     *   description = Description of the argument.
     *   defaultValue = Default value, or `null`.
     *
     * Throws:
     *   AssertError if format is not enclosed in `<>` or `[]`, or if the value type is unknown.
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
        const spec = isVariadic ? namePart[0..$ - 3].strip() : namePart;
        const separator = spec.indexOf(':');

        return new Argument(
            separator < 0 ? spec : spec[0..separator].strip(),
            isRequired,
            isVariadic,
            description,
            defaultValue,
            separator < 0 ? ValueType.init : ValueType.fromString(spec[separator + 1..$].strip())
        );
    }

    /**
     * Returns formatted name, e.g., "<file>" or "[files...]".
     *
     * Params:
     *   colors = Whether to use colors.
     */
    public string formattedName(bool colors = false) const nothrow @safe {
        const auto namePart = valueType.label(name, colors) ~ (variadic ? (colors ? "...".dim() : "...") : "");
        if (colors)
            return required
                ? "<".brightBlack() ~ namePart ~ ">".brightBlack()
                : "[".brightBlack() ~ namePart ~ "]".brightBlack();
        return required ? "<" ~ namePart ~ ">" : "[" ~ namePart ~ "]";
    }
}
