module cmd.help_test;

import std.algorithm : canFind, startsWith;
import std.array : join;
import std.exception : collectException;

import cmd.ansi;
import cmd.command;
import cmd.help_command;
import cmd.program;
import cmd.test_support;

unittest {
    Program program = new TestProgram("app");
    assert(program.usage() == "app");
    assert(program.usage(true) == "app");
}

unittest {
    Program program = new TestProgram("app")
        .argument("<input>", "d")
        .argument("[output]", "d")
        .argument("[files...]", "d");
    assert(program.usage() == "app <input> [output] [files...]");
    assert(program.usage(true).stripAnsi() == "app <input> [output] [files...]");
}

unittest {
    Program required = new TestProgram("app").option("-t, --target <n>", "d");
    assert(required.usage() == "app <options>");

    Program optional = new TestProgram("app").option("-p, --port [n]", "d");
    assert(optional.usage() == "app [options]");

    Program flags = new TestProgram("app").option("-v, --verbose", "d");
    assert(flags.usage() == "app [options]");

    Program mixed = new TestProgram("app").option("-v, --verbose", "d").option("-t, --target <n>", "d");
    assert(mixed.usage() == "app <options>");
}

unittest {
    Program program = new TestProgram("app").option("-t, --target <n>", "d").argument("<input>", "d");
    assert(program.usage() == "app <options> <input>");
}

unittest {
    Program program = new TestProgram("app").helpOption("-h, --help", "d");
    assert(program.usage().startsWith("app [options]"));

    Program versioned = new TestProgram("app").versionString("1").versionOption("--version", "d");
    assert(versioned.usage().startsWith("app [options]"));
}

unittest {
    Program program = new TestProgram("app");
    auto sub = new TestCommand("sub");
    program.add(sub);
    assert(sub.usage() == "app sub");
    assert(sub.usage(true) == "app sub");
}

unittest {
    Program program = new TestProgram("app").helpOption("-h, --help", "d");
    auto sub = new TestCommand("sub");
    program.add(sub);
    assert(sub.usage() == "app [global options] sub");

    Program versioned = new TestProgram("app").versionString("1").versionOption("--version", "d");
    auto other = new TestCommand("other");
    versioned.add(other);
    assert(other.usage() == "app [global options] other");
}

unittest {
    Program program = new TestProgram("app");
    auto sub = new TestCommand("sub");
    program.add(sub);
    sub.option("-v, --verbose", "d");
    sub.argument("<name>", "d");
    assert(sub.usage() == "app sub [options] <name>");
}

unittest {
    Program program = new TestProgram("app");
    auto sub = new TestCommand("sub");
    program.add(sub);
    sub.option("-t, --target <n>", "d");
    assert(sub.usage() == "app sub <options>");
}

unittest {
    Program program = new TestProgram("app").helpOption("-h, --help", "d");
    auto remote = new TestCommand("remote");
    program.add(remote);
    auto add = new TestCommand("add");
    remote.add(add);
    add.argument("<url>", "d");
    assert(remote.usage() == "app [global options] remote <command> ...");
    assert(add.usage() == "app [global options] remote add <url>");
}

unittest {
    Program program = new TestProgram("app");
    auto remote = new TestCommand("remote");
    program.add(remote);
    auto add = new TestCommand("add");
    remote.add(add);
    auto deep = new TestCommand("deep");
    add.add(deep);
    assert(deep.usage() == "app remote add deep");
    assert(deep.chain.length == 4);
}

unittest {
    Program program = new TestProgram("app");
    int status = -1;
    auto output = captureStdout({ status = program.printHelp(); });
    assert(status == 0);
    assert(output.stripAnsi() == "Usage:\n  app\n");
}

unittest {
    auto output = helpOf(new TestProgram("app"));
    assert(output == bold("Usage:") ~ "\n  app\n");
}

unittest {
    Program program = new TestProgram("app").description("Does things");
    assert(helpOf(program).stripAnsi() == "Usage:\n  app\n\nDescription:\n  Does things\n");
}

unittest {
    Program program = new TestProgram("app").description("Does things");
    auto output = helpOf(program);
    assert(output.canFind(bold("Usage:")));
    assert(output.canFind(bold("Description:")));
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
    assert(helpOf(program).stripAnsi() == expected);
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
    assert(helpOf(program).stripAnsi() == expected);
}

unittest {
    auto program = new TestProgram("app");
    auto greet = new TestCommand("greet");
    program.add(greet);
    greet.description("Greet someone")
        .argument("<name>", "Name of person")
        .option("--excited", "Add excitement")
        .option("-t, --times <n>", "Repeat count");

    assert(greet.usage() == "app greet <options> <name>");

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
    assert(output.stripAnsi() == expected);
    assert(output.startsWith(bold("Usage:") ~ "\n"));
    assert(output.canFind(bold("Arguments:")));
    assert(output.canFind(bold("Options:")));
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
    assert(helpOf(program).stripAnsi() == expected);
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
    assert(helpOf(program).stripAnsi() == expected);
}

unittest {
    Program program = new TestProgram("app");
    program.command(new TestHelpCommand("Display help"));
    assert(helpOf(program).stripAnsi().canFind("  help  Display help\n"));
}

unittest {
    auto help = new HelpCommand();
    assert(help.name() == "help");
    assert(help.description() == "Show help for command");
    assert(new HelpCommand("Custom").description() == "Custom");
}

unittest {
    Program program = new TestProgram("app");
    auto help = new TestHelpCommand();
    program.command(help);
    assert(help.usage() == "app help [command...]");
}

unittest {
    Program program = new TestProgram("app").description("App");
    auto build = new TestCommand("build").description("Build it");
    program.command(build).command(new TestHelpCommand());
    auto expected = helpOf(program);

    int status = -1;
    auto output = captureStdout({ status = runArgs(program, "help"); });
    assert(status == 0);
    assert(output == expected);
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
    assert(status == 0);
    assert(output == expected);
    assert(output != helpOf(program));
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
    assert(status == 0);
    assert(output == expected);
}

unittest {
    Program program = new TestProgram("app");
    program.command(new TestHelpCommand());
    auto failure = collectCliExit({ runArgs(program, "help", "nope"); });
    assert(failure !is null);
    assert(failure.status == 2);
    assert(failure.msg == "unknown command: nope");
}

unittest {
    Program program = new TestProgram("app");
    auto build = new TestCommand("build");
    program.command(build).command(new TestHelpCommand());
    auto failure = collectCliExit({ runArgs(program, "help", "build", "nope"); });
    assert(failure !is null);
    assert(failure.status == 2);
    assert(failure.msg == "unknown command: nope");
}

unittest {
    Program program = new TestProgram("app");
    program.command(new TestCommand("build"));
    auto failure = collectCliExit({ runArgs(program, "help", "nope"); });
    assert(failure !is null);
    assert(failure.msg == "unknown command 'help'");
}
