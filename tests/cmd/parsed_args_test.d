module cmd.parsed_args_test;

import core.exception : AssertError;
import std.exception : collectException;

import fluent.asserts;

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
    expect(parsed.hasFlag("verbose")).to.equal(false);
    expect(parsed.hasFlag(flag)).to.equal(false);
    expect(parsed.flag("verbose")).to.equal(0);
    expect(parsed.flag(flag)).to.equal(0);
}

unittest {
    auto parsed = blank(new Command("c"));
    auto flag = new Flag("v", "verbose", "d");
    parsed.setFlag(flag, 3);
    foreach (name; ["verbose", "v", "-v", "--verbose"]) {
        expect(parsed.hasFlag(name)).to.equal(true);
        expect(parsed.flag(name)).to.equal(3);
    }
    expect(parsed.hasFlag(flag)).to.equal(true);
    expect(parsed.flag(flag)).to.equal(3);
    expect(parsed.hasFlag("other")).to.equal(false);
    expect(parsed.flag("other")).to.equal(0);
}

unittest {
    auto parsed = blank(new Command("c"));
    auto flag = new Flag("v", "verbose", "d");
    parsed.setFlag(flag, 1);
    parsed.setFlag(flag, 2);
    expect(parsed.flag(flag)).to.equal(2);
    parsed.setFlag(flag, 0);
    expect(parsed.hasFlag(flag)).to.equal(false);
    expect(parsed.hasFlag("verbose")).to.equal(false);
    expect(parsed.hasFlag("v")).to.equal(false);
    expect(parsed.flag(flag)).to.equal(0);
}

unittest {
    auto parsed = blank(new Command("c"));
    auto onlyLong = new Flag(null, "only", "d");
    auto onlyShort = new Flag("s", null, "d");
    parsed.setFlag(onlyLong, 1);
    parsed.setFlag(onlyShort, 2);
    expect(parsed.hasFlag("only")).to.equal(true);
    expect(parsed.hasFlag("--only")).to.equal(true);
    expect(parsed.hasFlag(onlyLong)).to.equal(true);
    expect(parsed.flag(onlyLong)).to.equal(1);
    expect(parsed.hasFlag("s")).to.equal(true);
    expect(parsed.hasFlag("-s")).to.equal(true);
    expect(parsed.hasFlag(onlyShort)).to.equal(true);
    expect(parsed.flag(onlyShort)).to.equal(2);
}

unittest {
    auto parsed = blank(new Command("c"));
    auto option = new Option("t", "target", "name", "d", true);
    expect(parsed.hasOption(option)).to.equal(false);
    expect(parsed.hasOption("target")).to.equal(false);
    parsed.setOption(option, ["a", "b"]);
    expect(parsed.hasOption(option)).to.equal(true);
    foreach (name; ["target", "t", "-t", "--target"]) {
        expect(parsed.hasOption(name)).to.equal(true);
        expect(parsed.option(name)).to.equal("a");
        expect(parsed.optionList(name)).to.equal(["a", "b"]);
    }
    expect(parsed.optionList(option)).to.equal(["a", "b"]);
    expect(parsed.hasOption("other")).to.equal(false);
}

unittest {
    auto parsed = blank(new Command("c"));
    auto option = new Option("t", "target", "name", "d", true);
    parsed.setOption(option, ["a"]);
    expect({ parsed.setOption(option, ["b"]); }).to.throwException!AssertError;
    expect({ parsed.setOption(new Option("t", "target", "other", "d", true), ["b"]); }).to.throwException!AssertError;
}

unittest {
    auto parsed = blank(new Command("c"));
    auto onlyLong = new Option(null, "long", "v", "d", false);
    auto onlyShort = new Option("s", null, "v", "d", false);
    parsed.setOption(onlyLong, ["x"]);
    parsed.setOption(onlyShort, ["y"]);
    expect(parsed.hasOption(onlyLong)).to.equal(true);
    expect(parsed.hasOption("long")).to.equal(true);
    expect(parsed.hasOption("--long")).to.equal(true);
    expect(parsed.optionList(onlyLong)).to.equal(["x"]);
    expect(parsed.hasOption(onlyShort)).to.equal(true);
    expect(parsed.hasOption("s")).to.equal(true);
    expect(parsed.hasOption("-s")).to.equal(true);
    expect(parsed.optionList(onlyShort)).to.equal(["y"]);
}

unittest {
    auto parsed = blank(new Command("c"));
    auto missing = collectException(parsed.option("nope"));
    expect(missing).to.not.beNull;
    expect(missing.msg).to.equal("Option 'nope' not found");
    auto missingList = collectException(parsed.optionList("nope"));
    expect(missingList).to.not.beNull;
    expect(missingList.msg).to.equal("Option 'nope' not found");
}

unittest {
    auto parsed = blank(new Command("c"));
    auto option = new Option("t", "target", "name", "d", true);
    parsed.setOption(option, ["first", "second"]);
    expect(parsed.option("target")).to.equal("first");
    expect(parsed.option("-t")).to.equal("first");
}

unittest {
    auto command = new Command("c").argument("<input>", "d");
    auto parsed = blank(command);
    auto argument = Argument.fromString("<input>", "d");
    expect(parsed.hasArgument("input")).to.equal(false);
    expect(parsed.hasArgument(argument)).to.equal(false);
    parsed.setArgument(argument, "value");
    expect(parsed.hasArgument("input")).to.equal(true);
    expect(parsed.hasArgument(argument)).to.equal(true);
    expect(parsed.argument("input")).to.equal("value");
    expect(parsed.argumentList("input")).to.equal(["value"]);
    expect(parsed.hasArgument("other")).to.equal(false);
}

unittest {
    auto parsed = blank(new Command("c"));
    auto argument = Argument.fromString("<input>", "d");
    parsed.setArgument(argument, "value");
    expect({ parsed.setArgument(argument, "again"); }).to.throwException!AssertError;
}

unittest {
    auto parsed = blank(new Command("c"));
    auto missing = collectException(parsed.argument("nope"));
    expect(missing).to.not.beNull;
    expect(missing.msg).to.equal("Argument 'nope' not found");
    auto missingList = collectException(parsed.argumentList("nope"));
    expect(missingList).to.not.beNull;
    expect(missingList.msg).to.equal("Argument 'nope' not found");
}

unittest {
    auto command = new Command("c").argument("<files...>", "d");
    auto parsed = blank(command);
    expect(parsed.hasArgument("files")).to.equal(false);
    auto missing = collectException(parsed.argumentList("files"));
    expect(missing).to.not.beNull;
    expect(missing.msg).to.equal("Argument 'files' not found");

    parsed.setArgumentList(["a", "b", "c"]);
    expect(parsed.hasArgument("files")).to.equal(true);
    expect(parsed.hasArgument(Argument.fromString("<files...>", "d"))).to.equal(true);
    expect(parsed.argument("files")).to.equal("a");
    expect(parsed.argumentList("files")).to.equal(["a", "b", "c"]);
    expect(parsed.variadic).to.equal(["a", "b", "c"]);
}

unittest {
    auto command = new Command("c").argument("<files...>", "d");
    auto parsed = blank(command);
    parsed.setArgumentList(["a"]);
    expect({ parsed.setArgumentList(["b"]); }).to.throwException!AssertError;
}

unittest {
    auto command = new Command("c").argument("<files...>", "d");
    auto parsed = blank(command);
    parsed.setArgumentList([]);
    expect(parsed.hasArgument("files")).to.equal(false);
    parsed.setArgumentList(["x"]);
    expect(parsed.hasArgument("files")).to.equal(true);
    expect(parsed.argumentList("files")).to.equal(["x"]);
}

unittest {
    auto command = new Command("c").argument("<input>", "d").argument("<files...>", "d");
    auto parsed = blank(command);
    parsed.setArgumentList(["a", "b"]);
    expect(parsed.hasArgument("files")).to.equal(true);
    expect(parsed.hasArgument("input")).to.equal(false);
    expect(parsed.hasArgument("other")).to.equal(false);
    parsed.setArgument(Argument.fromString("<input>", "d"), "first");
    expect(parsed.argument("input")).to.equal("first");
    expect(parsed.argumentList("input")).to.equal(["first"]);
    expect(parsed.argumentList("files")).to.equal(["a", "b"]);
}
