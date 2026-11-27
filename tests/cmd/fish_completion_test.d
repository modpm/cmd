module cmd.fish_completion_test;

import std.algorithm : count;

import fluent.asserts;

import cmd.fish_completion;
import cmd.argument;
import cmd.option;
import cmd.program;
import cmd.test_support;

unittest {
    auto script = FishCompletion.generate(completionProgram());
    expect(script).to.startWith("# fish completion for my-app\n");
    expect(script).to.contain("complete -c 'my-app' -f -a '(__my_app)'");
    foreach (placeholder; ["@PROGRAM@", "@FN@", "@NAME@", "@LOAD@", "@OPTION@", "@ARGUMENT@", "@VERSION@"])
        expect(script).to.not.contain(placeholder);
}

unittest {
    auto script = FishCompletion.generate(new TestProgram("my.app-2").command(new TestCommand("go")));
    expect(script).to.contain("function __my_app_2_load");
    expect(script).to.contain("complete -c 'my.app-2' -f -a '(__my_app_2)'");
}

unittest {
    auto script = FishCompletion.generate(completionProgram());
    expect(script).to.contain("case ''\n            printf '%s\\t%s\\t%s\\n' s 'serve'");
    expect(script).to.contain(`printf '%s\t%s\t%s\n' s 'serve' 'Serve files, it\'s \'quoted\''`);
    expect(script).to.contain(`printf '%s\t%s\t%s\n' s 'remote' 'Manage remotes'`);
    expect(script).to.contain(`printf '%s\t%s\t%s\n' s 'rm' ''`);
    expect(script).to.contain("case 'remote add'\n");
    expect(script).to.contain("case 'remote rm'\n");
}

unittest {
    auto script = FishCompletion.generate(completionProgram());
    expect(script.count(`printf '%s\t%s\t%s\n' f '--help' 'Show help'`)).to.equal(5);
    expect(script.count(`printf '%s\t%s\t%s\n' f '-h' 'Show help'`)).to.equal(5);
    expect(script.count(`printf '%s\t%s\t%s\n' f '--version' 'Show version'`)).to.equal(5);
}

unittest {
    auto script = FishCompletion.generate(completionProgram());
    expect(script).to.contain(`printf '%s\t%s\t%s\n' f '-v' 'Verbose'`);
    expect(script).to.contain(`printf '%s\t%s\t%s\n' f '--verbose' 'Verbose'`);
    expect(script).to.contain(`printf '%s\t%s\t%s\n' o '-p' 'Port'`);
    expect(script).to.contain(`printf '%s\t%s\t%s\n' o '--port' 'Port'`);
    expect(script).to.contain(`printf '%s\t%s\t%s\n' o '--format' 'Output format'`);
}

unittest {
    auto script = FishCompletion.generate(new TestProgram("app").option("-x, --xx", "d").command(new TestCommand("go")));
    expect(script).to.not.contain("f '--help'");
    expect(script).to.not.contain("f '--version'");
}

unittest {
    auto script = FishCompletion.generate(completionProgram());
    expect(script).to.contain("case 'serve:--format'\n            printf '%s\\n' words 'json' 'yaml'\n");
    expect(script).to.contain("case 'serve:--config'\n            echo file\n");
    expect(script).to.contain("case 'serve:--root'\n            echo dir\n");
    expect(script).to.not.contain("'serve:--port'");
    expect(script).to.not.contain("'serve:-p'");
    expect(script).to.not.contain("'serve:--name'");
}

unittest {
    auto program = new TestProgram("app").command(new TestCommand("go")
        .option("-f, --file [path:file]", "File"));
    expect(FishCompletion.generate(program)).to.contain("case 'go:-f' 'go:--file'\n            echo file\n");
}

unittest {
    auto script = FishCompletion.generate(completionProgram());
    expect(script).to.contain(
        "case 'serve'\n            switch $argv[2]\n                case 0\n                    echo dir\n"
        ~ "                case '*'\n");
    expect(script).to.contain(
        "case 'remote rm'\n            switch $argv[2]\n                case 0\n"
        ~ "                    printf '%s\\n' words 'a' 'b'\n");
    expect(script).to.not.contain("case 'remote add'\n            switch");
}

unittest {
    auto program = new TestProgram("app").argument("<files:file...>", "Files");
    expect(FishCompletion.generate(program)).to.contain(
        "case ''\n            switch $argv[2]\n                case '*'\n                    echo file\n");
}

unittest {
    auto program = new TestProgram("app").command(new TestCommand("go").argument("<kind:a b|c>", "Kind"));
    expect(FishCompletion.generate(program)).to.contain("printf '%s\\n' words 'a b' 'c'");
}

unittest {
    auto program = new TestProgram("app").command(new TestCommand("go").description("back\\slash"));
    expect(FishCompletion.generate(program)).to.contain(`s 'go' 'back\\slash'`);
}

unittest {
    auto program = new TestProgram("app").command(new TestCommand("install")
        .add(Option.fromString("-r, --registry <name>", "Registry").completer((prefix) => ["npm"]))
        .add(Option.fromString("-f, --format <format:a|b>", "Format").completer((prefix) => ["c"]))
        .add(Argument.fromString("<package>", "Package").completer((prefix) => ["alpha"])));
    auto script = FishCompletion.generate(program);
    expect(script).to.contain("case 'install:-r' 'install:--registry'\n            printf '%s\\n' dynamic 'install:--registry'\n");
    expect(script).to.contain("case 'install:-f' 'install:--format'\n            printf '%s\\n' dynamic 'install:--format'\n");
    expect(script).to.contain("case 0\n                    printf '%s\\n' dynamic 'install:0'\n");
    expect(script).to.contain("case dynamic\n            for v in ('app' completion suggest -- $spec[2] \"$prefix\" 2>/dev/null)\n");
    expect(script).to.not.contain("words 'a' 'b'");
}

unittest {
    expect(FishCompletion.generate(completionProgram())).to.not.contain("dynamic '");
}
