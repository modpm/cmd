module cmd.ansi;

import std.process : environment;
import std.range : empty;
import std.regex;

/** Removes ANSI escape sequences from a string, leaving only the text that would be displayed. */
public string stripAnsi(string input) @safe {
    return input.replaceAll(
        regex("\\x1B\\[[0-9;:?]*[A-Za-z]|\\x1B\\]8;;.*?\\x07(.*?)\\x1B\\]8;;\\x07|\\x1BO.|\\x1B.", "gs"),
        "$1"
    );
}

/** Applies foreground (text) SGR bold (increased intensity). */
public string bold(string text) nothrow @safe {
    return "\x1B[1m" ~ text ~ "\x1B[0m";
}

/** Applies foreground (text) SGR dim (faint, decreased intensity). */
public string dim(string text) nothrow @safe {
    return "\x1B[2m" ~ text ~ "\x1B[0m";
}

/** Applies foreground (text) SGR bright black. Applies dim instead if the `NO_COLOR` environment variable is set to a non-empty value. */
public string brightBlack(string text) nothrow @safe {
    try {
        if (!environment.get("NO_COLOR", "").empty())
            return dim(text);
    } catch (Exception) {
    }
    return "\x1B[90m" ~ text ~ "\x1B[0m";
}

/** Formats text as OSC 8 hyperlink. */
public string link(string text, string url) nothrow @safe {
    return "\x1B]8;;" ~ url ~ "\x07" ~ text ~ "\x1B]8;;\x07";
}
