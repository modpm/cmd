module cmd.bash_completion_test;

import std.algorithm : count;

import fluent.asserts;

import cmd.bash_completion;
import cmd.argument;
import cmd.option;
import cmd.program;
import cmd.test_support;

unittest {
    auto script = BashCompletion.generate(completionProgram());
    expect(script).to.startWith("# bash completion for my-app\n");
    expect(script).to.contain("complete -F _my_app 'my-app'");
    foreach (placeholder; ["@PROGRAM@", "@FN@", "@NAME@", "@LOAD@", "@OPTION@", "@ARGUMENT@", "@VERSION@"])
        expect(script).to.not.contain(placeholder);
}

unittest {
    auto script = BashCompletion.generate(new TestProgram("my.app-2").command(new TestCommand("go")));
    expect(script).to.contain("_my_app_2_load()");
    expect(script).to.contain("complete -F _my_app_2 'my.app-2'");
}

unittest {
    auto script = BashCompletion.generate(completionProgram());
    expect(script).to.contain(
        "'')\n            subs='serve remote'\n            flags='-h --help --version -q --quiet'\n            opts=''\n");
    expect(script).to.contain(
        "'serve')\n            subs=''\n            flags='-h --help --version -v --verbose'\n"
        ~ "            opts='-p --port --format --config --root --name'\n");
    expect(script).to.contain("'remote')\n            subs='add rm'\n");
    expect(script).to.contain("'remote add')\n            subs=''\n");
    expect(script).to.contain("'remote rm')\n            subs=''\n");
}

unittest {
    auto script = BashCompletion.generate(completionProgram());
    expect(script.count("--help")).to.equal(5);
    expect(script.count("--version")).to.equal(6);
}

unittest {
    auto script = BashCompletion.generate(new TestProgram("app").command(new TestCommand("go")));
    expect(script).to.contain("subs='go'\n            flags=''\n            opts=''\n");
    expect(script).to.contain("[[ \"  \" == *\" $w \"* ]] && return 0");
}

unittest {
    auto script = BashCompletion.generate(completionProgram());
    expect(script).to.contain("[[ \" --version \" == *\" $w \"* ]] && return 0");
}

unittest {
    auto script = BashCompletion.generate(completionProgram());
    expect(script).to.contain("'serve:--format') kind=words; values='json yaml' ;;");
    expect(script).to.contain("'serve:--config') kind=file ;;");
    expect(script).to.contain("'serve:--root') kind=dir ;;");
    expect(script).to.not.contain("'serve:--port'");
    expect(script).to.not.contain("'serve:-p'");
    expect(script).to.not.contain("'serve:--name'");
}

unittest {
    auto program = new TestProgram("app").command(new TestCommand("go")
        .option("-f, --file [path:file]", "File"));
    auto script = BashCompletion.generate(program);
    expect(script).to.contain("'go:-f'|'go:--file') kind=file ;;");
}

unittest {
    auto script = BashCompletion.generate(completionProgram());
    expect(script).to.contain("'serve')\n            case \"$2\" in\n                0) kind=dir ;;\n                *) ;;\n");
    expect(script).to.contain("'remote rm')\n            case \"$2\" in\n                0) kind=words; values='a b' ;;\n");
    expect(script).to.not.contain("'remote add')\n            case");
}

unittest {
    auto program = new TestProgram("app").argument("<files:file...>", "Files");
    auto script = BashCompletion.generate(program);
    expect(script).to.contain("'')\n            case \"$2\" in\n                *) kind=file ;;\n");
}

unittest {
    auto program = new TestProgram("app").command(new TestCommand("install")
        .add(Option.fromString("-r, --registry <name>", "Registry").completer((prefix) => ["npm"]))
        .add(Option.fromString("-f, --format <format:a|b>", "Format").completer((prefix) => ["c"]))
        .add(Argument.fromString("<package>", "Package").completer((prefix) => ["alpha"])));
    auto script = BashCompletion.generate(program);
    expect(script).to.contain("'install:-r'|'install:--registry') kind=dynamic; parameter='install:--registry' ;;");
    expect(script).to.contain("'install:-f'|'install:--format') kind=dynamic; parameter='install:--format' ;;");
    expect(script).to.not.contain("values=");
    expect(script).to.contain("'install')\n            case \"$2\" in\n                0) kind=dynamic; parameter='install:0' ;;\n");
    expect(script).to.contain("<('app' completion suggest -- \"$parameter\" \"$prefix\" 2>/dev/null)");
}

unittest {
    expect(BashCompletion.generate(completionProgram())).to.not.contain("kind=dynamic");
}
