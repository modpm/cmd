module cmd.program_test;

import core.exception : AssertError;
import std.exception : assertThrown;

import cmd.flag;
import cmd.program;
import cmd.test_support;

unittest {
    assertThrown!AssertError(new Program("app").versionOption("--version", "d"));
    assertThrown!AssertError(new Program("app").versionOption(new Flag(null, "version", "d")));
}

unittest {
    auto program = new Program("app").versionString("1.0.0");
    assert(captureStdout({ assert(program.printVersion() == 0); }) == "1.0.0\n");
}

unittest {
    assertThrown!AssertError(new Program("app").printVersion());
}

unittest {
    auto program = new TestProgram("app").versionString("1.0.0").option("-v, --verbose", "d");
    program.versionOption("--version", "d");
    program.helpOption("-h, --help", "d");

    auto none = parseOk(program);
    assert(none.program is program);
    assert(none.command is program);
    assert(!none.hasFlag("version"));
    assert(!none.hasFlag("help"));
    assert(!none.hasFlag("verbose"));

    assert(parseOk(program, "-v").hasFlag("verbose"));
}
