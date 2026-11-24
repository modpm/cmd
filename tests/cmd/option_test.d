module cmd.option_test;

import core.exception : AssertError;
import std.exception : assertNotThrown, assertThrown;

import cmd.ansi;
import cmd.flag;
import cmd.option;
import cmd.value_type;

unittest {
    assertThrown!AssertError(new Option("t", "target", "name", "d", true, "x"));
    assertThrown!AssertError(new Option(null, null, "name", "d", false));
    assertThrown!AssertError(new Option("ab", "target", "name", "d", false));
    assertThrown!AssertError(new Option("t", "", "name", "d", false));
}

unittest {
    auto option = Option.fromString("-o, --output <file>", "Output file");
    assert(option.shortName == "o");
    assert(option.longName == "output");
    assert(option.paramName == "file");
    assert(option.description == "Output file");
    assert(option.required);
    assert(option.defaultValue is null);
}

unittest {
    auto option = Option.fromString("-o, --output [file]", "Output file", "a.out");
    assert(option.shortName == "o");
    assert(option.longName == "output");
    assert(option.paramName == "file");
    assert(!option.required);
    assert(option.defaultValue == "a.out");
}

unittest {
    auto onlyLong = Option.fromString("--output <file>", "d");
    assert(onlyLong.shortName is null);
    assert(onlyLong.longName == "output");
    assert(onlyLong.paramName == "file");
    assert(onlyLong.required);

    auto onlyShort = Option.fromString("-o [file]", "d");
    assert(onlyShort.shortName == "o");
    assert(onlyShort.longName is null);
    assert(onlyShort.paramName == "file");
    assert(!onlyShort.required);
}

unittest {
    auto option = Option.fromString("  --output <file>  ", "d");
    assert(option.longName == "output");
    assert(option.paramName == "file");
}

unittest {
    assertThrown!AssertError(Option.fromString("--output", "d"));
    assertThrown!AssertError(Option.fromString("-o, --output <file> extra", "d"));
    assertThrown!AssertError(Option.fromString("--output file", "d"));
    assertThrown!AssertError(Option.fromString("--output <file", "d"));
    assertThrown!AssertError(Option.fromString("--output file>", "d"));
    assertThrown!AssertError(Option.fromString("--output <file]", "d"));
    assertThrown!AssertError(Option.fromString("--output [file>", "d"));
    assertThrown!AssertError(Option.fromString("--out <a b>", "d"));
    assertThrown!AssertError(Option.fromString("--output <file>", "d", "x"));
}

unittest {
    auto required = new Option("o", "output", "file", "d", true);
    assert(required.formattedName() == "-o, --output <file>");
    assert(required.formattedName(false, false) == "-o, --output <file>");
    assert(required.formattedName(false, true) == "-o, --output <file>");

    auto optional = new Option("o", "output", "file", "d", false);
    assert(optional.formattedName() == "-o, --output [file]");
    assert(optional.formattedName(false, false) == "-o, --output [file]");
}

unittest {
    auto required = new Option("o", "output", "file", "d", true);
    auto colored = required.formattedName(true, false);
    assert(colored.stripAnsi() == "-o, --output <file>");

    auto optional = new Option("o", "output", "file", "d", false);
    auto optionalColored = optional.formattedName(true, false);
    assert(optionalColored.stripAnsi() == "-o, --output [file]");
}

unittest {
    auto onlyLong = new Option(null, "output", "file", "d", true);
    assert(onlyLong.formattedName() == "--output <file>");
    assert(onlyLong.formattedName(false, false) == "--output <file>");
    assert(onlyLong.formattedName(false, true) == "    --output <file>");
    assert(onlyLong.formattedName(true, true).stripAnsi() == "    --output <file>");
    assert(onlyLong.formattedName(true, false).stripAnsi() == "--output <file>");

    auto onlyShort = new Option("o", null, "file", "d", true);
    assert(onlyShort.formattedName() == "-o <file>");
    assert(onlyShort.formattedName(false, true) == "-o <file>");
}

unittest {
    Flag flag = new Option("o", "output", "file", "d", true);
    assert(flag.formattedName() == "-o, --output <file>");
    assert(flag.formattedName(false) == "-o, --output <file>");

    Flag longOnly = new Option(null, "output", "file", "d", false);
    assert(longOnly.formattedName(true) == "    --output [file]");
}

unittest {
    auto option = new Option("o", "output", "file", "d", true);
    assert(option.matches("--output"));
    assert(option.matches("-o"));
    assert(option.matches("output"));
    assert(option.matches("o"));
    assert(!option.matches("--file"));
    assert(!option.matches("-x"));
}

unittest {
    auto a = new Option("o", "output", "file", "one", true);
    auto b = new Option("o", "output", "file", "two", true);
    auto c = new Option("o", "output", "file", "one", false);
    auto d = new Option("o", "output", "path", "one", true);
    auto e = new Option(null, "output", "file", "one", true);

    assert(a == a);
    assert(a == b);
    assert(a.toHash() == b.toHash());
    assert(a != c);
    assert(a != d);
    assert(a != e);
    assert(!a.opEquals(new Object()));
    assert(!a.opEquals(new Flag("o", "output", "one")));
}

unittest {
    auto a = new Option("o", "output", "file", "one", true);
    auto b = new Option("o", "output", "file", "two", false, null);
    auto c = new Option("o", "output", "file", "three", false, "x");
    auto d = new Option("p", "port", "number", "one", false);

    string[][Option] values;
    values[c] = ["x"];
    assert(b in values);
    assert(a !in values);
    assert(d !in values);
    values[b] = ["y"];
    assert(values.length == 1);
    assert(values[c] == ["y"]);
}

unittest {
    auto integer = ValueType.fromString("int");
    auto choice = ValueType.fromString("json|yaml");
    assertThrown!AssertError(new Option("p", "port", "n", "d", false, "abc", integer));
    assertThrown!AssertError(new Option("p", "port", "n", "d", false, "01", integer));
    assertThrown!AssertError(new Option("f", "format", "f", "d", false, "xml", choice));
    assertNotThrown!AssertError(new Option("p", "port", "n", "d", false, "80", integer));
    assertNotThrown!AssertError(new Option("f", "format", "f", "d", false, "json", choice));
    assertNotThrown!AssertError(new Option("c", "config", "p", "d", false, "any value", ValueType.fromString("file")));
}

unittest {
    assert(Option.fromString("--name <name>", "d").valueType.kind == ValueType.Kind.text);
    assert(Option.fromString("--name <name:string>", "d").valueType.kind == ValueType.Kind.text);
    assert(Option.fromString("--config [path:file]", "d").valueType.kind == ValueType.Kind.file);
    assert(Option.fromString("--root <path:dir>", "d").valueType.kind == ValueType.Kind.dir);
}

unittest {
    auto option = Option.fromString("-p, --port <number:int>", "Port");
    assert(option.shortName == "p");
    assert(option.longName == "port");
    assert(option.paramName == "number");
    assert(option.valueType.kind == ValueType.Kind.integer);
    assert(option.required);
}

unittest {
    auto option = Option.fromString("--format [format:json|yaml|toml]", "Format", "json");
    assert(option.paramName == "format");
    assert(option.valueType.kind == ValueType.Kind.choice);
    assert(option.valueType.choices == ["json", "yaml", "toml"]);
    assert(!option.required);
    assert(option.defaultValue == "json");
}

unittest {
    assertThrown!AssertError(Option.fromString("--port <n:float>", "d"));
    assertThrown!AssertError(Option.fromString("--port <n:json>", "d"));
    assertThrown!AssertError(Option.fromString("--port <:int>", "d"));
    assertThrown!AssertError(Option.fromString("--port [n:int]", "d", "x"));
    assertThrown!AssertError(Option.fromString("--format [f:json|yaml]", "d", "xml"));
    assertNotThrown!AssertError(Option.fromString("--port [n:int]", "d", "80"));
}

unittest {
    assert(Option.fromString("-p, --port <number:int>", "d").formattedName() == "-p, --port <number>");
    assert(Option.fromString("--config [path:file]", "d").formattedName() == "--config [path]");
    assert(Option.fromString("-f, --format [format:json|yaml]", "d").formattedName() == "-f, --format [json|yaml]");
    assert(Option.fromString("--format <format:json|yaml>", "d").formattedName(false, true)
        == "    --format <json|yaml>");
}

unittest {
    assert(Option.fromString("-p, --port <number:int>", "d").formattedName(true, false).stripAnsi()
        == "-p, --port <number>");
    assert(Option.fromString("-f, --format [format:json|yaml]", "d").formattedName(true, false).stripAnsi()
        == "-f, --format [json|yaml]");
}
