module cmd.nu_completion_test;

import std.algorithm : count;

import fluent.asserts;

import cmd.nu_completion;
import cmd.program;
import cmd.test_support;

unittest {
    auto script = NuCompletion.generate(completionProgram());
    expect(script).to.startWith("# nushell completion for my-app\n");
    expect(script).to.contain("module completions-my_app {\n");
    expect(script).to.contain("}\n\nuse completions-my_app *\n");
}

unittest {
    auto script = NuCompletion.generate(completionProgram());
    expect(script).to.contain("export extern \"my-app\" [\n");
    expect(script).to.contain("export extern \"my-app serve\" [\n");
    expect(script).to.contain("export extern \"my-app remote\" [\n");
    expect(script).to.contain("export extern \"my-app remote add\" [\n");
    expect(script).to.contain("export extern \"my-app remote rm\" [\n");
}

unittest {
    auto script = NuCompletion.generate(completionProgram());
    expect(script).to.contain("    # Serve files, it's 'quoted'\n    export extern \"my-app serve\" [\n");
    expect(script).to.contain("    # Manage remotes\n    export extern \"my-app remote\" [\n");
    expect(script).to.not.contain("# \n");
}

unittest {
    auto script = NuCompletion.generate(completionProgram());
    expect(script.count("        --help(-h) # Show help\n")).to.equal(5);
    expect(script.count("        --version # Show version\n")).to.equal(5);
    expect(script).to.contain("        --quiet(-q) # Quiet\n");
    expect(script).to.contain("        --verbose(-v) # Verbose\n");
}

unittest {
    auto script = NuCompletion.generate(completionProgram());
    expect(script).to.contain("        --port(-p): int # Port\n");
    expect(script).to.contain("        --format: string@\"nu-complete my-app serve format\" # Output format\n");
    expect(script).to.contain("        --config: path # Config file\n");
    expect(script).to.contain("        --root: directory # Root\n");
    expect(script).to.contain("        --name: string # Name\n");
}

unittest {
    auto script = NuCompletion.generate(completionProgram());
    expect(script).to.contain("        root: directory # Document root\n");
    expect(script).to.contain("        ...ids: int # Ids\n");
    expect(script).to.contain("        name: string # Remote name\n");
    expect(script).to.contain("        name: string@\"nu-complete my-app remote rm name\" # Remote name\n");
}

unittest {
    auto script = NuCompletion.generate(completionProgram());
    expect(script).to.contain("    def \"nu-complete my-app serve format\" [] {\n        [\"json\" \"yaml\"]\n    }\n");
    expect(script).to.contain("    def \"nu-complete my-app remote rm name\" [] {\n        [\"a\" \"b\"]\n    }\n");
}

unittest {
    auto program = new TestProgram("app").argument("[shell:a|b]", "Shell");
    expect(NuCompletion.generate(program)).to.contain("        shell?: string@\"nu-complete app shell\" # Shell\n");
}

unittest {
    auto program = new TestProgram("app").argument("<my-file:file>", "File");
    expect(NuCompletion.generate(program)).to.contain("        my_file: path # File\n");
}

unittest {
    auto program = new TestProgram("app").argument("<kind:say \"hi\"|b>", "Kind");
    expect(NuCompletion.generate(program)).to.contain(`["say \"hi\"" "b"]`);
}

unittest {
    auto program = new TestProgram("app").option("-x, --xx", "line one\nline two");
    expect(NuCompletion.generate(program)).to.contain("        --xx(-x) # line one line two\n");
}

unittest {
    auto script = NuCompletion.generate(new TestProgram("app").option("-x", "Short only").option("--yy", "Long only"));
    expect(script).to.contain("        -x # Short only\n");
    expect(script).to.contain("        --yy # Long only\n");
    expect(script).to.not.contain("--help");
    expect(script).to.not.contain("--version");
}
