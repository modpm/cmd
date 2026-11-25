module cmd.value_type;

import std.algorithm;
import std.array;
import std.ascii : isDigit;
import std.string;

import cmd.ansi;

/** Type of the value accepted by an option or an argument. */
public struct ValueType {
    /** Kind of the value. */
    public enum Kind {
        /** Any string. */
        text,

        /** Path to a file. */
        file,

        /** Path to a directory. */
        dir,

        /** Well-formed integer of any size. */
        integer,

        /** One of a fixed set of strings. */
        choice
    }

    /** Kind of the value. */
    public Kind kind = Kind.text;

    /** Allowed values if the kind is `choice`, otherwise empty. */
    public string[] choices;

    /**
     * Creates a value type from its name.
     *
     * The name is one of `string`, `file`, `dir`, `int`, or choices separated by `|`, e.g., `json|yaml`.
     *
     * Params:
     *   name = Name of the type.
     *
     * Throws:
     *   AssertError if the name is not a known type and not a list of at least two non-empty choices.
     */
    public static ValueType fromString(string name) @safe {
        switch (name) {
            case "string": return ValueType(Kind.text);
            case "file": return ValueType(Kind.file);
            case "dir": return ValueType(Kind.dir);
            case "int": return ValueType(Kind.integer);
            default: break;
        }

        auto choices = name.split("|");
        assert(choices.length > 1 && choices.all!(c => !c.empty()), "Unknown value type '" ~ name ~ "'");
        return ValueType(Kind.choice, choices);
    }

    /**
     * Checks whether the value is valid for this type.
     *
     * An integer is `0`, or an optional `-` followed by digits that do not start with `0`.
     *
     * Params:
     *   value = Value to check.
     */
    public bool accepts(string value) const @safe {
        final switch (kind) {
            case Kind.text:
            case Kind.file:
            case Kind.dir:
                return true;
            case Kind.integer:
                if (value == "0")
                    return true;
                const digits = value.startsWith('-') ? value[1..$] : value;
                return !digits.empty() && digits[0] != '0' && digits.all!(isDigit);
            case Kind.choice:
                return choices.canFind(value);
        }
    }

    /** Returns a description of the accepted values, e.g., `an integer` or `one of: json, yaml`. */
    public string expected() const @safe {
        if (kind == Kind.integer)
            return "an integer";
        return "one of: " ~ choices.join(", ");
    }

    /**
     * Returns the choices joined by `|` for a `choice` type, otherwise the given name.
     *
     * Params:
     *   name = Name to return if this is not a `choice` type.
     *   colors = Whether to dim the text and colour the `|` separators like other syntax symbols.
     */
    public string label(string name, bool colors = false) const nothrow @safe {
        if (kind != Kind.choice)
            return colors ? name.dim() : name;
        return colors ? choices.map!(c => c.dim()).join("|".brightBlack()) : choices.join("|");
    }
}
