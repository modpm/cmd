module cmd.parsed_args_test;

import core.exception : AssertError;
import std.exception : assertThrown, collectException;

import cmd.argument;
import cmd.command;
import cmd.flag;
import cmd.option;
import cmd.parsed_args;
import cmd.program;

private ParsedArgs blank(const(Command) command) {
    return new ParsedArgs(command, new Program("app"));
}

unittest {
    auto parsed = blank(new Command("c"));
    auto flag = new Flag("v", "verbose", "d");
    assert(!parsed.hasFlag("verbose"));
    assert(!parsed.hasFlag(flag));
    assert(parsed.flag("verbose") == 0);
    assert(parsed.flag(flag) == 0);
}

unittest {
    auto parsed = blank(new Command("c"));
    auto flag = new Flag("v", "verbose", "d");
    parsed.setFlag(flag, 3);
    foreach (name; ["verbose", "v", "-v", "--verbose"]) {
        assert(parsed.hasFlag(name));
        assert(parsed.flag(name) == 3);
    }
    assert(parsed.hasFlag(flag));
    assert(parsed.flag(flag) == 3);
    assert(!parsed.hasFlag("other"));
    assert(parsed.flag("other") == 0);
}

unittest {
    auto parsed = blank(new Command("c"));
    auto flag = new Flag("v", "verbose", "d");
    parsed.setFlag(flag, 1);
    parsed.setFlag(flag, 2);
    assert(parsed.flag(flag) == 2);
    parsed.setFlag(flag, 0);
    assert(!parsed.hasFlag(flag));
    assert(!parsed.hasFlag("verbose"));
    assert(!parsed.hasFlag("v"));
    assert(parsed.flag(flag) == 0);
}

unittest {
    auto parsed = blank(new Command("c"));
    auto onlyLong = new Flag(null, "only", "d");
    auto onlyShort = new Flag("s", null, "d");
    parsed.setFlag(onlyLong, 1);
    parsed.setFlag(onlyShort, 2);
    assert(parsed.hasFlag("only"));
    assert(parsed.hasFlag("--only"));
    assert(parsed.hasFlag(onlyLong));
    assert(parsed.flag(onlyLong) == 1);
    assert(parsed.hasFlag("s"));
    assert(parsed.hasFlag("-s"));
    assert(parsed.hasFlag(onlyShort));
    assert(parsed.flag(onlyShort) == 2);
}

unittest {
    auto parsed = blank(new Command("c"));
    auto option = new Option("t", "target", "name", "d", true);
    assert(!parsed.hasOption(option));
    assert(!parsed.hasOption("target"));
    parsed.setOption(option, ["a", "b"]);
    assert(parsed.hasOption(option));
    foreach (name; ["target", "t", "-t", "--target"]) {
        assert(parsed.hasOption(name));
        assert(parsed.option(name) == "a");
        assert(parsed.optionList(name) == ["a", "b"]);
    }
    assert(parsed.optionList(option) == ["a", "b"]);
    assert(!parsed.hasOption("other"));
}

unittest {
    auto parsed = blank(new Command("c"));
    auto option = new Option("t", "target", "name", "d", true);
    parsed.setOption(option, ["a"]);
    assertThrown!AssertError(parsed.setOption(option, ["b"]));
    assertThrown!AssertError(parsed.setOption(new Option("t", "target", "other", "d", true), ["b"]));
}

unittest {
    auto parsed = blank(new Command("c"));
    auto onlyLong = new Option(null, "long", "v", "d", false);
    auto onlyShort = new Option("s", null, "v", "d", false);
    parsed.setOption(onlyLong, ["x"]);
    parsed.setOption(onlyShort, ["y"]);
    assert(parsed.hasOption(onlyLong));
    assert(parsed.hasOption("long"));
    assert(parsed.hasOption("--long"));
    assert(parsed.optionList(onlyLong) == ["x"]);
    assert(parsed.hasOption(onlyShort));
    assert(parsed.hasOption("s"));
    assert(parsed.hasOption("-s"));
    assert(parsed.optionList(onlyShort) == ["y"]);
}

unittest {
    auto parsed = blank(new Command("c"));
    auto missing = collectException(parsed.option("nope"));
    assert(missing !is null);
    assert(missing.msg == "Option 'nope' not found");
    auto missingList = collectException(parsed.optionList("nope"));
    assert(missingList !is null);
    assert(missingList.msg == "Option 'nope' not found");
}

unittest {
    auto parsed = blank(new Command("c"));
    auto option = new Option("t", "target", "name", "d", true);
    parsed.setOption(option, ["first", "second"]);
    assert(parsed.option("target") == "first");
    assert(parsed.option("-t") == "first");
}

unittest {
    auto command = new Command("c").argument("<input>", "d");
    auto parsed = blank(command);
    auto argument = Argument.fromString("<input>", "d");
    assert(!parsed.hasArgument("input"));
    assert(!parsed.hasArgument(argument));
    parsed.setArgument(argument, "value");
    assert(parsed.hasArgument("input"));
    assert(parsed.hasArgument(argument));
    assert(parsed.argument("input") == "value");
    assert(parsed.argumentList("input") == ["value"]);
    assert(!parsed.hasArgument("other"));
}

unittest {
    auto parsed = blank(new Command("c"));
    auto argument = Argument.fromString("<input>", "d");
    parsed.setArgument(argument, "value");
    assertThrown!AssertError(parsed.setArgument(argument, "again"));
}

unittest {
    auto parsed = blank(new Command("c"));
    auto missing = collectException(parsed.argument("nope"));
    assert(missing !is null);
    assert(missing.msg == "Argument 'nope' not found");
    auto missingList = collectException(parsed.argumentList("nope"));
    assert(missingList !is null);
    assert(missingList.msg == "Argument 'nope' not found");
}

unittest {
    auto command = new Command("c").argument("<files...>", "d");
    auto parsed = blank(command);
    assert(!parsed.hasArgument("files"));
    auto missing = collectException(parsed.argumentList("files"));
    assert(missing !is null);
    assert(missing.msg == "Argument 'files' not found");

    parsed.setArgumentList(["a", "b", "c"]);
    assert(parsed.hasArgument("files"));
    assert(parsed.hasArgument(Argument.fromString("<files...>", "d")));
    assert(parsed.argument("files") == "a");
    assert(parsed.argumentList("files") == ["a", "b", "c"]);
    assert(parsed.variadic == ["a", "b", "c"]);
}

unittest {
    auto command = new Command("c").argument("<files...>", "d");
    auto parsed = blank(command);
    parsed.setArgumentList(["a"]);
    assertThrown!AssertError(parsed.setArgumentList(["b"]));
}

unittest {
    auto command = new Command("c").argument("<files...>", "d");
    auto parsed = blank(command);
    parsed.setArgumentList([]);
    assert(!parsed.hasArgument("files"));
    parsed.setArgumentList(["x"]);
    assert(parsed.hasArgument("files"));
    assert(parsed.argumentList("files") == ["x"]);
}

unittest {
    auto command = new Command("c").argument("<input>", "d").argument("<files...>", "d");
    auto parsed = blank(command);
    parsed.setArgumentList(["a", "b"]);
    assert(parsed.hasArgument("files"));
    assert(!parsed.hasArgument("input"));
    assert(!parsed.hasArgument("other"));
    parsed.setArgument(Argument.fromString("<input>", "d"), "first");
    assert(parsed.argument("input") == "first");
    assert(parsed.argumentList("input") == ["first"]);
    assert(parsed.argumentList("files") == ["a", "b"]);
}
