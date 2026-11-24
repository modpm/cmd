module cmd.program_test;

import core.exception : AssertError;

import fluent.asserts;

import cmd.flag;
import cmd.program;
import cmd.test_support;

unittest {
    expect({ new Program("app").versionOption("--version", "d"); }).to.throwException!AssertError;
    expect({ new Program("app").versionOption(new Flag(null, "version", "d")); }).to.throwException!AssertError;
}

unittest {
    auto program = new Program("app").versionString("1.0.0");
    expect(captureStdout({ expect(program.printVersion()).to.equal(0); })).to.equal("1.0.0\n");
}

unittest {
    expect({ new Program("app").printVersion(); }).to.throwException!AssertError;
}

unittest {
    auto program = new TestProgram("app").versionString("1.0.0").option("-v, --verbose", "d");
    program.versionOption("--version", "d");
    program.helpOption("-h, --help", "d");

    auto none = parseOk(program);
    expect(none.program is program).to.equal(true);
    expect(none.command is program).to.equal(true);
    expect(none.hasFlag("version")).to.equal(false);
    expect(none.hasFlag("help")).to.equal(false);
    expect(none.hasFlag("verbose")).to.equal(false);

    expect(parseOk(program, "-v").hasFlag("verbose")).to.equal(true);
}
