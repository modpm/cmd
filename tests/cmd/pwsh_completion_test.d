module cmd.pwsh_completion_test;

import std.algorithm : count;

import fluent.asserts;

import cmd.program;
import cmd.pwsh_completion;
import cmd.test_support;

unittest {
    auto script = PwshCompletion.generate(completionProgram());
    expect(script).to.startWith("# PowerShell completion for my-app\n");
    expect(script).to.contain("Register-ArgumentCompleter -Native -CommandName 'my-app' -ScriptBlock {");
    expect(script).to.contain("$versionNames = @('--version')");
    foreach (placeholder; ["@PROGRAM@", "@NAME@", "@DATA@", "@VALUES@", "@VERSION@"])
        expect(script).to.not.contain(placeholder);
}

unittest {
    auto script = PwshCompletion.generate(new TestProgram("app").command(new TestCommand("go")));
    expect(script).to.contain("$versionNames = @()");
}

unittest {
    auto script = PwshCompletion.generate(completionProgram());
    expect(script).to.contain("$data = @{\n    '' = @{\n");
    expect(script).to.contain("    'serve' = @{\n");
    expect(script).to.contain("    'remote' = @{\n");
    expect(script).to.contain("    'remote add' = @{\n");
    expect(script).to.contain("    'remote rm' = @{\n");
}

unittest {
    auto script = PwshCompletion.generate(completionProgram());
    expect(script).to.contain("            'serve' = 'Serve files, it''s ''quoted'''\n");
    expect(script).to.contain("            'remote' = 'Manage remotes'\n");
    expect(script).to.contain("            'rm' = 'rm'\n");
}

unittest {
    auto script = PwshCompletion.generate(completionProgram());
    expect(script.count("            '--help' = 'Show help'\n")).to.equal(5);
    expect(script.count("            '-h' = 'Show help'\n")).to.equal(5);
    expect(script.count("            '--version' = 'Show version'\n")).to.equal(5);
    expect(script).to.contain("            '--verbose' = 'Verbose'\n");
    expect(script).to.contain("            '-p' = 'Port'\n");
    expect(script).to.contain("            '--port' = 'Port'\n");
}

unittest {
    auto script = PwshCompletion.generate(completionProgram());
    expect(script).to.contain("        Subs = [ordered]@{}\n        Flags = [ordered]@{\n");
    expect(script).to.contain("        Opts = [ordered]@{}\n");
}

unittest {
    auto script = PwshCompletion.generate(completionProgram());
    expect(script).to.contain("'serve:--format' = @('words', 'json', 'yaml')");
    expect(script).to.contain("'serve:--config' = @('file')");
    expect(script).to.contain("'serve:--root' = @('dir')");
    expect(script).to.contain("'serve:0' = @('dir')");
    expect(script).to.contain("'remote rm:0' = @('words', 'a', 'b')");
    expect(script).to.not.contain("'serve:--port'");
    expect(script).to.not.contain("'serve:-p'");
    expect(script).to.not.contain("'serve:--name'");
    expect(script).to.not.contain("'serve:*'");
    expect(script).to.not.contain("'remote add:0'");
}

unittest {
    auto program = new TestProgram("app").argument("<files:file...>", "Files");
    expect(PwshCompletion.generate(program)).to.contain("':*' = @('file')");
}

unittest {
    auto program = new TestProgram("app").option("-x, --xx", "line one\nline two");
    expect(PwshCompletion.generate(program)).to.contain("'--xx' = 'line one line two'");
}

unittest {
    auto program = new TestProgram("app").option("-x, --xx", "it’s ‘fancy’");
    expect(PwshCompletion.generate(program)).to.contain("'it’’s ‘‘fancy’’'");
}

unittest {
    auto script = PwshCompletion.generate(new TestProgram("app").option("-x", "Short only").option("--yy", "Long only"));
    expect(script).to.contain("'-x' = 'Short only'");
    expect(script).to.contain("'--yy' = 'Long only'");
    expect(script).to.not.contain("'--help'");
}
