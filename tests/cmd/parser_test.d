module cmd.parser_test;

import std.exception : collectException;

import cmd.program;
import cmd.test_support;

unittest {
    Program program = new TestProgram("app").option("-v, --verbose", "Verbose");

    auto absent = parseOk(program);
    assert(!absent.hasFlag("verbose"));
    assert(absent.flag("verbose") == 0);

    auto viaShort = parseOk(program, "-v");
    auto viaLong = parseOk(program, "--verbose");
    foreach (name; ["verbose", "v", "-v", "--verbose"]) {
        assert(viaShort.hasFlag(name));
        assert(viaShort.flag(name) == 1);
        assert(viaLong.hasFlag(name));
        assert(viaLong.flag(name) == 1);
    }
    assert(!viaShort.hasFlag("other"));
}

unittest {
    Program program = new TestProgram("app").option("-v, --verbose", "Verbose");
    assert(parseOk(program, "-v", "-v").flag("verbose") == 2);
    assert(parseOk(program, "-v", "--verbose", "-v").flag("verbose") == 3);
    assert(parseOk(program, "--verbose", "--verbose").flag("v") == 2);
    assert(parseOk(program, "-vvv").flag("verbose") == 3);
    assert(parseOk(program, "-vv", "-v").flag("verbose") == 3);
}

unittest {
    Program program = new TestProgram("app").option("--only-long", "d").option("-s", "d");
    auto parsed = parseOk(program, "--only-long", "-s", "-s");
    assert(parsed.hasFlag("only-long"));
    assert(parsed.hasFlag("--only-long"));
    assert(parsed.flag("only-long") == 1);
    assert(parsed.hasFlag("s"));
    assert(parsed.hasFlag("-s"));
    assert(parsed.flag("s") == 2);
}

unittest {
    Program program = new TestProgram("app")
        .option("-a, --all", "d")
        .option("-b, --brief", "d")
        .option("-c", "d");
    auto parsed = parseOk(program, "-abc");
    assert(parsed.flag("all") == 1);
    assert(parsed.flag("brief") == 1);
    assert(parsed.flag("c") == 1);

    auto counted = parseOk(program, "-aab", "-a", "-c");
    assert(counted.flag("all") == 3);
    assert(counted.flag("brief") == 1);
    assert(counted.flag("c") == 1);
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
    assertFails(program, "unknown option '--verbos'", "--verbos");
    assertFails(program, "unknown option '--verbose2'", "--verbose2");
}

unittest {
    Program program = new TestProgram("app").option("-t, --target <name>", "Target");
    foreach (args; [["--target", "x"], ["--target=x"], ["-t", "x"], ["-t=x"]]) {
        auto parsed = parseOk(program, args);
        foreach (name; ["target", "t", "-t", "--target"]) {
            assert(parsed.hasOption(name));
            assert(parsed.option(name) == "x");
            assert(parsed.optionList(name) == ["x"]);
        }
    }
}

unittest {
    Program program = new TestProgram("app").option("-t, --target <name>", "Target");
    auto parsed = parseOk(program, "--target", "a", "-t", "b", "--target=c", "-t=d");
    assert(parsed.option("target") == "a");
    assert(parsed.optionList("target") == ["a", "b", "c", "d"]);
    assert(parsed.optionList("t") == ["a", "b", "c", "d"]);
}

unittest {
    Program program = new TestProgram("app").option("-t, --target <name>", "Target");
    assert(parseOk(program, "--target=").option("target") == "");
    assert(parseOk(program, "-t=").option("target") == "");
    assert(parseOk(program, "--target", "").option("target") == "");
    assert(parseOk(program, "--target=a=b").option("target") == "a=b");
    assert(parseOk(program, "-t=a=b").option("target") == "a=b");
    assert(parseOk(program, "--target==x").option("target") == "=x");
}

unittest {
    Program program = new TestProgram("app")
        .option("-t, --target <name>", "Target")
        .option("-v, --verbose", "Verbose");
    assert(parseOk(program, "--target", "--verbose").option("target") == "--verbose");
    assert(!parseOk(program, "--target", "--verbose").hasFlag("verbose"));
    assert(parseOk(program, "-t", "-5").option("target") == "-5");
    assert(parseOk(program, "-t", "-v").option("t") == "-v");
}

unittest {
    Program program = new TestProgram("app").option("--target [name]", "Target").option("-o [file]", "Out");
    assert(parseOk(program, "--target", "x").option("target") == "x");
    assert(parseOk(program, "--target=x").option("--target") == "x");
    assert(parseOk(program, "-o", "f").option("o") == "f");
    assert(parseOk(program, "-o=f").option("-o") == "f");
    assert(parseOk(program, "-o", "f").hasOption("-o"));
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
    assert(parseOk(program, "--first", "1", "--second", "2").option("second") == "2");
}

unittest {
    Program program = new TestProgram("app")
        .option("-p, --port [number]", "Port", "8080")
        .option("-c, --config [file]", "Config");

    auto absent = parseOk(program);
    assert(absent.hasOption("port"));
    assert(absent.option("port") == "8080");
    assert(absent.option("p") == "8080");
    assert(absent.optionList("port") == ["8080"]);
    assert(!absent.hasOption("config"));
    assert(!absent.hasOption("c"));
    auto missing = collectException(absent.option("config"));
    assert(missing !is null);
    assert(missing.msg == "Option 'config' not found");
}

unittest {
    Program program = new TestProgram("app")
        .option("-p, --port [number]", "Port", "8080");
    auto overridden = parseOk(program, "-p", "9");
    assert(overridden.option("port") == "9");
    assert(overridden.optionList("port") == ["9"]);

    auto repeated = parseOk(program, "-p", "1", "--port=2");
    assert(repeated.optionList("port") == ["1", "2"]);
}

unittest {
    Program program = new TestProgram("app")
        .option("-c, --config [file]", "Config");
    auto parsed = parseOk(program, "--config", "x.toml");
    assert(parsed.hasOption("config"));
    assert(parsed.option("config") == "x.toml");
}

unittest {
    Program program = new TestProgram("app")
        .argument("<input>", "Input")
        .argument("[output]", "Output");

    auto both = parseOk(program, "in", "out");
    assert(both.hasArgument("input"));
    assert(both.hasArgument("output"));
    assert(both.argument("input") == "in");
    assert(both.argument("output") == "out");
    assert(both.argumentList("input") == ["in"]);

    auto onlyRequired = parseOk(program, "in");
    assert(onlyRequired.argument("input") == "in");
    assert(!onlyRequired.hasArgument("output"));
    auto missing = collectException(onlyRequired.argument("output"));
    assert(missing !is null);
    assert(missing.msg == "Argument 'output' not found");
}

unittest {
    Program program = new TestProgram("app").argument("<input>", "Input");
    assertFails(program, "missing required argument 'input'");
    assertFails(program, "unexpected argument 'b'", "a", "b");
}

unittest {
    Program program = new TestProgram("app");
    assertFails(program, "unexpected argument 'x'", "x");
    assert(parseOk(program).command is program);
}

unittest {
    Program program = new TestProgram("app")
        .argument("<a>", "d")
        .argument("<b>", "d");
    assertFails(program, "missing required argument 'b'", "x");
    assertFails(program, "missing required argument 'a'");
    auto parsed = parseOk(program, "x", "y");
    assert(parsed.argument("a") == "x");
    assert(parsed.argument("b") == "y");
}

unittest {
    Program program = new TestProgram("app")
        .argument("[output]", "Output", "out.txt");
    auto absent = parseOk(program);
    assert(absent.hasArgument("output"));
    assert(absent.argument("output") == "out.txt");
    assert(parseOk(program, "x.txt").argument("output") == "x.txt");
}

unittest {
    Program program = new TestProgram("app")
        .argument("[first]", "d")
        .argument("<second>", "d");
    assertFails(program, "missing required argument 'second'", "x");
    auto parsed = parseOk(program, "x", "y");
    assert(parsed.argument("first") == "x");
    assert(parsed.argument("second") == "y");
}

unittest {
    Program program = new TestProgram("app").argument("<files...>", "Files");
    auto many = parseOk(program, "a", "b", "c");
    assert(many.hasArgument("files"));
    assert(many.argument("files") == "a");
    assert(many.argumentList("files") == ["a", "b", "c"]);
    assert(parseOk(program, "a").argumentList("files") == ["a"]);
    assertFails(program, "missing required argument 'files'");
}

unittest {
    Program program = new TestProgram("app").argument("[files...]", "Files");
    auto many = parseOk(program, "a", "b");
    assert(many.argumentList("files") == ["a", "b"]);
    auto none = parseOk(program);
    assert(!none.hasArgument("files"));
    auto missing = collectException(none.argumentList("files"));
    assert(missing !is null);
    assert(missing.msg == "Argument 'files' not found");
}

unittest {
    Program program = new TestProgram("app").argument("[files...]", "Files", "default.txt");
    assert(parseOk(program).argumentList("files") == ["default.txt"]);
    assert(parseOk(program).argument("files") == "default.txt");
    assert(parseOk(program, "a", "b").argumentList("files") == ["a", "b"]);
}

unittest {
    Program program = new TestProgram("app")
        .argument("<command>", "d")
        .argument("[rest...]", "d");
    auto parsed = parseOk(program, "run", "a", "b", "c");
    assert(parsed.argument("command") == "run");
    assert(parsed.argumentList("rest") == ["a", "b", "c"]);
    assert(parsed.argumentList("command") == ["run"]);

    auto single = parseOk(program, "run");
    assert(single.argument("command") == "run");
    assert(!single.hasArgument("rest"));

    assertFails(program, "missing required argument 'command'");
}

unittest {
    Program program = new TestProgram("app")
        .option("-v, --verbose", "d")
        .option("-t, --target <n>", "d")
        .argument("<input>", "d")
        .argument("[files...]", "d");
    auto parsed = parseOk(program, "a", "-v", "b", "--target", "x", "c", "-t=y", "d");
    assert(parsed.hasFlag("verbose"));
    assert(parsed.optionList("target") == ["x", "y"]);
    assert(parsed.argument("input") == "a");
    assert(parsed.argumentList("files") == ["b", "c", "d"]);
}

unittest {
    Program program = new TestProgram("app").argument("<value>", "d");
    auto parsed = parseOk(program, "");
    assert(parsed.hasArgument("value"));
    assert(parsed.argument("value") == "");
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
    assert(parsed.command is program);
    assert(parsed.program is program);
}

unittest {
    auto sub = new TestCommand("sub")
        .option("--flag", "d")
        .argument("<x>", "d");
    Program program = new TestProgram("app").command(sub);

    auto parsed = parseOk(program, "sub", "val", "--flag");
    assert(parsed.command is sub);
    assert(parsed.program is program);
    assert(parsed.hasFlag("flag"));
    assert(parsed.argument("x") == "val");
}

unittest {
    auto sub = new TestCommand("sub")
        .option("--flag", "d")
        .argument("<x>", "d");
    Program program = new TestProgram("app").command(sub);

    auto parsed = parseOk(program, "--flag", "sub", "val");
    assert(parsed.command is sub);
    assert(parsed.hasFlag("flag"));
    assert(parsed.argument("x") == "val");
}

unittest {
    auto sub = new TestCommand("sub").argument("<x>", "d");
    Program program = new TestProgram("app").command(sub);
    assertFails(program, "unknown command 'nope'", "nope");
    assertFails(program, "unknown command 'nope'", "--flag", "nope");
    assertFails(program, "unknown command 'sub2'", "sub2", "x");
    assertFails(program, "missing required argument 'x'", "sub");
    assertFails(program, "unexpected argument 'b'", "sub", "a", "b");
}

unittest {
    auto sub = new TestCommand("sub");
    Program program = new TestProgram("app").command(sub);
    assertFails(program, "unknown option '--flag'", "--flag");
    assertFails(program, "unknown option '--flag'", "sub", "--flag");
    assert(parseOk(program).command is program);
}

unittest {
    auto first = new TestCommand("first").argument("<x>", "d");
    auto second = new TestCommand("second").option("--flag", "d");
    Program program = new TestProgram("app").command(first).command(second);

    auto viaFirst = parseOk(program, "first", "v");
    assert(viaFirst.command is first);
    assert(viaFirst.argument("x") == "v");

    auto viaSecond = parseOk(program, "second", "--flag");
    assert(viaSecond.command is second);
    assert(viaSecond.hasFlag("flag"));
    assert(!viaSecond.hasArgument("x"));
}

unittest {
    Program program = new TestProgram("app");
    auto mid = new TestCommand("mid");
    program.add(mid);
    auto leaf = new TestCommand("leaf").argument("<v>", "d");
    mid.add(leaf);

    auto parsed = parseOk(program, "mid", "leaf", "x");
    assert(parsed.command is leaf);
    assert(parsed.argument("v") == "x");
    assert(parseOk(program, "mid").command is mid);
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
    assert(parsed.command is leaf);
    assert(parsed.hasFlag("leaf-flag"));
    assertFails(program, "unknown option '--deep'", "mid", "leaf", "--deep");
}
