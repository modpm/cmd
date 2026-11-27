module cmd.argument_test;

import core.exception : AssertError;

import fluent.asserts;

import cmd.ansi;
import cmd.argument;
import cmd.value_type;

unittest {
    expect({ new Argument("", true, false, "d"); }).to.throwException!AssertError;
    expect({ new Argument("input", true, false, "d", "x"); }).to.throwException!AssertError;
    expect({ new Argument("input", true, true, "d", "x"); }).to.throwException!AssertError;
}

unittest {
    auto argument = Argument.fromString("<input>", "Input file");
    expect(argument.name).to.equal("input");
    expect(argument.required).to.equal(true);
    expect(argument.variadic).to.equal(false);
    expect(argument.description).to.equal("Input file");
    expect(argument.defaultValue).to.beNull;
}

unittest {
    auto argument = Argument.fromString("[output]", "Output file");
    expect(argument.name).to.equal("output");
    expect(argument.required).to.equal(false);
    expect(argument.variadic).to.equal(false);
}

unittest {
    auto required = Argument.fromString("<files...>", "d");
    expect(required.name).to.equal("files");
    expect(required.required).to.equal(true);
    expect(required.variadic).to.equal(true);

    auto optional = Argument.fromString("[files...]", "d");
    expect(optional.name).to.equal("files");
    expect(optional.required).to.equal(false);
    expect(optional.variadic).to.equal(true);
}

unittest {
    auto argument = Argument.fromString("[output]", "d", "out.txt");
    expect(argument.defaultValue).to.equal("out.txt");

    auto variadic = Argument.fromString("[files...]", "d", "a.txt");
    expect(variadic.defaultValue).to.equal("a.txt");
}

unittest {
    expect(Argument.fromString("< name >", "d").name).to.equal("name");
    expect(Argument.fromString("<files ...>", "d").name).to.equal("files");
    expect(Argument.fromString("<files ...>", "d").variadic).to.equal(true);
    expect(Argument.fromString("[ name ]", "d").name).to.equal("name");
}

unittest {
    expect({ Argument.fromString("", "d"); }).to.throwException!AssertError;
    expect({ Argument.fromString("input", "d"); }).to.throwException!AssertError;
    expect({ Argument.fromString("<input", "d"); }).to.throwException!AssertError;
    expect({ Argument.fromString("input>", "d"); }).to.throwException!AssertError;
    expect({ Argument.fromString("<input]", "d"); }).to.throwException!AssertError;
    expect({ Argument.fromString("[input>", "d"); }).to.throwException!AssertError;
    expect({ Argument.fromString("<>", "d"); }).to.throwException!AssertError;
    expect({ Argument.fromString("[]", "d"); }).to.throwException!AssertError;
    expect({ Argument.fromString("<...>", "d"); }).to.throwException!AssertError;
    expect({ Argument.fromString("<input>", "d", "x"); }).to.throwException!AssertError;
    expect({ Argument.fromString("<files...>", "d", "x"); }).to.throwException!AssertError;
}

unittest {
    expect(Argument.fromString("<input>", "d").formattedName()).to.equal("<input>");
    expect(Argument.fromString("[output]", "d").formattedName()).to.equal("[output]");
    expect(Argument.fromString("<files...>", "d").formattedName()).to.equal("<files...>");
    expect(Argument.fromString("[files...]", "d").formattedName()).to.equal("[files...]");
    expect(Argument.fromString("<input>", "d").formattedName(false)).to.equal("<input>");
}

unittest {
    auto required = Argument.fromString("<input>", "d").formattedName(true);
    expect(required.stripAnsi()).to.equal("<input>");

    auto optional = Argument.fromString("[output]", "d").formattedName(true);
    expect(optional.stripAnsi()).to.equal("[output]");

    auto variadic = Argument.fromString("<files...>", "d").formattedName(true);
    expect(variadic.stripAnsi()).to.equal("<files...>");

    auto optionalVariadic = Argument.fromString("[files...]", "d").formattedName(true);
    expect(optionalVariadic.stripAnsi()).to.equal("[files...]");
}

unittest {
    auto integer = ValueType.fromString("int");
    auto choice = ValueType.fromString("json|yaml");
    expect({ new Argument("count", false, false, "d", "abc", integer); }).to.throwException!AssertError;
    expect({ new Argument("count", false, false, "d", "01", integer); }).to.throwException!AssertError;
    expect({ new Argument("format", false, false, "d", "xml", choice); }).to.throwException!AssertError;
    expect({ new Argument("count", false, false, "d", "5", integer); }).to.not.throwException!AssertError;
    expect({ new Argument("format", false, true, "d", "yaml", choice); }).to.not.throwException!AssertError;
}

unittest {
    expect(Argument.fromString("<name>", "d").valueType.kind).to.equal(ValueType.Kind.text);
    expect(Argument.fromString("<name:string>", "d").valueType.kind).to.equal(ValueType.Kind.text);
    expect(Argument.fromString("<path:file>", "d").valueType.kind).to.equal(ValueType.Kind.file);
    expect(Argument.fromString("<root:dir>", "d").valueType.kind).to.equal(ValueType.Kind.dir);
}

unittest {
    auto argument = Argument.fromString("<count:int>", "Count");
    expect(argument.name).to.equal("count");
    expect(argument.required).to.equal(true);
    expect(argument.variadic).to.equal(false);
    expect(argument.valueType.kind).to.equal(ValueType.Kind.integer);
}

unittest {
    auto argument = Argument.fromString("[ids:int...]", "Ids");
    expect(argument.name).to.equal("ids");
    expect(argument.required).to.equal(false);
    expect(argument.variadic).to.equal(true);
    expect(argument.valueType.kind).to.equal(ValueType.Kind.integer);

    auto files = Argument.fromString("<files:file...>", "Files");
    expect(files.name).to.equal("files");
    expect(files.variadic).to.equal(true);
    expect(files.valueType.kind).to.equal(ValueType.Kind.file);
}

unittest {
    auto argument = Argument.fromString("<format:json|yaml>", "Format");
    expect(argument.name).to.equal("format");
    expect(argument.valueType.kind).to.equal(ValueType.Kind.choice);
    expect(argument.valueType.choices).to.equal(["json", "yaml"]);
}

unittest {
    auto spaced = Argument.fromString("< count : int >", "d");
    expect(spaced.name).to.equal("count");
    expect(spaced.valueType.kind).to.equal(ValueType.Kind.integer);

    auto variadic = Argument.fromString("<ids:int ...>", "d");
    expect(variadic.name).to.equal("ids");
    expect(variadic.variadic).to.equal(true);
    expect(variadic.valueType.kind).to.equal(ValueType.Kind.integer);
}

unittest {
    expect({ Argument.fromString("<x:float>", "d"); }).to.throwException!AssertError;
    expect({ Argument.fromString("<:int>", "d"); }).to.throwException!AssertError;
    expect({ Argument.fromString("[x:int]", "d", "a"); }).to.throwException!AssertError;
    expect({ Argument.fromString("[x:json|yaml]", "d", "xml"); }).to.throwException!AssertError;
    expect({ Argument.fromString("[x:int]", "d", "5"); }).to.not.throwException!AssertError;
}

unittest {
    expect(Argument.fromString("<count:int>", "d").formattedName()).to.equal("<count>");
    expect(Argument.fromString("[path:file]", "d").formattedName()).to.equal("[path]");
    expect(Argument.fromString("[ids:int...]", "d").formattedName()).to.equal("[ids...]");
    expect(Argument.fromString("<format:json|yaml>", "d").formattedName()).to.equal("<json|yaml>");
    expect(Argument.fromString("<format:json|yaml...>", "d").formattedName()).to.equal("<json|yaml...>");
}

unittest {
    expect(Argument.fromString("<count:int>", "d").formattedName(true).stripAnsi()).to.equal("<count>");
    expect(Argument.fromString("[ids:int...]", "d").formattedName(true).stripAnsi()).to.equal("[ids...]");
    expect(Argument.fromString("<format:json|yaml>", "d").formattedName(true).stripAnsi()).to.equal("<json|yaml>");
}

unittest {
    auto argument = Argument.fromString("<input>", "Input file");
    expect(argument.hasCompleter()).to.equal(false);
    expect(argument.completer((prefix) => ["a", "b"])).to.equal(argument);
    expect(argument.hasCompleter()).to.equal(true);
    expect(argument.complete("")).to.equal(["a", "b"]);
}

unittest {
    auto argument = Argument.fromString("<kind:x|y>", "Kind").completer((prefix) => ["z"]);
    expect(argument.valueType.accepts("x")).to.equal(true);
    expect(argument.valueType.accepts("z")).to.equal(false);
    expect(argument.complete("")).to.equal(["z"]);
}

unittest {
    auto argument = Argument.fromString("<input>", "Input file").completer((prefix) => [prefix ~ "!"]);
    expect(argument.complete("ab")).to.equal(["ab!"]);
    expect(argument.complete("")).to.equal(["!"]);
}
