module cmd.option_test;

import core.exception : AssertError;

import fluent.asserts;

import cmd.ansi;
import cmd.flag;
import cmd.option;
import cmd.value_type;

unittest {
    expect({ new Option("t", "target", "name", "d", true, "x"); }).to.throwException!AssertError;
    expect({ new Option(null, null, "name", "d", false); }).to.throwException!AssertError;
    expect({ new Option("ab", "target", "name", "d", false); }).to.throwException!AssertError;
    expect({ new Option("t", "", "name", "d", false); }).to.throwException!AssertError;
}

unittest {
    auto option = Option.fromString("-o, --output <file>", "Output file");
    expect(option.shortName).to.equal("o");
    expect(option.longName).to.equal("output");
    expect(option.paramName).to.equal("file");
    expect(option.description).to.equal("Output file");
    expect(option.required).to.equal(true);
    expect(option.defaultValue).to.beNull;
}

unittest {
    auto option = Option.fromString("-o, --output [file]", "Output file", "a.out");
    expect(option.shortName).to.equal("o");
    expect(option.longName).to.equal("output");
    expect(option.paramName).to.equal("file");
    expect(option.required).to.equal(false);
    expect(option.defaultValue).to.equal("a.out");
}

unittest {
    auto onlyLong = Option.fromString("--output <file>", "d");
    expect(onlyLong.shortName).to.beNull;
    expect(onlyLong.longName).to.equal("output");
    expect(onlyLong.paramName).to.equal("file");
    expect(onlyLong.required).to.equal(true);

    auto onlyShort = Option.fromString("-o [file]", "d");
    expect(onlyShort.shortName).to.equal("o");
    expect(onlyShort.longName).to.beNull;
    expect(onlyShort.paramName).to.equal("file");
    expect(onlyShort.required).to.equal(false);
}

unittest {
    auto option = Option.fromString("  --output <file>  ", "d");
    expect(option.longName).to.equal("output");
    expect(option.paramName).to.equal("file");
}

unittest {
    expect({ Option.fromString("--output", "d"); }).to.throwException!AssertError;
    expect({ Option.fromString("-o, --output <file> extra", "d"); }).to.throwException!AssertError;
    expect({ Option.fromString("--output file", "d"); }).to.throwException!AssertError;
    expect({ Option.fromString("--output <file", "d"); }).to.throwException!AssertError;
    expect({ Option.fromString("--output file>", "d"); }).to.throwException!AssertError;
    expect({ Option.fromString("--output <file]", "d"); }).to.throwException!AssertError;
    expect({ Option.fromString("--output [file>", "d"); }).to.throwException!AssertError;
    expect({ Option.fromString("--out <a b>", "d"); }).to.throwException!AssertError;
    expect({ Option.fromString("--output <file>", "d", "x"); }).to.throwException!AssertError;
}

unittest {
    auto required = new Option("o", "output", "file", "d", true);
    expect(required.formattedName()).to.equal("-o, --output <file>");
    expect(required.formattedName(false, false)).to.equal("-o, --output <file>");
    expect(required.formattedName(false, true)).to.equal("-o, --output <file>");

    auto optional = new Option("o", "output", "file", "d", false);
    expect(optional.formattedName()).to.equal("-o, --output [file]");
    expect(optional.formattedName(false, false)).to.equal("-o, --output [file]");
}

unittest {
    auto required = new Option("o", "output", "file", "d", true);
    auto colored = required.formattedName(true, false);
    expect(colored.stripAnsi()).to.equal("-o, --output <file>");

    auto optional = new Option("o", "output", "file", "d", false);
    auto optionalColored = optional.formattedName(true, false);
    expect(optionalColored.stripAnsi()).to.equal("-o, --output [file]");
}

unittest {
    auto onlyLong = new Option(null, "output", "file", "d", true);
    expect(onlyLong.formattedName()).to.equal("--output <file>");
    expect(onlyLong.formattedName(false, false)).to.equal("--output <file>");
    expect(onlyLong.formattedName(false, true)).to.equal("    --output <file>");
    expect(onlyLong.formattedName(true, true).stripAnsi()).to.equal("    --output <file>");
    expect(onlyLong.formattedName(true, false).stripAnsi()).to.equal("--output <file>");

    auto onlyShort = new Option("o", null, "file", "d", true);
    expect(onlyShort.formattedName()).to.equal("-o <file>");
    expect(onlyShort.formattedName(false, true)).to.equal("-o <file>");
}

unittest {
    Flag flag = new Option("o", "output", "file", "d", true);
    expect(flag.formattedName()).to.equal("-o, --output <file>");
    expect(flag.formattedName(false)).to.equal("-o, --output <file>");

    Flag longOnly = new Option(null, "output", "file", "d", false);
    expect(longOnly.formattedName(true)).to.equal("    --output [file]");
}

unittest {
    auto option = new Option("o", "output", "file", "d", true);
    expect(option.matches("--output")).to.equal(true);
    expect(option.matches("-o")).to.equal(true);
    expect(option.matches("output")).to.equal(true);
    expect(option.matches("o")).to.equal(true);
    expect(option.matches("--file")).to.equal(false);
    expect(option.matches("-x")).to.equal(false);
}

unittest {
    auto a = new Option("o", "output", "file", "one", true);
    auto b = new Option("o", "output", "file", "two", true);
    auto c = new Option("o", "output", "file", "one", false);
    auto d = new Option("o", "output", "path", "one", true);
    auto e = new Option(null, "output", "file", "one", true);

    expect(a).to.equal(a);
    expect(a).to.equal(b);
    expect(a.toHash()).to.equal(b.toHash());
    expect(a).to.not.equal(c);
    expect(a).to.not.equal(d);
    expect(a).to.not.equal(e);
    expect(a.opEquals(new Object())).to.equal(false);
    expect(a.opEquals(new Flag("o", "output", "one"))).to.equal(false);
}

unittest {
    auto a = new Option("o", "output", "file", "one", true);
    auto b = new Option("o", "output", "file", "two", false, null);
    auto c = new Option("o", "output", "file", "three", false, "x");
    auto d = new Option("p", "port", "number", "one", false);

    string[][Option] values;
    values[c] = ["x"];
    expect(b in values).to.not.beNull;
    expect(a in values).to.beNull;
    expect(d in values).to.beNull;
    values[b] = ["y"];
    expect(values.length).to.equal(1);
    expect(values[c]).to.equal(["y"]);
}

unittest {
    auto integer = ValueType.fromString("int");
    auto choice = ValueType.fromString("json|yaml");
    expect({ new Option("p", "port", "n", "d", false, "abc", integer); }).to.throwException!AssertError;
    expect({ new Option("p", "port", "n", "d", false, "01", integer); }).to.throwException!AssertError;
    expect({ new Option("f", "format", "f", "d", false, "xml", choice); }).to.throwException!AssertError;
    expect({ new Option("p", "port", "n", "d", false, "80", integer); }).to.not.throwException!AssertError;
    expect({ new Option("f", "format", "f", "d", false, "json", choice); }).to.not.throwException!AssertError;
    expect({ new Option("c", "config", "p", "d", false, "any value", ValueType.fromString("file")); })
        .to.not.throwException!AssertError;
}

unittest {
    expect(Option.fromString("--name <name>", "d").valueType.kind).to.equal(ValueType.Kind.text);
    expect(Option.fromString("--name <name:string>", "d").valueType.kind).to.equal(ValueType.Kind.text);
    expect(Option.fromString("--config [path:file]", "d").valueType.kind).to.equal(ValueType.Kind.file);
    expect(Option.fromString("--root <path:dir>", "d").valueType.kind).to.equal(ValueType.Kind.dir);
}

unittest {
    auto option = Option.fromString("-p, --port <number:int>", "Port");
    expect(option.shortName).to.equal("p");
    expect(option.longName).to.equal("port");
    expect(option.paramName).to.equal("number");
    expect(option.valueType.kind).to.equal(ValueType.Kind.integer);
    expect(option.required).to.equal(true);
}

unittest {
    auto option = Option.fromString("--format [format:json|yaml|toml]", "Format", "json");
    expect(option.paramName).to.equal("format");
    expect(option.valueType.kind).to.equal(ValueType.Kind.choice);
    expect(option.valueType.choices).to.equal(["json", "yaml", "toml"]);
    expect(option.required).to.equal(false);
    expect(option.defaultValue).to.equal("json");
}

unittest {
    expect({ Option.fromString("--port <n:float>", "d"); }).to.throwException!AssertError;
    expect({ Option.fromString("--port <n:json>", "d"); }).to.throwException!AssertError;
    expect({ Option.fromString("--port <:int>", "d"); }).to.throwException!AssertError;
    expect({ Option.fromString("--port [n:int]", "d", "x"); }).to.throwException!AssertError;
    expect({ Option.fromString("--format [f:json|yaml]", "d", "xml"); }).to.throwException!AssertError;
    expect({ Option.fromString("--port [n:int]", "d", "80"); }).to.not.throwException!AssertError;
}

unittest {
    expect(Option.fromString("-p, --port <number:int>", "d").formattedName()).to.equal("-p, --port <number>");
    expect(Option.fromString("--config [path:file]", "d").formattedName()).to.equal("--config [path]");
    expect(Option.fromString("-f, --format [format:json|yaml]", "d").formattedName())
        .to.equal("-f, --format [json|yaml]");
    expect(Option.fromString("--format <format:json|yaml>", "d").formattedName(false, true))
        .to.equal("    --format <json|yaml>");
}

unittest {
    expect(Option.fromString("-p, --port <number:int>", "d").formattedName(true, false).stripAnsi())
        .to.equal("-p, --port <number>");
    expect(Option.fromString("-f, --format [format:json|yaml]", "d").formattedName(true, false).stripAnsi())
        .to.equal("-f, --format [json|yaml]");
}

unittest {
    auto option = Option.fromString("-f, --file <path>", "File");
    expect(option.hasCompleter()).to.equal(false);
    expect(option.completer((prefix) => ["a", "b"])).to.equal(option);
    expect(option.hasCompleter()).to.equal(true);
    expect(option.complete("")).to.equal(["a", "b"]);
}

unittest {
    auto option = Option.fromString("-k, --kind <kind:x|y>", "Kind").completer((prefix) => ["z"]);
    expect(option.valueType.accepts("x")).to.equal(true);
    expect(option.valueType.accepts("z")).to.equal(false);
    expect(option.complete("")).to.equal(["z"]);
}

unittest {
    auto option = Option.fromString("-f, --file <path>", "File").completer((prefix) => [prefix ~ "!"]);
    expect(option.complete("ab")).to.equal(["ab!"]);
    expect(option.complete("")).to.equal(["!"]);
}
