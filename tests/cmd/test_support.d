module cmd.test_support;

import std.conv : to;
import std.exception : collectException;
import std.file : readText, remove, tempDir;
import std.path : buildPath;
import std.process : thisProcessID;
import std.stdio : File, stderr, stdout;

import core.sys.posix.unistd : close, dup, dup2;

import fluent.asserts;

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

mixin template ThrowOnError() {
    public override noreturn error(string description, int status) const {
        throw new CliExit(status, description);
    }
}

class TestProgram : Program {
    public this(string name) {
        super(name);
    }

    mixin ThrowOnError;
}

class TestCommand : Command {
    public this(string name) {
        super(name);
    }

    mixin ThrowOnError;
}

class TestHelpCommand : HelpCommand {
    public this(string description = "Show help for command") {
        super(description);
    }

    mixin ThrowOnError;
}

string sp(size_t count) {
    string result;
    foreach (_; 0 .. count)
        result ~= ' ';
    return result;
}

ParsedArgs parseOk(const Program program, string[] args...) {
    return program.parse(["prog"] ~ args);
}

void assertFails(string file = __FILE__, size_t line = __LINE__)(const Program program, string message, string[] args...) {
    auto failure = cast(CliExit) expect({ program.parse(["prog"] ~ args); }, file, line)
        .to.throwException!CliExit.thrown;
    expect(failure.status, file, line).to.equal(2);
    expect(failure.msg, file, line).to.equal(message);
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

Program completionProgram() {
    return new TestProgram("my-app")
        .versionString("1.0")
        .versionOption("--version", "Show version")
        .helpOption("-h, --help", "Show help")
        .option("-q, --quiet", "Quiet")
        .command(new TestCommand("serve")
            .description("Serve files, it's 'quoted'")
            .option("-p, --port [port:int]", "Port")
            .option("--format [format:json|yaml]", "Output format")
            .option("--config [path:file]", "Config file")
            .option("--root [dir:dir]", "Root")
            .option("--name [name]", "Name")
            .option("-v, --verbose", "Verbose")
            .argument("<root:dir>", "Document root")
            .argument("[ids:int...]", "Ids"))
        .command(new TestCommand("remote")
            .description("Manage remotes")
            .command(new TestCommand("add").description("Add remote").argument("<name>", "Remote name"))
            .command(new TestCommand("rm").argument("<name:a|b>", "Remote name")));
}
