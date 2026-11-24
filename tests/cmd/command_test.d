module cmd.command_test;

import core.exception : AssertError;
import std.exception : assertNotThrown, assertThrown;

import cmd.argument;
import cmd.command;
import cmd.flag;
import cmd.option;
import cmd.parsed_args;
import cmd.program;
import cmd.test_support;

unittest {
    assertThrown!AssertError(new Command(""));
    assertThrown!AssertError(new Program(""));
}

unittest {
    auto program = new Program("app");
    assert(program.chain.length == 1);
    assert(program.chain[0] is program);
}

unittest {
    auto program = new Program("app");
    auto child = new Command("child");
    assert(child.chain is null);
    assert(program.add(child) is program);
    assert(child.chain.length == 2);
    assert(child.chain[0] is program);
    assert(child.chain[1] is child);
}

unittest {
    auto program = new Program("app");
    auto child = new Command("child");
    assert(program.command(child) is program);
    assert(child.chain.length == 2);
}

unittest {
    auto program = new Program("app");
    auto a = new Command("a");
    program.add(a);
    auto b = new Command("b");
    a.add(b);
    auto c = new Command("c");
    b.add(c);
    assert(b.chain.length == 3);
    assert(b.chain[0] is program);
    assert(b.chain[1] is a);
    assert(b.chain[2] is b);
    assert(c.chain.length == 4);
    assert(c.chain[3] is c);
}

unittest {
    auto program = new Program("app");
    auto child = new Command("child");
    program.add(child);
    assertThrown!AssertError(program.add(child));
    assertThrown!AssertError(program.add(new Command("child")));
    assertNotThrown!AssertError(program.add(new Command("other")));
}

unittest {
    auto other = new Program("other");
    auto child = new Command("child");
    other.add(child);
    auto program = new Program("app");
    assertThrown!AssertError(program.add(child));
}

unittest {
    auto command = new Command("c").argument("<a>", "d");
    assertThrown!AssertError(command.add(new Command("sub")));

    auto holder = new Command("h");
    holder.add(new Command("sub"));
    assertThrown!AssertError(holder.argument("<a>", "d"));
    assertThrown!AssertError(holder.add(Argument.fromString("<a>", "d")));
}

unittest {
    auto command = new Command("c").argument("<a>", "d");
    assertThrown!AssertError(command.argument("<a>", "d"));
    assertThrown!AssertError(command.argument("[a]", "d"));
    assertNotThrown!AssertError(command.argument("<b>", "d"));
}

unittest {
    auto command = new Command("c");
    assertThrown!AssertError(command.argument("a", "d"));
    assertThrown!AssertError(command.argument("<a", "d"));
    assertThrown!AssertError(command.argument("<a>", "d", "x"));
}

unittest {
    auto command = new Command("c").option("-t, --target <n>", "d");
    assertThrown!AssertError(command.option("-t, --other <n>", "d"));
    assertThrown!AssertError(command.option("-x, --target <n>", "d"));
    assertThrown!AssertError(command.option("-t, --target <n>", "d"));
    assertNotThrown!AssertError(command.option("-x, --other <n>", "d"));
}

unittest {
    auto command = new Command("c").option("--target <n>", "d");
    assertThrown!AssertError(command.option("--target [n]", "d"));
    assertNotThrown!AssertError(command.option("--other <n>", "d"));
    assertNotThrown!AssertError(command.option("--another <n>", "d"));
}

unittest {
    auto command = new Command("c").option("-v, --verbose", "d");
    assertThrown!AssertError(command.option("-v, --other", "d"));
    assertThrown!AssertError(command.option("-x, --verbose", "d"));
    assertThrown!AssertError(command.option("-v, --verbose", "d"));
    assertNotThrown!AssertError(command.option("-x, --other", "d"));
}

unittest {
    auto command = new Command("c").option("--verbose", "d");
    assertThrown!AssertError(command.option("--verbose", "d"));
}

unittest {
    auto command = new Command("c");
    assertThrown!AssertError(command.option("-t, --target <n>", "d", "x"));
}

unittest {
    auto program = new Program("app");
    auto a = new Command("a");
    program.add(a);
    auto b = new Command("b");
    a.add(b);
    auto c = new Command("c");
    b.add(c);

    assert(program.findCommand("a") is a);
    assert(program.findCommand("b") is null);
    assert(program.findCommand("c") is null);
    assert(program.findCommand("app") is null);
    assert(program.findCommand("missing") is null);
    assert(a.findCommand("b") is b);
    assert(a.findCommand("c") is null);
    assert(c.findCommand("a") is null);
}

unittest {
    auto program = new Program("app");
    auto a = new Command("a");
    program.add(a);
    auto b = new Command("b");
    a.add(b);
    auto c = new Command("c");
    b.add(c);

    assert(program.findCommand("app", program) is program);
    assert(program.findCommand("a", program) is a);
    assert(program.findCommand("b", program) is b);
    assert(program.findCommand("c", program) is c);
    assert(program.findCommand("missing", program) is null);
    assert(a.findCommand("a", a) is a);
    assert(a.findCommand("c", a) is c);
    assert(a.findCommand("app", a) is null);
    assert(a.findCommand("b", program) is b);
}

unittest {
    auto program = new Program("app");
    auto first = new Command("first");
    auto second = new Command("second");
    program.add(first);
    program.add(second);
    assert(program.findCommand("first") is first);
    assert(program.findCommand("second") is second);
}

unittest {
    auto command = new Command("c");
    assert(captureStderr({ command.error("something broke"); }) == "error: something broke\n");
}

unittest {
    auto command = new Command("c");
    assert(captureStderr({ command.error(""); }) == "error: \n");
    assert(captureStderr({ command.error("a"); command.error("b"); }) == "error: a\nerror: b\n");
}

unittest {
    auto orphan = new Command("orphan");
    assertThrown!AssertError(orphan.usage());
    assertThrown!AssertError(orphan.usage(true));
    assertThrown!AssertError(orphan.printHelp());
}

unittest {
    auto root = new Command("root");
    auto child = new Command("child");
    root.add(child);
    assertThrown!AssertError(child.usage());
    assertThrown!AssertError(root.usage());
    assertThrown!AssertError(child.printHelp());
}

unittest {
    int seen = 0;
    Program program = new TestProgram("app")
        .option("-n, --number <n>", "Number")
        .action((args) {
            seen = 5;
            return 11;
        });
    assert(runArgs(program, "--number", "1") == 11);
    assert(seen == 5);
}

unittest {
    string received;
    string commandName;
    auto sub = new TestCommand("echo")
        .argument("<text>", "Text")
        .action((args) {
            received = args.argument("text");
            commandName = args.command.name();
            return 3;
        });
    Program program = new TestProgram("app")
        .command(sub)
        .action((args) => 99);
    assert(runArgs(program, "echo", "hi") == 3);
    assert(received == "hi");
    assert(commandName == "echo");
    assert(runArgs(program) == 99);
}

unittest {
    Program program = new TestProgram("app");
    program.command(new TestCommand("sub"));
    auto expected = helpOf(program);
    int status = -1;
    auto output = captureStdout({ status = runArgs(program); });
    assert(status == 0);
    assert(output == expected);
}

unittest {
    auto sub = new TestCommand("sub").description("Sub command");
    Program program = new TestProgram("app");
    program.command(sub);
    auto expected = helpOf(sub);
    int status = -1;
    auto output = captureStdout({ status = runArgs(program, "sub"); });
    assert(status == 0);
    assert(output == expected);
}

unittest {
    Program program = new TestProgram("app").action((args) => 4);
    assert(runArgs(program) == 4);
    assert(runArgs(program) == 4);
}

unittest {
    Program program = new TestProgram("app")
        .argument("<value>", "Value")
        .action((args) => args.argument("value") == "ok" ? 0 : 1);
    assert(runArgs(program, "ok") == 0);
    assert(runArgs(program, "nope") == 1);
}

unittest {
    Program program = new TestProgram("app").argument("<value>", "Value");
    auto failure = collectCliExit({ runArgs(program); });
    assert(failure !is null);
    assert(failure.status == 2);
    assert(failure.msg == "missing required argument 'value'");
}
