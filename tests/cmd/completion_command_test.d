module cmd.completion_command_test;

import std.algorithm : canFind;
import std.array : join;
import std.process : environment;

import fluent.asserts;

import cmd.argument;
import cmd.completion_command;
import cmd.option;
import cmd.program;
import cmd.test_support;

class TestCompletionCommand : CompletionCommand {
    mixin ThrowOnError;
}

Program completionHost() {
    return new TestProgram("app")
        .command(new TestCommand("install")
            .add(Option.fromString("-r, --registry <name>", "Registry").completer((prefix) => ["npm", "github"]))
            .add(Option.fromString("--tag <tag>", "Tag"))
            .option("--echo <value>", "Echo", (prefix) => [prefix ~ "!"])
            .argument("<package>", "Package", (prefix) => ["alpha", "beta"])
            .add(Argument.fromString("[extra]", "Extra")))
        .command(new TestCommand("remote")
            .command(new TestCommand("rm").add(Argument.fromString("<name>", "Name").completer((prefix) => ["origin"]))))
        .command(new TestCommand("broken")
            .add(Argument.fromString("<name>", "Name").completer(delegate string[](string prefix) { throw new Exception("boom"); })))
        .command(new TestCompletionCommand());
}

string[] shellNames() {
    return new CompletionCommand().subcommands[0].arguments[0].valueType.choices.dup;
}

string completionOutput(string[] args...) {
    auto program = completionHost();
    return captureStdout({ runArgs(program, args); });
}

void withShell(string value, scope void delegate() action) {
    const previous = environment.get("SHELL");
    scope (exit) {
        if (previous is null)
            environment.remove("SHELL");
        else
            environment["SHELL"] = previous;
    }
    if (value is null)
        environment.remove("SHELL");
    else
        environment["SHELL"] = value;
    action();
}

unittest {
    auto command = new CompletionCommand();
    expect(command.name()).to.equal("completion");
    expect(command.description()).to.equal("Shell completion");
    expect(new CompletionCommand("Custom").description()).to.equal("Custom");
}

unittest {
    auto command = new CompletionCommand();
    expect(command.subcommands.length).to.equal(2);
    expect(command.subcommands[0].name()).to.equal("generate");
    expect(command.subcommands[1].name()).to.equal("suggest");
}

unittest {
    auto generate = new CompletionCommand().subcommands[0];
    expect(generate.arguments.length).to.equal(1);
    expect(generate.arguments[0].name).to.equal("shell");
    expect(generate.arguments[0].required).to.equal(false);
    expect(shellNames().length > 0).to.equal(true);
}

unittest {
    auto suggest = new CompletionCommand().subcommands[1];
    expect(suggest.arguments.length).to.equal(2);
    expect(suggest.arguments[0].name).to.equal("parameter");
    expect(suggest.arguments[0].required).to.equal(true);
    expect(suggest.arguments[1].name).to.equal("prefix");
    expect(suggest.arguments[1].required).to.equal(false);
}

unittest {
    bool[string] seen;
    foreach (shell; shellNames()) {
        auto script = completionOutput("completion", "generate", shell);
        expect(script.length > 0).to.equal(true).because(shell);
        expect(script.canFind("app")).to.equal(true).because(shell);
        expect((script in seen) is null).to.equal(true).because(shell);
        seen[script] = true;
    }
}

unittest {
    foreach (shell; shellNames())
        withShell("/usr/bin/" ~ shell, {
            expect(completionOutput("completion", "generate")).to.equal(completionOutput("completion", "generate", shell))
                .because(shell);
        });
}

unittest {
    const shells = shellNames();
    withShell("/usr/bin/" ~ shells[0], {
        expect(completionOutput("completion", "generate", shells[$ - 1]))
            .to.not.equal(completionOutput("completion", "generate"));
    });
}

unittest {
    const message = "cannot detect the login shell, specify one of: " ~ shellNames().join(", ");
    foreach (value; [null, "", "/bin/tcsh"]) {
        withShell(value, {
            auto program = completionHost();
            auto failure = collectCliExit({ runArgs(program, "completion", "generate"); });
            expect(failure).to.not.beNull;
            expect(failure.status).to.equal(2);
            expect(failure.msg).to.equal(message);
        });
    }
}

unittest {
    expect(completionOutput("completion", "suggest", "install:--registry")).to.equal("npm\ngithub\n");
    expect(completionOutput("completion", "suggest", "install:-r")).to.equal("npm\ngithub\n");
    expect(completionOutput("completion", "suggest", "install:0")).to.equal("alpha\nbeta\n");
    expect(completionOutput("completion", "suggest", "remote rm:0")).to.equal("origin\n");
}

unittest {
    expect(completionOutput("completion", "suggest", "install:--echo")).to.equal("!\n");
    expect(completionOutput("completion", "suggest", "--", "install:--echo", "hel")).to.equal("hel!\n");
    expect(completionOutput("completion", "suggest", "--", "install:--echo", "")).to.equal("!\n");
    expect(completionOutput("completion", "suggest", "--", "install:--echo", "-x")).to.equal("-x!\n");
}

unittest {
    expect(completionOutput("completion", "suggest", "broken:0")).to.equal("");
}

unittest {
    foreach (parameter; ["install:--tag", "install:-t", "install:1", "install:2", "install:name", "install:-1"]) {
        auto program = completionHost();
        auto failure = collectCliExit({ runArgs(program, "completion", "suggest", parameter); });
        expect(failure).to.not.beNull.because(parameter);
        expect(failure.status).to.equal(2);
        expect(failure.msg).to.equal("no suggestions for parameter '" ~ parameter ~ "'");
    }
}

unittest {
    auto program = completionHost();
    auto failure = collectCliExit({ runArgs(program, "completion", "suggest", "nosuch:0"); });
    expect(failure).to.not.beNull;
    expect(failure.status).to.equal(2);
    expect(failure.msg).to.equal("unknown command 'nosuch' in parameter 'nosuch:0'");
}

unittest {
    auto program = completionHost();
    auto failure = collectCliExit({ runArgs(program, "completion", "suggest", "invalid"); });
    expect(failure).to.not.beNull;
    expect(failure.status).to.equal(2);
    expect(failure.msg).to.equal("invalid parameter 'invalid': expected command path and name separated by ':'");
}
