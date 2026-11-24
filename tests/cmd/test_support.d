module cmd.test_support;

import std.conv : to;
import std.exception : collectException;
import std.file : readText, remove, tempDir;
import std.path : buildPath;
import std.process : thisProcessID;
import std.stdio : File, stderr, stdout;

import core.sys.posix.unistd : close, dup, dup2;

import cmd.command;
import cmd.help_command;
import cmd.parsed_args;
import cmd.program;

class CliExit : Exception {
    public int status;

    public this(int status, string msg) {
        super(msg);
        this.status = status;
    }
}

class TestProgram : Program {
    public this(string name) {
        super(name);
    }

    public override noreturn error(string description, int status) const {
        throw new CliExit(status, description);
    }
}

class TestCommand : Command {
    public this(string name) {
        super(name);
    }

    public override noreturn error(string description, int status) const {
        throw new CliExit(status, description);
    }
}

class TestHelpCommand : HelpCommand {
    public this(string description = "Show help for command") {
        super(description);
    }

    public override noreturn error(string description, int status) const {
        throw new CliExit(status, description);
    }
}

string sp(size_t count) {
    string result;
    foreach (_; 0 .. count)
        result ~= ' ';
    return result;
}

CliExit parseFails(const Program program, string[] args...) {
    return collectException!CliExit(program.parse(["prog"] ~ args));
}

ParsedArgs parseOk(const Program program, string[] args...) {
    return program.parse(["prog"] ~ args);
}

void assertFails(const Program program, string message, string[] args...) {
    auto failure = parseFails(program, args);
    assert(failure !is null, "expected failure: " ~ message);
    assert(failure.status == 2);
    assert(failure.msg == message);
}

CliExit collectCliExit(scope void delegate() action) {
    return collectException!CliExit(action());
}

int runArgs(Program program, string[] args...) {
    Command command = program;
    return command.run(args, program);
}

string capture(int fd, scope void delegate() action) {
    stdout.flush();
    stderr.flush();
    auto path = buildPath(tempDir(), "cmd-test-" ~ thisProcessID.to!string ~ "-" ~ fd.to!string);
    const saved = dup(fd);
    auto sink = File(path, "wb");
    dup2(sink.fileno, fd);
    try {
        action();
    } finally {
        stdout.flush();
        stderr.flush();
        dup2(saved, fd);
        close(saved);
        sink.close();
    }
    auto text = readText(path);
    remove(path);
    return text;
}

string captureStdout(scope void delegate() action) {
    return capture(1, action);
}

string captureStderr(scope void delegate() action) {
    return capture(2, action);
}

string helpOf(const Command command) {
    return captureStdout({ command.printHelp(); });
}
