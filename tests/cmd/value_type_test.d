module cmd.value_type_test;

import core.exception : AssertError;

import fluent.asserts;

import cmd.ansi;
import cmd.value_type;

unittest {
    expect(ValueType.init.kind).to.equal(ValueType.Kind.text);
    expect(ValueType.init.choices.length).to.equal(0);
}

unittest {
    expect(ValueType.fromString("string").kind).to.equal(ValueType.Kind.text);
    expect(ValueType.fromString("file").kind).to.equal(ValueType.Kind.file);
    expect(ValueType.fromString("dir").kind).to.equal(ValueType.Kind.dir);
    expect(ValueType.fromString("int").kind).to.equal(ValueType.Kind.integer);
}

unittest {
    auto type = ValueType.fromString("json|yaml|toml");
    expect(type.kind).to.equal(ValueType.Kind.choice);
    expect(type.choices).to.equal(["json", "yaml", "toml"]);
    expect(ValueType.fromString("a|b").choices).to.equal(["a", "b"]);
}

unittest {
    foreach (name; ["", "float", "Int", "File", "json", "json|", "|yaml", "a||b", "|"])
        expect({ ValueType.fromString(name); }).to.throwException!AssertError;
}

unittest {
    foreach (name; ["string", "file", "dir"]) {
        auto type = ValueType.fromString(name);
        expect(type.accepts("anything")).to.equal(true);
        expect(type.accepts("")).to.equal(true);
        expect(type.accepts("-x")).to.equal(true);
    }
    expect(ValueType.init.accepts("anything")).to.equal(true);
}

unittest {
    auto type = ValueType.fromString("int");
    foreach (value; ["0", "1", "9", "42", "-1", "-42", "1234567890", "123456789012345678901234567890",
            "-98765432109876543210"])
        expect(type.accepts(value)).to.equal(true).because(value);
    foreach (value; ["", "-", "--1", "-0", "00", "01", "-01", "+1", "1.5", "1e3", "abc", "1a", "a1", " 1", "1 ",
            "1_000", "0x10"])
        expect(type.accepts(value)).to.equal(false).because(value);
}

unittest {
    auto type = ValueType.fromString("json|yaml");
    expect(type.accepts("json")).to.equal(true);
    expect(type.accepts("yaml")).to.equal(true);
    foreach (value; ["", "JSON", "jso", "jsonx", "json|yaml", "xml", " json"])
        expect(type.accepts(value)).to.equal(false).because(value);
}

unittest {
    expect(ValueType.fromString("int").expected()).to.equal("an integer");
    expect(ValueType.fromString("json|yaml|toml").expected()).to.equal("one of: json, yaml, toml");
}

unittest {
    expect(ValueType.init.label("name")).to.equal("name");
    expect(ValueType.fromString("int").label("count")).to.equal("count");
    expect(ValueType.fromString("file").label("path")).to.equal("path");
    expect(ValueType.fromString("json|yaml").label("format")).to.equal("json|yaml");
}

unittest {
    expect(ValueType.fromString("int").label("count", true).stripAnsi()).to.equal("count");
    expect(ValueType.fromString("json|yaml").label("format", true).stripAnsi()).to.equal("json|yaml");
}
