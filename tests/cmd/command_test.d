module cmd.command_test;

import core.exception : AssertError;

import fluent.asserts;

import cmd.argument;
import cmd.command;
import cmd.flag;
import cmd.option;
import cmd.parsed_args;
import cmd.program;
import cmd.test_support;

unittest {
    expect({ new Command(""); }).to.throwException!AssertError;
    expect({ new Program(""); }).to.throwException!AssertError;
}

unittest {
    auto program = new Program("app");
    expect(program.chain.length).to.equal(1);
    expect(program.chain[0] is program).to.equal(true);
}

unittest {
    auto program = new Program("app");
    auto child = new Command("child");
    expect(child.chain).to.beNull;
    expect(program.add(child) is program).to.equal(true);
    expect(child.chain.length).to.equal(2);
    expect(child.chain[0] is program).to.equal(true);
    expect(child.chain[1] is child).to.equal(true);
}

unittest {
    auto program = new Program("app");
    auto child = new Command("child");
    expect(program.command(child) is program).to.equal(true);
    expect(child.chain.length).to.equal(2);
}

unittest {
    auto program = new Program("app");
    auto a = new Command("a");
    program.add(a);
    auto b = new Command("b");
    a.add(b);
    auto c = new Command("c");
    b.add(c);
    expect(b.chain.length).to.equal(3);
    expect(b.chain[0] is program).to.equal(true);
    expect(b.chain[1] is a).to.equal(true);
    expect(b.chain[2] is b).to.equal(true);
    expect(c.chain.length).to.equal(4);
    expect(c.chain[3] is c).to.equal(true);
}

unittest {
    auto program = new Program("app");
    auto child = new Command("child");
    program.add(child);
    expect({ program.add(child); }).to.throwException!AssertError;
    expect({ program.add(new Command("child")); }).to.throwException!AssertError;
    expect({ program.add(new Command("other")); }).to.not.throwException!AssertError;
}

unittest {
    auto other = new Program("other");
    auto child = new Command("child");
    other.add(child);
    auto program = new Program("app");
    expect({ program.add(child); }).to.throwException!AssertError;
}

unittest {
    auto command = new Command("c").argument("<a>", "d");
    expect({ command.add(new Command("sub")); }).to.throwException!AssertError;

    auto holder = new Command("h");
    holder.add(new Command("sub"));
    expect({ holder.argument("<a>", "d"); }).to.throwException!AssertError;
    expect({ holder.add(Argument.fromString("<a>", "d")); }).to.throwException!AssertError;
}

unittest {
    auto command = new Command("c").argument("<a>", "d");
    expect({ command.argument("<a>", "d"); }).to.throwException!AssertError;
    expect({ command.argument("[a]", "d"); }).to.throwException!AssertError;
    expect({ command.argument("<b>", "d"); }).to.not.throwException!AssertError;
}

unittest {
    auto command = new Command("c");
    expect({ command.argument("a", "d"); }).to.throwException!AssertError;
    expect({ command.argument("<a", "d"); }).to.throwException!AssertError;
    expect({ command.argument("<a>", "d", "x"); }).to.throwException!AssertError;
}

unittest {
    auto command = new Command("c").option("-t, --target <n>", "d");
    expect({ command.option("-t, --other <n>", "d"); }).to.throwException!AssertError;
    expect({ command.option("-x, --target <n>", "d"); }).to.throwException!AssertError;
    expect({ command.option("-t, --target <n>", "d"); }).to.throwException!AssertError;
    expect({ command.option("-x, --other <n>", "d"); }).to.not.throwException!AssertError;
}

unittest {
    auto command = new Command("c").option("--target <n>", "d");
    expect({ command.option("--target [n]", "d"); }).to.throwException!AssertError;
    expect({ command.option("--other <n>", "d"); }).to.not.throwException!AssertError;
    expect({ command.option("--another <n>", "d"); }).to.not.throwException!AssertError;
}

unittest {
    auto command = new Command("c").option("-v, --verbose", "d");
    expect({ command.option("-v, --other", "d"); }).to.throwException!AssertError;
    expect({ command.option("-x, --verbose", "d"); }).to.throwException!AssertError;
    expect({ command.option("-v, --verbose", "d"); }).to.throwException!AssertError;
    expect({ command.option("-x, --other", "d"); }).to.not.throwException!AssertError;
}

unittest {
    auto command = new Command("c").option("--verbose", "d");
    expect({ command.option("--verbose", "d"); }).to.throwException!AssertError;
}

unittest {
    auto command = new Command("c");
    expect({ command.option("-t, --target <n>", "d", "x"); }).to.throwException!AssertError;
}

unittest {
    auto program = new Program("app");
    auto a = new Command("a");
    program.add(a);
    auto b = new Command("b");
    a.add(b);
    auto c = new Command("c");
    b.add(c);

    expect(program.findCommand("a") is a).to.equal(true);
    expect(program.findCommand("b") is null).to.equal(true);
    expect(program.findCommand("c") is null).to.equal(true);
    expect(program.findCommand("app") is null).to.equal(true);
    expect(program.findCommand("missing") is null).to.equal(true);
    expect(a.findCommand("b") is b).to.equal(true);
    expect(a.findCommand("c") is null).to.equal(true);
    expect(c.findCommand("a") is null).to.equal(true);
}

unittest {
    auto program = new Program("app");
    auto a = new Command("a");
    program.add(a);
    auto b = new Command("b");
    a.add(b);
    auto c = new Command("c");
    b.add(c);

    expect(program.findCommand("app", program) is program).to.equal(true);
    expect(program.findCommand("a", program) is a).to.equal(true);
    expect(program.findCommand("b", program) is b).to.equal(true);
    expect(program.findCommand("c", program) is c).to.equal(true);
    expect(program.findCommand("missing", program) is null).to.equal(true);
    expect(a.findCommand("a", a) is a).to.equal(true);
    expect(a.findCommand("c", a) is c).to.equal(true);
    expect(a.findCommand("app", a) is null).to.equal(true);
    expect(a.findCommand("b", program) is b).to.equal(true);
}

unittest {
    auto program = new Program("app");
    auto first = new Command("first");
    auto second = new Command("second");
    program.add(first);
    program.add(second);
    expect(program.findCommand("first") is first).to.equal(true);
    expect(program.findCommand("second") is second).to.equal(true);
}

unittest {
    auto command = new Command("c");
    expect(captureStderr({ command.error("something broke"); })).to.equal("error: something broke\n");
}

unittest {
    auto command = new Command("c");
    expect(captureStderr({ command.error(""); })).to.equal("error: \n");
    expect(captureStderr({ command.error("a"); command.error("b"); })).to.equal("error: a\nerror: b\n");
}

unittest {
    auto orphan = new Command("orphan");
    expect({ orphan.usage(); }).to.throwException!AssertError;
    expect({ orphan.usage(true); }).to.throwException!AssertError;
    expect({ orphan.printHelp(); }).to.throwException!AssertError;
}

unittest {
    auto root = new Command("root");
    auto child = new Command("child");
    root.add(child);
    expect({ child.usage(); }).to.throwException!AssertError;
    expect({ root.usage(); }).to.throwException!AssertError;
    expect({ child.printHelp(); }).to.throwException!AssertError;
}

unittest {
    int seen = 0;
    Program program = new TestProgram("app")
        .option("-n, --number <n>", "Number")
        .action((args) {
            seen = 5;
            return 11;
        });
    expect(runArgs(program, "--number", "1")).to.equal(11);
    expect(seen).to.equal(5);
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
    expect(runArgs(program, "echo", "hi")).to.equal(3);
    expect(received).to.equal("hi");
    expect(commandName).to.equal("echo");
    expect(runArgs(program)).to.equal(99);
}

unittest {
    Program program = new TestProgram("app");
    program.command(new TestCommand("sub"));
    auto expected = helpOf(program);
    int status = -1;
    auto output = captureStdout({ status = runArgs(program); });
    expect(status).to.equal(0);
    expect(output).to.equal(expected);
}

unittest {
    auto sub = new TestCommand("sub").description("Sub command");
    Program program = new TestProgram("app");
    program.command(sub);
    auto expected = helpOf(sub);
    int status = -1;
    auto output = captureStdout({ status = runArgs(program, "sub"); });
    expect(status).to.equal(0);
    expect(output).to.equal(expected);
}

unittest {
    Program program = new TestProgram("app").action((args) => 4);
    expect(runArgs(program)).to.equal(4);
    expect(runArgs(program)).to.equal(4);
}

unittest {
    Program program = new TestProgram("app")
        .argument("<value>", "Value")
        .action((args) => args.argument("value") == "ok" ? 0 : 1);
    expect(runArgs(program, "ok")).to.equal(0);
    expect(runArgs(program, "nope")).to.equal(1);
}

unittest {
    Program program = new TestProgram("app").argument("<value>", "Value");
    auto failure = collectCliExit({ runArgs(program); });
    expect(failure).to.not.beNull;
    expect(failure.status).to.equal(2);
    expect(failure.msg).to.equal("missing required argument 'value'");
}

unittest {
    auto command = new TestCommand("deploy")
        .option("-r, --registry <name>", "Registry", (prefix) => ["npm"])
        .option("-t, --tag [tag]", "Tag", "latest", (prefix) => ["latest", "next"])
        .argument("<package>", "Package", (prefix) => ["alpha"])
        .argument("[version]", "Version", "1.0", (prefix) => ["1.0", "2.0"]);
    expect(command.options.length).to.equal(2);
    expect(command.options[0].complete("")).to.equal(["npm"]);
    expect(command.options[1].defaultValue).to.equal("latest");
    expect(command.options[1].complete("")).to.equal(["latest", "next"]);
    expect(command.arguments.length).to.equal(2);
    expect(command.arguments[0].complete("")).to.equal(["alpha"]);
    expect(command.arguments[1].defaultValue).to.equal("1.0");
    expect(command.arguments[1].complete("")).to.equal(["1.0", "2.0"]);
}

unittest {
    Program program = new TestProgram("app")
        .option("-r, --registry <name>", "Registry", (prefix) => ["npm"])
        .option("-t, --tag [tag]", "Tag", "latest", (prefix) => ["next"])
        .argument("<package>", "Package", (prefix) => ["alpha"])
        .argument("[version]", "Version", "1.0", (prefix) => ["2.0"]);
    expect(program.options.length).to.equal(2);
    expect(program.options[0].complete("")).to.equal(["npm"]);
    expect(program.options[1].defaultValue).to.equal("latest");
    expect(program.arguments[0].complete("")).to.equal(["alpha"]);
    expect(program.arguments[1].defaultValue).to.equal("1.0");
}
