module cmd.completion_command_test;

import std.algorithm : canFind;
import std.array : join;
import std.process : environment;

import fluent.asserts;

import cmd.completion_command;
import cmd.program;
import cmd.test_support;

class TestCompletionCommand : CompletionCommand {
    public override noreturn error(string description, int status) const {
        throw new CliExit(status, description);
    }
}

Program completionHost() {
    return new TestProgram("app").command(new TestCompletionCommand());
}

string[] shellNames() {
    return new CompletionCommand().arguments[0].valueType.choices.dup;
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
    expect(command.description()).to.equal("Generate shell completion script");
    expect(new CompletionCommand("Custom").description()).to.equal("Custom");
}

unittest {
    auto command = new CompletionCommand();
    expect(command.arguments.length).to.equal(1);
    expect(command.arguments[0].name).to.equal("shell");
    expect(command.arguments[0].required).to.equal(false);
    expect(shellNames().length > 0).to.equal(true);
}

unittest {
    bool[string] seen;
    foreach (shell; shellNames()) {
        auto script = completionOutput("completion", shell);
        expect(script.length > 0).to.equal(true).because(shell);
        expect(script.canFind("app")).to.equal(true).because(shell);
        expect((script in seen) is null).to.equal(true).because(shell);
        seen[script] = true;
    }
}

unittest {
    foreach (shell; shellNames())
        withShell("/usr/bin/" ~ shell, {
            expect(completionOutput("completion")).to.equal(completionOutput("completion", shell)).because(shell);
        });
}

unittest {
    const shells = shellNames();
    withShell("/usr/bin/" ~ shells[0], {
        expect(completionOutput("completion", shells[$ - 1])).to.not.equal(completionOutput("completion"));
    });
}

unittest {
    const message = "invalid value 'tcsh' for argument 'shell': expected one of: " ~ shellNames().join(", ");
    assertFails(completionHost(), message, "completion", "tcsh");
}

unittest {
    const message = "cannot detect the login shell, specify one of: " ~ shellNames().join(", ");
    foreach (value; [null, "", "/bin/tcsh"]) {
        withShell(value, {
            auto program = completionHost();
            auto failure = collectCliExit({ runArgs(program, "completion"); });
            expect(failure).to.not.beNull;
            expect(failure.status).to.equal(2);
            expect(failure.msg).to.equal(message);
        });
    }
}
