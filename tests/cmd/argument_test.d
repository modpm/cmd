module cmd.argument_test;

import core.exception : AssertError;
import std.exception : assertThrown;

import cmd.ansi;
import cmd.argument;

unittest {
    assertThrown!AssertError(new Argument("", true, false, "d"));
    assertThrown!AssertError(new Argument("input", true, false, "d", "x"));
    assertThrown!AssertError(new Argument("input", true, true, "d", "x"));
}

unittest {
    auto argument = Argument.fromString("<input>", "Input file");
    assert(argument.name == "input");
    assert(argument.required);
    assert(!argument.variadic);
    assert(argument.description == "Input file");
    assert(argument.defaultValue is null);
}

unittest {
    auto argument = Argument.fromString("[output]", "Output file");
    assert(argument.name == "output");
    assert(!argument.required);
    assert(!argument.variadic);
}

unittest {
    auto required = Argument.fromString("<files...>", "d");
    assert(required.name == "files");
    assert(required.required);
    assert(required.variadic);

    auto optional = Argument.fromString("[files...]", "d");
    assert(optional.name == "files");
    assert(!optional.required);
    assert(optional.variadic);
}

unittest {
    auto argument = Argument.fromString("[output]", "d", "out.txt");
    assert(argument.defaultValue == "out.txt");

    auto variadic = Argument.fromString("[files...]", "d", "a.txt");
    assert(variadic.defaultValue == "a.txt");
}

unittest {
    assert(Argument.fromString("< name >", "d").name == "name");
    assert(Argument.fromString("<files ...>", "d").name == "files");
    assert(Argument.fromString("<files ...>", "d").variadic);
    assert(Argument.fromString("[ name ]", "d").name == "name");
}

unittest {
    assertThrown!AssertError(Argument.fromString("", "d"));
    assertThrown!AssertError(Argument.fromString("input", "d"));
    assertThrown!AssertError(Argument.fromString("<input", "d"));
    assertThrown!AssertError(Argument.fromString("input>", "d"));
    assertThrown!AssertError(Argument.fromString("<input]", "d"));
    assertThrown!AssertError(Argument.fromString("[input>", "d"));
    assertThrown!AssertError(Argument.fromString("<>", "d"));
    assertThrown!AssertError(Argument.fromString("[]", "d"));
    assertThrown!AssertError(Argument.fromString("<...>", "d"));
    assertThrown!AssertError(Argument.fromString("<input>", "d", "x"));
    assertThrown!AssertError(Argument.fromString("<files...>", "d", "x"));
}

unittest {
    assert(Argument.fromString("<input>", "d").formattedName() == "<input>");
    assert(Argument.fromString("[output]", "d").formattedName() == "[output]");
    assert(Argument.fromString("<files...>", "d").formattedName() == "<files...>");
    assert(Argument.fromString("[files...]", "d").formattedName() == "[files...]");
    assert(Argument.fromString("<input>", "d").formattedName(false) == "<input>");
}

unittest {
    auto required = Argument.fromString("<input>", "d").formattedName(true);
    assert(required.stripAnsi() == "<input>");

    auto optional = Argument.fromString("[output]", "d").formattedName(true);
    assert(optional.stripAnsi() == "[output]");

    auto variadic = Argument.fromString("<files...>", "d").formattedName(true);
    assert(variadic.stripAnsi() == "<files...>");

    auto optionalVariadic = Argument.fromString("[files...]", "d").formattedName(true);
    assert(optionalVariadic.stripAnsi() == "[files...]");
}
