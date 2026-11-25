module cmd.help_test;

import std.array : join;
import std.exception : collectException;

import fluent.asserts;

import cmd.ansi;
import cmd.command;
import cmd.help_command;
import cmd.program;
import cmd.test_support;

unittest {
    Program program = new TestProgram("app");
    expect(program.usage()).to.equal("app");
    expect(program.usage(true)).to.equal("app");
}

unittest {
    Program program = new TestProgram("app")
        .argument("<input>", "d")
        .argument("[output]", "d")
        .argument("[files...]", "d");
    expect(program.usage()).to.equal("app <input> [output] [files...]");
    expect(program.usage(true).stripAnsi()).to.equal("app <input> [output] [files...]");
}

unittest {
    Program required = new TestProgram("app").option("-t, --target <n>", "d");
    expect(required.usage()).to.equal("app <options>");

    Program optional = new TestProgram("app").option("-p, --port [n]", "d");
    expect(optional.usage()).to.equal("app [options]");

    Program flags = new TestProgram("app").option("-v, --verbose", "d");
    expect(flags.usage()).to.equal("app [options]");

    Program mixed = new TestProgram("app").option("-v, --verbose", "d").option("-t, --target <n>", "d");
    expect(mixed.usage()).to.equal("app <options>");
}

unittest {
    Program program = new TestProgram("app").option("-t, --target <n>", "d").argument("<input>", "d");
    expect(program.usage()).to.equal("app <options> <input>");
}

unittest {
    Program help = new TestProgram("app").helpOption("-h, --help", "d");
    expect(help.usage()).to.equal("app [options]");

    Program versioned = new TestProgram("app").versionString("1").versionOption("--version", "d");
    expect(versioned.usage()).to.equal("app [options]");

    Program both = new TestProgram("app")
        .versionString("1")
        .versionOption("--version", "d")
        .helpOption("-h, --help", "d");
    expect(both.usage()).to.equal("app [options]");
}

unittest {
    Program required = new TestProgram("app").helpOption("-h, --help", "d").option("-t, --target <n>", "d");
    expect(required.usage()).to.equal("app <options>");

    Program optional = new TestProgram("app").helpOption("-h, --help", "d").option("-p, --port [n]", "d");
    expect(optional.usage()).to.equal("app [options]");

    Program withArgument = new TestProgram("app").helpOption("-h, --help", "d").argument("<input>", "d");
    expect(withArgument.usage()).to.equal("app [options] <input>");
}

unittest {
    Program program = new TestProgram("app").helpOption("-h, --help", "d");
    program.command(new TestCommand("sub"));
    expect(program.usage()).to.equal("app [options] <command> ...");
}

unittest {
    Program program = new TestProgram("app").helpOption("-h, --help", "d");
    auto sub = new TestCommand("sub");
    program.add(sub);
    sub.option("-v, --verbose", "d");
    expect(sub.usage()).to.equal("app [global options] sub [options]");
}

unittest {
    Program program = new TestProgram("app");
    auto sub = new TestCommand("sub");
    program.add(sub);
    expect(sub.usage()).to.equal("app sub");
    expect(sub.usage(true)).to.equal("app sub");
}

unittest {
    Program program = new TestProgram("app").helpOption("-h, --help", "d");
    auto sub = new TestCommand("sub");
    program.add(sub);
    expect(sub.usage()).to.equal("app [global options] sub");

    Program versioned = new TestProgram("app").versionString("1").versionOption("--version", "d");
    auto other = new TestCommand("other");
    versioned.add(other);
    expect(other.usage()).to.equal("app [global options] other");
}

unittest {
    Program program = new TestProgram("app");
    auto sub = new TestCommand("sub");
    program.add(sub);
    sub.option("-v, --verbose", "d");
    sub.argument("<name>", "d");
    expect(sub.usage()).to.equal("app sub [options] <name>");
}

unittest {
    Program program = new TestProgram("app");
    auto sub = new TestCommand("sub");
    program.add(sub);
    sub.option("-t, --target <n>", "d");
    expect(sub.usage()).to.equal("app sub <options>");
}

unittest {
    Program program = new TestProgram("app").helpOption("-h, --help", "d");
    auto remote = new TestCommand("remote");
    program.add(remote);
    auto add = new TestCommand("add");
    remote.add(add);
    add.argument("<url>", "d");
    expect(remote.usage()).to.equal("app [global options] remote <command> ...");
    expect(add.usage()).to.equal("app [global options] remote add <url>");
}

unittest {
    Program program = new TestProgram("app");
    auto remote = new TestCommand("remote");
    program.add(remote);
    auto add = new TestCommand("add");
    remote.add(add);
    auto deep = new TestCommand("deep");
    add.add(deep);
    expect(deep.usage()).to.equal("app remote add deep");
    expect(deep.chain.length).to.equal(4);
}

unittest {
    Program program = new TestProgram("app");
    int status = -1;
    auto output = captureStdout({ status = program.printHelp(); });
    expect(status).to.equal(0);
    expect(output.stripAnsi()).to.equal("Usage:\n  app\n");
}

unittest {
    auto output = helpOf(new TestProgram("app"));
    expect(output).to.equal(bold("Usage:") ~ "\n  app\n");
}

unittest {
    Program program = new TestProgram("app").description("Does things");
    expect(helpOf(program).stripAnsi()).to.equal("Usage:\n  app\n\nDescription:\n  Does things\n");
}

unittest {
    Program program = new TestProgram("app").description("Does things");
    auto output = helpOf(program);
    expect(output).to.contain(bold("Usage:"));
    expect(output).to.contain(bold("Description:"));
}

unittest {
    Program program = new TestProgram("app")
        .argument("<input>", "Input file")
        .argument("[files...]", "More files");
    auto expected = [
        "Usage:",
        "  app <input> [files...]",
        "",
        "Arguments:",
        "  input  Input file",
        "  files  More files",
    ].join("\n") ~ "\n";
    expect(helpOf(program).stripAnsi()).to.equal(expected);
}

unittest {
    Program program = new TestProgram("app")
        .option("-q, --quiet", "Quiet")
        .option("-o, --output [file]", "Output file", "a.out");
    auto expected = [
        "Usage:",
        "  app [options]",
        "",
        "Options:",
        "  -o, --output [file]" ~ sp(2) ~ "Output file",
        "  -q, --quiet" ~ sp(10) ~ "Quiet",
    ].join("\n") ~ "\n";
    expect(helpOf(program).stripAnsi()).to.equal(expected);
}

unittest {
    auto program = new TestProgram("app");
    auto greet = new TestCommand("greet");
    program.add(greet);
    greet.description("Greet someone")
        .argument("<name>", "Name of person")
        .option("--excited", "Add excitement")
        .option("-t, --times <n>", "Repeat count");

    expect(greet.usage()).to.equal("app greet <options> <name>");

    auto expected = [
        "Usage:",
        "  app greet <options> <name>",
        "",
        "Description:",
        "  Greet someone",
        "",
        "Arguments:",
        "  name" ~ sp(13) ~ "Name of person",
        "",
        "Options:",
        "  " ~ sp(4) ~ "--excited" ~ sp(4) ~ "Add excitement",
        "  -t, --times <n>" ~ sp(2) ~ "Repeat count",
    ].join("\n") ~ "\n";
    auto output = helpOf(greet);
    expect(output.stripAnsi()).to.equal(expected);
    expect(output).to.startWith(bold("Usage:") ~ "\n");
    expect(output).to.contain(bold("Arguments:"));
    expect(output).to.contain(bold("Options:"));
}

unittest {
    Program program = new TestProgram("app")
        .description("My app")
        .versionString("1.0.0")
        .versionOption("--version", "Show version")
        .helpOption("-h, --help", "Show help");
    program.command(new TestCommand("deploy").description("Deploy"));
    program.command(new TestCommand("alpha"));
    program.command(new TestCommand("build").description("Build it"));

    auto expected = [
        "Usage:",
        "  app [options] <command> ...",
        "",
        "Description:",
        "  My app",
        "",
        "Commands:",
        "  alpha" ~ sp(10),
        "  build" ~ sp(10) ~ "Build it",
        "  deploy" ~ sp(9) ~ "Deploy",
        "",
        "Options:",
        "  -h, --help" ~ sp(5) ~ "Show help",
        "  " ~ sp(4) ~ "--version" ~ sp(2) ~ "Show version",
    ].join("\n") ~ "\n";
    expect(helpOf(program).stripAnsi()).to.equal(expected);
}

unittest {
    Program program = new TestProgram("app");
    program.command(new TestHelpCommand());
    auto expected = [
        "Usage:",
        "  app <command> ...",
        "",
        "Commands:",
        "  help  Show help for command",
    ].join("\n") ~ "\n";
    expect(helpOf(program).stripAnsi()).to.equal(expected);
}

unittest {
    Program program = new TestProgram("app");
    program.command(new TestHelpCommand("Display help"));
    expect(helpOf(program).stripAnsi()).to.contain("  help  Display help\n");
}

unittest {
    auto help = new HelpCommand();
    expect(help.name()).to.equal("help");
    expect(help.description()).to.equal("Show help for command");
    expect(new HelpCommand("Custom").description()).to.equal("Custom");
}

unittest {
    Program program = new TestProgram("app");
    auto help = new TestHelpCommand();
    program.command(help);
    expect(help.usage()).to.equal("app help [command...]");
}

unittest {
    Program program = new TestProgram("app").description("App");
    auto build = new TestCommand("build").description("Build it");
    program.command(build).command(new TestHelpCommand());
    auto expected = helpOf(program);

    int status = -1;
    auto output = captureStdout({ status = runArgs(program, "help"); });
    expect(status).to.equal(0);
    expect(output).to.equal(expected);
}

unittest {
    Program program = new TestProgram("app").description("App");
    auto build = new TestCommand("build")
        .description("Build it")
        .argument("<target>", "Target");
    program.command(build).command(new TestHelpCommand());
    auto expected = helpOf(build);

    int status = -1;
    auto output = captureStdout({ status = runArgs(program, "help", "build"); });
    expect(status).to.equal(0);
    expect(output).to.equal(expected);
    expect(output).to.not.equal(helpOf(program));
}

unittest {
    Program program = new TestProgram("app");
    auto remote = new TestCommand("remote").description("Remote");
    program.command(remote).command(new TestHelpCommand());
    auto add = new TestCommand("add").description("Add remote").argument("<url>", "Url");
    remote.add(add);
    auto expected = helpOf(add);

    int status = -1;
    auto output = captureStdout({ status = runArgs(program, "help", "remote", "add"); });
    expect(status).to.equal(0);
    expect(output).to.equal(expected);
}

unittest {
    Program program = new TestProgram("app");
    program.command(new TestHelpCommand());
    auto failure = collectCliExit({ runArgs(program, "help", "nope"); });
    expect(failure).to.not.beNull;
    expect(failure.status).to.equal(2);
    expect(failure.msg).to.equal("unknown command: nope");
}

unittest {
    Program program = new TestProgram("app");
    auto build = new TestCommand("build");
    program.command(build).command(new TestHelpCommand());
    auto failure = collectCliExit({ runArgs(program, "help", "build", "nope"); });
    expect(failure).to.not.beNull;
    expect(failure.status).to.equal(2);
    expect(failure.msg).to.equal("unknown command: nope");
}

unittest {
    Program program = new TestProgram("app");
    program.command(new TestCommand("build"));
    auto failure = collectCliExit({ runArgs(program, "help", "nope"); });
    expect(failure).to.not.beNull;
    expect(failure.msg).to.equal("unknown command 'help'");
}

unittest {
    Program program = new TestProgram("app")
        .option("-f, --format [fmt:json|yaml]", "Output format", "json")
        .argument("<n:int>", "Count");
    auto expected = [
        "Usage:",
        "  app [options] <n>",
        "",
        "Arguments:",
        "  n" ~ sp(25) ~ "Count",
        "",
        "Options:",
        "  -f, --format [json|yaml]" ~ sp(2) ~ "Output format",
    ].join("\n") ~ "\n";
    expect(helpOf(program).stripAnsi()).to.equal(expected);
}

unittest {
    Program program = new TestProgram("app").argument("<format:json|yaml>", "d");
    expect(program.usage()).to.equal("app <json|yaml>");
}
