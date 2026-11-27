module cmd.parser_test;

import std.exception : collectException;

import fluent.asserts;

import cmd.program;
import cmd.test_support;

unittest {
    Program program = new TestProgram("app").option("-v, --verbose", "Verbose");

    auto absent = parseOk(program);
    expect(absent.hasFlag("verbose")).to.equal(false);
    expect(absent.flag("verbose")).to.equal(0);

    auto viaShort = parseOk(program, "-v");
    auto viaLong = parseOk(program, "--verbose");
    foreach (name; ["verbose", "v", "-v", "--verbose"]) {
        expect(viaShort.hasFlag(name)).to.equal(true);
        expect(viaShort.flag(name)).to.equal(1);
        expect(viaLong.hasFlag(name)).to.equal(true);
        expect(viaLong.flag(name)).to.equal(1);
    }
    expect(viaShort.hasFlag("other")).to.equal(false);
}

unittest {
    Program program = new TestProgram("app").option("-v, --verbose", "Verbose");
    expect(parseOk(program, "-v", "-v").flag("verbose")).to.equal(2);
    expect(parseOk(program, "-v", "--verbose", "-v").flag("verbose")).to.equal(3);
    expect(parseOk(program, "--verbose", "--verbose").flag("v")).to.equal(2);
    expect(parseOk(program, "-vvv").flag("verbose")).to.equal(3);
    expect(parseOk(program, "-vv", "-v").flag("verbose")).to.equal(3);
}

unittest {
    Program program = new TestProgram("app").option("--only-long", "d").option("-s", "d");
    auto parsed = parseOk(program, "--only-long", "-s", "-s");
    expect(parsed.hasFlag("only-long")).to.equal(true);
    expect(parsed.hasFlag("--only-long")).to.equal(true);
    expect(parsed.flag("only-long")).to.equal(1);
    expect(parsed.hasFlag("s")).to.equal(true);
    expect(parsed.hasFlag("-s")).to.equal(true);
    expect(parsed.flag("s")).to.equal(2);
}

unittest {
    Program program = new TestProgram("app")
        .option("-a, --all", "d")
        .option("-b, --brief", "d")
        .option("-c", "d");
    auto parsed = parseOk(program, "-abc");
    expect(parsed.flag("all")).to.equal(1);
    expect(parsed.flag("brief")).to.equal(1);
    expect(parsed.flag("c")).to.equal(1);

    auto counted = parseOk(program, "-aab", "-a", "-c");
    expect(counted.flag("all")).to.equal(3);
    expect(counted.flag("brief")).to.equal(1);
    expect(counted.flag("c")).to.equal(1);
}

unittest {
    Program program = new TestProgram("app")
        .option("-a, --all", "d")
        .option("-t, --target <n>", "d");
    assertFails(program, "unknown option '-z'", "-az");
    assertFails(program, "unknown option '-z'", "-za");
    assertFails(program, "missing value for option '-t'", "-at");
    assertFails(program, "missing value for option '-t'", "-ta");
    assertFails(program, "missing value for option '-t'", "-at", "value");
    assertFails(program, "missing value for option '-t'", "-tvalue");
}

unittest {
    Program program = new TestProgram("app")
        .option("-a, --all", "d")
        .option("-b, --brief", "d");
    assertFails(program, "unexpected '=' for option '-a'", "-a=1");
    assertFails(program, "unexpected '=' for option '--all'", "--all=1");
    assertFails(program, "unexpected '=' for option '--all'", "--all=");
    assertFails(program, "unexpected '=' in combined short options '-ab'", "-ab=1");
}

unittest {
    Program program = new TestProgram("app").option("-v, --verbose", "d");
    assertFails(program, "unknown option '--nope'", "--nope");
    assertFails(program, "unknown option '--nope'", "--nope=1");
    assertFails(program, "unknown option '-n'", "-n");
    assertFails(program, "unknown option '-5'", "-5");
    assertFails(program, "unknown option '--verbos', did you mean '--verbose'?", "--verbos");
    assertFails(program, "unknown option '--verbose2', did you mean '--verbose'?", "--verbose2");
}

unittest {
    Program program = new TestProgram("app").option("-t, --target <name>", "Target");
    foreach (args; [["--target", "x"], ["--target=x"], ["-t", "x"], ["-t=x"]]) {
        auto parsed = parseOk(program, args);
        foreach (name; ["target", "t", "-t", "--target"]) {
            expect(parsed.hasOption(name)).to.equal(true);
            expect(parsed.option(name)).to.equal("x");
            expect(parsed.optionList(name)).to.equal(["x"]);
        }
    }
}

unittest {
    Program program = new TestProgram("app").option("-t, --target <name>", "Target");
    auto parsed = parseOk(program, "--target", "a", "-t", "b", "--target=c", "-t=d");
    expect(parsed.option("target")).to.equal("a");
    expect(parsed.optionList("target")).to.equal(["a", "b", "c", "d"]);
    expect(parsed.optionList("t")).to.equal(["a", "b", "c", "d"]);
}

unittest {
    Program program = new TestProgram("app").option("-t, --target <name>", "Target");
    expect(parseOk(program, "--target=").option("target")).to.equal("");
    expect(parseOk(program, "-t=").option("target")).to.equal("");
    expect(parseOk(program, "--target", "").option("target")).to.equal("");
    expect(parseOk(program, "--target=a=b").option("target")).to.equal("a=b");
    expect(parseOk(program, "-t=a=b").option("target")).to.equal("a=b");
    expect(parseOk(program, "--target==x").option("target")).to.equal("=x");
}

unittest {
    Program program = new TestProgram("app")
        .option("-t, --target <name>", "Target")
        .option("-v, --verbose", "Verbose");
    expect(parseOk(program, "--target", "--verbose").option("target")).to.equal("--verbose");
    expect(parseOk(program, "--target", "--verbose").hasFlag("verbose")).to.equal(false);
    expect(parseOk(program, "-t", "-5").option("target")).to.equal("-5");
    expect(parseOk(program, "-t", "-v").option("t")).to.equal("-v");
}

unittest {
    Program program = new TestProgram("app").option("--target [name]", "Target").option("-o [file]", "Out");
    expect(parseOk(program, "--target", "x").option("target")).to.equal("x");
    expect(parseOk(program, "--target=x").option("--target")).to.equal("x");
    expect(parseOk(program, "-o", "f").option("o")).to.equal("f");
    expect(parseOk(program, "-o=f").option("-o")).to.equal("f");
    expect(parseOk(program, "-o", "f").hasOption("-o")).to.equal(true);
}

unittest {
    Program program = new TestProgram("app")
        .option("-t, --target <name>", "Target")
        .option("--other [name]", "Other");
    assertFails(program, "missing value for option '--target'", "--target");
    assertFails(program, "missing value for option '-t'", "-t");
    assertFails(program, "missing value for option '--other'", "--other");
    assertFails(program, "missing value for option '--target'", "--target=x", "--target");
}

unittest {
    Program program = new TestProgram("app").option("-t, --target <name>", "Target");
    assertFails(program, "missing required option '-t, --target <name>'");
}

unittest {
    Program program = new TestProgram("app").option("--target <name>", "Target");
    assertFails(program, "missing required option '--target <name>'");

    Program shortOnly = new TestProgram("app").option("-t <name>", "Target");
    assertFails(shortOnly, "missing required option '-t <name>'");
}

unittest {
    Program program = new TestProgram("app")
        .option("-a, --first <x>", "d")
        .option("-b, --second <x>", "d");
    assertFails(program, "missing required option '-a, --first <x>'");
    assertFails(program, "missing required option '-b, --second <x>'", "--first", "1");
    expect(parseOk(program, "--first", "1", "--second", "2").option("second")).to.equal("2");
}

unittest {
    Program program = new TestProgram("app")
        .option("-p, --port [number]", "Port", "8080")
        .option("-c, --config [file]", "Config");

    auto absent = parseOk(program);
    expect(absent.hasOption("port")).to.equal(true);
    expect(absent.option("port")).to.equal("8080");
    expect(absent.option("p")).to.equal("8080");
    expect(absent.optionList("port")).to.equal(["8080"]);
    expect(absent.hasOption("config")).to.equal(false);
    expect(absent.hasOption("c")).to.equal(false);
    auto missing = collectException(absent.option("config"));
    expect(missing).to.not.beNull;
    expect(missing.msg).to.equal("Option 'config' not found");
}

unittest {
    Program program = new TestProgram("app")
        .option("-p, --port [number]", "Port", "8080");
    auto overridden = parseOk(program, "-p", "9");
    expect(overridden.option("port")).to.equal("9");
    expect(overridden.optionList("port")).to.equal(["9"]);

    auto repeated = parseOk(program, "-p", "1", "--port=2");
    expect(repeated.optionList("port")).to.equal(["1", "2"]);
}

unittest {
    Program program = new TestProgram("app")
        .option("-c, --config [file]", "Config");
    auto parsed = parseOk(program, "--config", "x.toml");
    expect(parsed.hasOption("config")).to.equal(true);
    expect(parsed.option("config")).to.equal("x.toml");
}

unittest {
    Program program = new TestProgram("app")
        .argument("<input>", "Input")
        .argument("[output]", "Output");

    auto both = parseOk(program, "in", "out");
    expect(both.hasArgument("input")).to.equal(true);
    expect(both.hasArgument("output")).to.equal(true);
    expect(both.argument("input")).to.equal("in");
    expect(both.argument("output")).to.equal("out");
    expect(both.argumentList("input")).to.equal(["in"]);

    auto onlyRequired = parseOk(program, "in");
    expect(onlyRequired.argument("input")).to.equal("in");
    expect(onlyRequired.hasArgument("output")).to.equal(false);
    auto missing = collectException(onlyRequired.argument("output"));
    expect(missing).to.not.beNull;
    expect(missing.msg).to.equal("Argument 'output' not found");
}

unittest {
    Program program = new TestProgram("app").argument("<input>", "Input");
    assertFails(program, "missing required argument 'input'");
    assertFails(program, "unexpected argument 'b'", "a", "b");
}

unittest {
    Program program = new TestProgram("app");
    assertFails(program, "unexpected argument 'x'", "x");
    expect(parseOk(program).command is program).to.equal(true);
}

unittest {
    Program program = new TestProgram("app")
        .argument("<a>", "d")
        .argument("<b>", "d");
    assertFails(program, "missing required argument 'b'", "x");
    assertFails(program, "missing required argument 'a'");
    auto parsed = parseOk(program, "x", "y");
    expect(parsed.argument("a")).to.equal("x");
    expect(parsed.argument("b")).to.equal("y");
}

unittest {
    Program program = new TestProgram("app")
        .argument("[output]", "Output", "out.txt");
    auto absent = parseOk(program);
    expect(absent.hasArgument("output")).to.equal(true);
    expect(absent.argument("output")).to.equal("out.txt");
    expect(parseOk(program, "x.txt").argument("output")).to.equal("x.txt");
}

unittest {
    Program program = new TestProgram("app")
        .argument("[first]", "d")
        .argument("<second>", "d");
    assertFails(program, "missing required argument 'second'", "x");
    auto parsed = parseOk(program, "x", "y");
    expect(parsed.argument("first")).to.equal("x");
    expect(parsed.argument("second")).to.equal("y");
}

unittest {
    Program program = new TestProgram("app").argument("<files...>", "Files");
    auto many = parseOk(program, "a", "b", "c");
    expect(many.hasArgument("files")).to.equal(true);
    expect(many.argument("files")).to.equal("a");
    expect(many.argumentList("files")).to.equal(["a", "b", "c"]);
    expect(parseOk(program, "a").argumentList("files")).to.equal(["a"]);
    assertFails(program, "missing required argument 'files'");
}

unittest {
    Program program = new TestProgram("app").argument("[files...]", "Files");
    auto many = parseOk(program, "a", "b");
    expect(many.argumentList("files")).to.equal(["a", "b"]);
    auto none = parseOk(program);
    expect(none.hasArgument("files")).to.equal(false);
    auto missing = collectException(none.argumentList("files"));
    expect(missing).to.not.beNull;
    expect(missing.msg).to.equal("Argument 'files' not found");
}

unittest {
    Program program = new TestProgram("app").argument("[files...]", "Files", "default.txt");
    expect(parseOk(program).argumentList("files")).to.equal(["default.txt"]);
    expect(parseOk(program).argument("files")).to.equal("default.txt");
    expect(parseOk(program, "a", "b").argumentList("files")).to.equal(["a", "b"]);
}

unittest {
    Program program = new TestProgram("app")
        .argument("<command>", "d")
        .argument("[rest...]", "d");
    auto parsed = parseOk(program, "run", "a", "b", "c");
    expect(parsed.argument("command")).to.equal("run");
    expect(parsed.argumentList("rest")).to.equal(["a", "b", "c"]);
    expect(parsed.argumentList("command")).to.equal(["run"]);

    auto single = parseOk(program, "run");
    expect(single.argument("command")).to.equal("run");
    expect(single.hasArgument("rest")).to.equal(false);

    assertFails(program, "missing required argument 'command'");
}

unittest {
    Program program = new TestProgram("app")
        .option("-v, --verbose", "d")
        .option("-t, --target <n>", "d")
        .argument("<input>", "d")
        .argument("[files...]", "d");
    auto parsed = parseOk(program, "a", "-v", "b", "--target", "x", "c", "-t=y", "d");
    expect(parsed.hasFlag("verbose")).to.equal(true);
    expect(parsed.optionList("target")).to.equal(["x", "y"]);
    expect(parsed.argument("input")).to.equal("a");
    expect(parsed.argumentList("files")).to.equal(["b", "c", "d"]);
}

unittest {
    Program program = new TestProgram("app").argument("<value>", "d");
    auto parsed = parseOk(program, "");
    expect(parsed.hasArgument("value")).to.equal(true);
    expect(parsed.argument("value")).to.equal("");
}

unittest {
    Program program = new TestProgram("app")
        .option("-t, --target <n>", "d")
        .argument("<input>", "d");
    assertFails(program, "missing required option '-t, --target <n>'");
    assertFails(program, "missing required argument 'input'", "-t", "x");
    assertFails(program, "missing required option '-t, --target <n>'", "in");
}

unittest {
    Program program = new TestProgram("app").option("-t, --target <n>", "d");
    auto parsed = parseOk(program, "-t", "x");
    expect(parsed.command is program).to.equal(true);
    expect(parsed.program is program).to.equal(true);
}

unittest {
    auto sub = new TestCommand("sub")
        .option("--flag", "d")
        .argument("<x>", "d");
    Program program = new TestProgram("app").command(sub);

    auto parsed = parseOk(program, "sub", "val", "--flag");
    expect(parsed.command is sub).to.equal(true);
    expect(parsed.program is program).to.equal(true);
    expect(parsed.hasFlag("flag")).to.equal(true);
    expect(parsed.argument("x")).to.equal("val");
}

unittest {
    auto sub = new TestCommand("sub")
        .option("--flag", "d")
        .argument("<x>", "d");
    Program program = new TestProgram("app").command(sub);

    auto parsed = parseOk(program, "--flag", "sub", "val");
    expect(parsed.command is sub).to.equal(true);
    expect(parsed.hasFlag("flag")).to.equal(true);
    expect(parsed.argument("x")).to.equal("val");
}

unittest {
    auto sub = new TestCommand("sub").argument("<x>", "d");
    Program program = new TestProgram("app").command(sub);
    assertFails(program, "unknown command 'nope'", "nope");
    assertFails(program, "unknown command 'nope'", "--flag", "nope");
    assertFails(program, "unknown command 'sub2', did you mean 'sub'?", "sub2", "x");
    assertFails(program, "missing required argument 'x'", "sub");
    assertFails(program, "unexpected argument 'b'", "sub", "a", "b");
}

unittest {
    auto sub = new TestCommand("sub");
    Program program = new TestProgram("app").command(sub);
    assertFails(program, "unknown option '--flag'", "--flag");
    assertFails(program, "unknown option '--flag'", "sub", "--flag");
    expect(parseOk(program).command is program).to.equal(true);
}

unittest {
    auto first = new TestCommand("first").argument("<x>", "d");
    auto second = new TestCommand("second").option("--flag", "d");
    Program program = new TestProgram("app").command(first).command(second);

    auto viaFirst = parseOk(program, "first", "v");
    expect(viaFirst.command is first).to.equal(true);
    expect(viaFirst.argument("x")).to.equal("v");

    auto viaSecond = parseOk(program, "second", "--flag");
    expect(viaSecond.command is second).to.equal(true);
    expect(viaSecond.hasFlag("flag")).to.equal(true);
    expect(viaSecond.hasArgument("x")).to.equal(false);
}

unittest {
    Program program = new TestProgram("app");
    auto mid = new TestCommand("mid");
    program.add(mid);
    auto leaf = new TestCommand("leaf").argument("<v>", "d");
    mid.add(leaf);

    auto parsed = parseOk(program, "mid", "leaf", "x");
    expect(parsed.command is leaf).to.equal(true);
    expect(parsed.argument("v")).to.equal("x");
    expect(parseOk(program, "mid").command is mid).to.equal(true);
    assertFails(program, "unknown command 'leaf'", "leaf");
    assertFails(program, "unknown command 'other'", "mid", "other");
    assertFails(program, "missing required argument 'v'", "mid", "leaf");
}

unittest {
    Program program = new TestProgram("app");
    auto mid = new TestCommand("mid").option("--deep", "d");
    program.add(mid);
    auto leaf = new TestCommand("leaf").option("--leaf-flag", "d");
    mid.add(leaf);

    auto parsed = parseOk(program, "--leaf-flag", "mid", "leaf");
    expect(parsed.command is leaf).to.equal(true);
    expect(parsed.hasFlag("leaf-flag")).to.equal(true);
    assertFails(program, "unknown option '--deep'", "mid", "leaf", "--deep");
}

unittest {
    Program program = new TestProgram("app").option("-p, --port <number:int>", "Port");
    foreach (value; ["0", "80", "-1", "65536", "123456789012345678901234567890"]) {
        expect(parseOk(program, "--port", value).option("port")).to.equal(value);
        expect(parseOk(program, "-p", value).option("port")).to.equal(value);
        expect(parseOk(program, "--port=" ~ value).option("port")).to.equal(value);
        expect(parseOk(program, "-p=" ~ value).option("port")).to.equal(value);
    }
}

unittest {
    Program program = new TestProgram("app").option("-p, --port <number:int>", "Port");
    foreach (value; ["abc", "", "01", "-0", "1.5", "+1", " 1"]) {
        assertFails(program, "invalid value '" ~ value ~ "' for option '--port': expected an integer",
            "--port", value);
        assertFails(program, "invalid value '" ~ value ~ "' for option '-p': expected an integer", "-p", value);
        assertFails(program, "invalid value '" ~ value ~ "' for option '--port': expected an integer",
            "--port=" ~ value);
        assertFails(program, "invalid value '" ~ value ~ "' for option '-p': expected an integer", "-p=" ~ value);
    }
}

unittest {
    Program program = new TestProgram("app").option("-p, --port [number:int]", "Port");
    expect(parseOk(program, "-p", "1", "-p", "2").optionList("port")).to.equal(["1", "2"]);
    assertFails(program, "invalid value 'x' for option '--port': expected an integer", "-p", "1", "--port", "x");
}

unittest {
    Program program = new TestProgram("app").option("-f, --format <format:json|yaml>", "Format");
    expect(parseOk(program, "--format", "json").option("format")).to.equal("json");
    expect(parseOk(program, "-f", "yaml").option("format")).to.equal("yaml");
    assertFails(program, "invalid value 'xml' for option '--format': expected one of: json, yaml",
        "--format", "xml");
    assertFails(program, "invalid value 'JSON' for option '-f': expected one of: json, yaml", "-f", "JSON");
    assertFails(program, "invalid value '' for option '--format': expected one of: json, yaml", "--format=");
}

unittest {
    Program program = new TestProgram("app")
        .option("--config [path:file]", "Config")
        .option("--root [path:dir]", "Root")
        .option("--name [name:string]", "Name");
    auto parsed = parseOk(program, "--config", "/no/such/file", "--root", "", "--name", "-x");
    expect(parsed.option("config")).to.equal("/no/such/file");
    expect(parsed.option("root")).to.equal("");
    expect(parsed.option("name")).to.equal("-x");
}

unittest {
    Program program = new TestProgram("app").option("-p, --port <number:int>", "Port");
    expect(parseOk(program, "-p", "-5").option("port")).to.equal("-5");
}

unittest {
    Program program = new TestProgram("app").argument("<count:int>", "Count");
    expect(parseOk(program, "5").argument("count")).to.equal("5");
    assertFails(program, "invalid value 'x' for argument 'count': expected an integer", "x");
    assertFails(program, "invalid value '05' for argument 'count': expected an integer", "05");
    assertFails(program, "invalid value '' for argument 'count': expected an integer", "");
}

unittest {
    Program program = new TestProgram("app").argument("<format:json|yaml>", "Format");
    expect(parseOk(program, "yaml").argument("format")).to.equal("yaml");
    assertFails(program, "invalid value 'xml' for argument 'format': expected one of: json, yaml", "xml");
}

unittest {
    Program program = new TestProgram("app").argument("[ids:int...]", "Ids");
    expect(parseOk(program, "1", "2", "3").argumentList("ids")).to.equal(["1", "2", "3"]);
    assertFails(program, "invalid value 'x' for argument 'ids': expected an integer", "x");
    assertFails(program, "invalid value 'x' for argument 'ids': expected an integer", "1", "x");
    assertFails(program, "invalid value 'x' for argument 'ids': expected an integer", "1", "2", "x");
}

unittest {
    Program program = new TestProgram("app")
        .argument("<name>", "Name")
        .argument("[ids:int...]", "Ids");
    auto parsed = parseOk(program, "5", "1", "2");
    expect(parsed.argument("name")).to.equal("5");
    expect(parsed.argumentList("ids")).to.equal(["1", "2"]);
    assertFails(program, "invalid value 'x' for argument 'ids': expected an integer", "alice", "x");
    assertFails(program, "invalid value 'x' for argument 'ids': expected an integer", "alice", "1", "x");
}

unittest {
    auto sub = new TestCommand("sub").argument("<count:int>", "Count");
    Program program = new TestProgram("app").command(sub);
    expect(parseOk(program, "sub", "3").argument("count")).to.equal("3");
    assertFails(program, "invalid value 'x' for argument 'count': expected an integer", "sub", "x");
}

unittest {
    Program program = new TestProgram("app").option("-v, --verbose", "d").argument("<input>", "d");
    auto parsed = parseOk(program, "--", "-v");
    expect(parsed.argument("input")).to.equal("-v");
    expect(parsed.hasFlag("verbose")).to.equal(false);
}

unittest {
    Program program = new TestProgram("app").option("-v, --verbose", "d").argument("<input>", "d");
    auto parsed = parseOk(program, "-v", "--", "-x");
    expect(parsed.flag("verbose")).to.equal(1);
    expect(parsed.argument("input")).to.equal("-x");
}

unittest {
    Program program = new TestProgram("app").argument("<input>", "d");
    assertFails(program, "missing required argument 'input'", "--");
    expect(parseOk(program, "--", "x").argument("input")).to.equal("x");
    expect(parseOk(program, "x", "--").argument("input")).to.equal("x");
}

unittest {
    Program program = new TestProgram("app");
    expect(parseOk(program, "--").command is program).to.equal(true);
    assertFails(program, "unexpected argument 'x'", "--", "x");
}

unittest {
    Program program = new TestProgram("app").argument("[files...]", "d");
    expect(parseOk(program, "a", "--", "-b", "--c").argumentList("files")).to.equal(["a", "-b", "--c"]);
}

unittest {
    Program program = new TestProgram("app").argument("<input>", "d");
    expect(parseOk(program, "--", "--").argument("input")).to.equal("--");

    Program variadic = new TestProgram("app").argument("[files...]", "d");
    expect(parseOk(variadic, "a", "--", "--", "b").argumentList("files")).to.equal(["a", "--", "b"]);
}

unittest {
    Program program = new TestProgram("app")
        .option("--target <n>", "d")
        .argument("[rest...]", "d");
    auto parsed = parseOk(program, "--target", "x", "--", "--target", "y");
    expect(parsed.optionList("target")).to.equal(["x"]);
    expect(parsed.argumentList("rest")).to.equal(["--target", "y"]);
    assertFails(program, "missing required option '--target <n>'", "--", "a");
}

unittest {
    Program program = new TestProgram("app")
        .option("-v, --verbose", "d")
        .option("--target <n>", "d")
        .argument("[rest...]", "d");
    auto parsed = parseOk(program, "--target", "--", "-v");
    expect(parsed.option("target")).to.equal("--");
    expect(parsed.hasFlag("verbose")).to.equal(true);
    expect(parsed.hasArgument("rest")).to.equal(false);
}

unittest {
    Program program = new TestProgram("app")
        .helpOption("-h, --help", "d")
        .versionString("1.0.0")
        .versionOption("--version", "d")
        .argument("[rest...]", "d");
    expect(parseOk(program, "--", "--help").argumentList("rest")).to.equal(["--help"]);
    expect(parseOk(program, "--", "-h").argumentList("rest")).to.equal(["-h"]);
    expect(parseOk(program, "--", "--version").argumentList("rest")).to.equal(["--version"]);
}

unittest {
    auto sub = new TestCommand("sub").argument("<v>", "d");
    Program program = new TestProgram("app").command(sub);

    auto beforeName = parseOk(program, "--", "sub", "x");
    expect(beforeName.command is sub).to.equal(true);
    expect(beforeName.argument("v")).to.equal("x");

    expect(parseOk(program, "sub", "--", "-x").argument("v")).to.equal("-x");
    expect(parseOk(program, "--").command is program).to.equal(true);
    assertFails(program, "unknown command '-x'", "--", "-x");
}

unittest {
    Program program = new TestProgram("app")
        .helpOption("-h, --help", "d")
        .option("-c, --colour", "d")
        .option("--format <format>", "d");
    assertFails(program, "unknown option '--colur', did you mean '--colour'?", "--colur");
    assertFails(program, "unknown option '--colur', did you mean '--colour'?", "--colur=1");
    assertFails(program, "unknown option '--fromat', did you mean '--format'?", "--fromat", "x");
    assertFails(program, "unknown option '--hlp', did you mean '--help'?", "--hlp");
    assertFails(program, "unknown option '--zzzzzz'", "--zzzzzz");
    assertFails(program, "unknown option '-x'", "-x");
}

unittest {
    Program program = new TestProgram("app")
        .command(new TestCommand("serve"))
        .command(new TestCommand("build"));
    assertFails(program, "unknown command 'serv', did you mean 'serve'?", "serv");
    assertFails(program, "unknown command 'biuld', did you mean 'build'?", "biuld");
    assertFails(program, "unknown command 'deploy'", "deploy");
}
