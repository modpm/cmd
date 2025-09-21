module cmd.flag;

import std.range;
import std.string;

/**
 * Represents a command-line flag.
 */
public class Flag {
    /** Single-character short name, or `null`. */
    public const string shortName;

    /** Long name, or `null`. */
    public const string longName;

    /** Description of the flag. */
    public const string description;

    /**
     * Placeholder for padding when there is no short option.
     *
     * 4 spaces as placeholder for: minus (`-`) + any letter (`a`) + comma (`,`) + space (` `)
     * Example: `-a, ` (4 characters)
     */
    public static const enum PADDING_MISSING_SHORT = "    ";

    /**
     * Constructs a flag.
     *
     * Params:
     *   shortName = Single-character short name, or `null`.
     *   longName = Long name, or `null`.
     *   description = Description of the flag.
     *
     * Throws:
     *   AssertionError if both names are `null`, `shortName` not single character, or `longName` empty.
     */
    public this(string shortName, string longName, string description) @safe {
        assert(shortName is null || shortName.length == 1, "Short name must be a single character");
        assert(longName is null || longName.length > 0, "Long name must be non-empty");
        assert(shortName !is null || longName !is null, "At least one of shortName or longName must be provided");

        this.shortName = shortName;
        this.longName = longName;
        this.description = description;
    }

    /**
     * Creates a flag from a formatted string.
     *
     * Format may include short name `-x` and/or long name `--name`, comma-separated.
     *
     * Params:
     *   format = Formatted string.
     *   description = Description of the flag.
     *
     * Throws:
     *   AssertionError if format does not contain 1 or 2 parts.
     */
    public static Flag fromString(string format, string description) @safe {
        auto parts = format.strip().split(",");
        assert(parts.length == 1 || parts.length == 2, "Expected 1 or 2 parts in flag format");

        string shortOpt = null;
        string longOpt = null;

        foreach (part; parts) {
            part = part.strip();
            if (part.startsWith("--"))
                longOpt = part[2..$];
            else if (part.startsWith("-"))
                shortOpt = part[1..2];
        }

        return new Flag(shortOpt, longOpt, description);
    }

    /** Returns formatted name, e.g., `-h, --help`. */
    public string formattedName() const nothrow @safe {
        return "" ~ (shortName !is null ? "-" ~ shortName : "")
            ~ (longName !is null ? (shortName !is null ? ", " : "") ~ "--" ~ longName : "");
    }

    /** Returns formatted name padded with spaces if there is no short option. */
    public string paddedName() const nothrow @safe {
        auto name = formattedName();
        return shortName is null
            ? PADDING_MISSING_SHORT ~ name
            : name;
    }

    /**
     * Checks whether the given query matches this flag.
     *
     * Params:
     *   query = String to check.
     */
    public bool matches(string query) const nothrow @safe {
        return
            (query.startsWith("--") && longName == query[2..$])
            || (query.startsWith("-") && shortName == query[1..2])
            || query == longName
            || query == shortName;
    }

    public override hash_t toHash() const nothrow @safe {
        return formattedName().hashOf();
    }

    public override bool opEquals(Object o) const nothrow {
        if (auto other = cast(Flag) o)
            return this.formattedName() == other.formattedName();
        return false;
    }
}
