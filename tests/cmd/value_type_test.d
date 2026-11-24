module cmd.value_type_test;

import core.exception : AssertError;
import std.exception : assertThrown;

import cmd.ansi;
import cmd.value_type;

unittest {
    assert(ValueType.init.kind == ValueType.Kind.text);
    assert(ValueType.init.choices.length == 0);
}

unittest {
    assert(ValueType.fromString("string").kind == ValueType.Kind.text);
    assert(ValueType.fromString("file").kind == ValueType.Kind.file);
    assert(ValueType.fromString("dir").kind == ValueType.Kind.dir);
    assert(ValueType.fromString("int").kind == ValueType.Kind.integer);
}

unittest {
    auto type = ValueType.fromString("json|yaml|toml");
    assert(type.kind == ValueType.Kind.choice);
    assert(type.choices == ["json", "yaml", "toml"]);
    assert(ValueType.fromString("a|b").choices == ["a", "b"]);
}

unittest {
    foreach (name; ["", "float", "Int", "File", "json", "json|", "|yaml", "a||b", "|"])
        assertThrown!AssertError(ValueType.fromString(name));
}

unittest {
    foreach (name; ["string", "file", "dir"]) {
        auto type = ValueType.fromString(name);
        assert(type.accepts("anything"));
        assert(type.accepts(""));
        assert(type.accepts("-x"));
    }
    assert(ValueType.init.accepts("anything"));
}

unittest {
    auto type = ValueType.fromString("int");
    foreach (value; ["0", "1", "9", "42", "-1", "-42", "1234567890", "123456789012345678901234567890",
            "-98765432109876543210"])
        assert(type.accepts(value), value);
    foreach (value; ["", "-", "--1", "-0", "00", "01", "-01", "+1", "1.5", "1e3", "abc", "1a", "a1", " 1", "1 ",
            "1_000", "0x10"])
        assert(!type.accepts(value), value);
}

unittest {
    auto type = ValueType.fromString("json|yaml");
    assert(type.accepts("json"));
    assert(type.accepts("yaml"));
    foreach (value; ["", "JSON", "jso", "jsonx", "json|yaml", "xml", " json"])
        assert(!type.accepts(value), value);
}

unittest {
    assert(ValueType.fromString("int").expected() == "an integer");
    assert(ValueType.fromString("json|yaml|toml").expected() == "one of: json, yaml, toml");
}

unittest {
    assert(ValueType.init.label("name") == "name");
    assert(ValueType.fromString("int").label("count") == "count");
    assert(ValueType.fromString("file").label("path") == "path");
    assert(ValueType.fromString("json|yaml").label("format") == "json|yaml");
}

unittest {
    assert(ValueType.fromString("int").label("count", true).stripAnsi() == "count");
    assert(ValueType.fromString("json|yaml").label("format", true).stripAnsi() == "json|yaml");
}
