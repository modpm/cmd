module cmd.argument_test;

import core.exception : AssertError;
import std.exception : assertNotThrown, assertThrown;

import cmd.ansi;
import cmd.argument;
import cmd.value_type;

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

unittest {
    auto integer = ValueType.fromString("int");
    auto choice = ValueType.fromString("json|yaml");
    assertThrown!AssertError(new Argument("count", false, false, "d", "abc", integer));
    assertThrown!AssertError(new Argument("count", false, false, "d", "01", integer));
    assertThrown!AssertError(new Argument("format", false, false, "d", "xml", choice));
    assertNotThrown!AssertError(new Argument("count", false, false, "d", "5", integer));
    assertNotThrown!AssertError(new Argument("format", false, true, "d", "yaml", choice));
}

unittest {
    assert(Argument.fromString("<name>", "d").valueType.kind == ValueType.Kind.text);
    assert(Argument.fromString("<name:string>", "d").valueType.kind == ValueType.Kind.text);
    assert(Argument.fromString("<path:file>", "d").valueType.kind == ValueType.Kind.file);
    assert(Argument.fromString("<root:dir>", "d").valueType.kind == ValueType.Kind.dir);
}

unittest {
    auto argument = Argument.fromString("<count:int>", "Count");
    assert(argument.name == "count");
    assert(argument.required);
    assert(!argument.variadic);
    assert(argument.valueType.kind == ValueType.Kind.integer);
}

unittest {
    auto argument = Argument.fromString("[ids:int...]", "Ids");
    assert(argument.name == "ids");
    assert(!argument.required);
    assert(argument.variadic);
    assert(argument.valueType.kind == ValueType.Kind.integer);

    auto files = Argument.fromString("<files:file...>", "Files");
    assert(files.name == "files");
    assert(files.variadic);
    assert(files.valueType.kind == ValueType.Kind.file);
}

unittest {
    auto argument = Argument.fromString("<format:json|yaml>", "Format");
    assert(argument.name == "format");
    assert(argument.valueType.kind == ValueType.Kind.choice);
    assert(argument.valueType.choices == ["json", "yaml"]);
}

unittest {
    auto spaced = Argument.fromString("< count : int >", "d");
    assert(spaced.name == "count");
    assert(spaced.valueType.kind == ValueType.Kind.integer);

    auto variadic = Argument.fromString("<ids:int ...>", "d");
    assert(variadic.name == "ids");
    assert(variadic.variadic);
    assert(variadic.valueType.kind == ValueType.Kind.integer);
}

unittest {
    assertThrown!AssertError(Argument.fromString("<x:float>", "d"));
    assertThrown!AssertError(Argument.fromString("<:int>", "d"));
    assertThrown!AssertError(Argument.fromString("[x:int]", "d", "a"));
    assertThrown!AssertError(Argument.fromString("[x:json|yaml]", "d", "xml"));
    assertNotThrown!AssertError(Argument.fromString("[x:int]", "d", "5"));
}

unittest {
    assert(Argument.fromString("<count:int>", "d").formattedName() == "<count>");
    assert(Argument.fromString("[path:file]", "d").formattedName() == "[path]");
    assert(Argument.fromString("[ids:int...]", "d").formattedName() == "[ids...]");
    assert(Argument.fromString("<format:json|yaml>", "d").formattedName() == "<json|yaml>");
    assert(Argument.fromString("<format:json|yaml...>", "d").formattedName() == "<json|yaml...>");
}

unittest {
    assert(Argument.fromString("<count:int>", "d").formattedName(true).stripAnsi() == "<count>");
    assert(Argument.fromString("[ids:int...]", "d").formattedName(true).stripAnsi() == "[ids...]");
    assert(Argument.fromString("<format:json|yaml>", "d").formattedName(true).stripAnsi() == "<json|yaml>");
}
