module cmd.zsh_completion_test;

import std.algorithm : count;

import fluent.asserts;

import cmd.argument;
import cmd.option;
import cmd.program;
import cmd.test_support;
import cmd.zsh_completion;

unittest {
    auto script = ZshCompletion.generate(completionProgram());
    expect(script).to.startWith("#compdef my-app\n");
    expect(script).to.contain(
        "if [[ ${funcstack[1]} == _my_app ]]; then\n    _my_app \"$@\"\nelse\n    compdef _my_app 'my-app'\nfi\n");
}

unittest {
    auto script = ZshCompletion.generate(new TestProgram("my.app-2").option("-x", "d"));
    expect(script).to.contain("_my_app_2() {");
    expect(script).to.contain("compdef _my_app_2 'my.app-2'");
}

unittest {
    auto script = ZshCompletion.generate(completionProgram());
    expect(script).to.contain("_arguments -C -s -S -A '-*' \\\n");
    expect(script).to.contain("'1: :->command'");
    expect(script).to.contain("'*:: :->args'");
    expect(script).to.contain("serve) _my_app_1 ;;");
    expect(script).to.contain("remote) _my_app_2 ;;");
    expect(script).to.contain("add) _my_app_3 ;;");
    expect(script).to.contain("rm) _my_app_4 ;;");
}

unittest {
    auto script = ZshCompletion.generate(completionProgram());
    expect(script).to.contain(`'serve:Serve files, it'\''s '\''quoted'\'''`);
    expect(script).to.contain("                'remote:Manage remotes'\n");
    expect(script).to.contain("                'rm'\n");
}

unittest {
    auto script = ZshCompletion.generate(completionProgram());
    expect(script.count(`'*'{-h,--help}'[Show help]'`)).to.equal(5);
    expect(script.count(`--version[Show version]'`)).to.equal(5);
}

unittest {
    auto script = ZshCompletion.generate(completionProgram());
    expect(script).to.contain(`'(- * 1)*--version[Show version]'`);
    expect(script).to.contain(`'(- * 1 2)*--version[Show version]'`);
    expect(script).to.not.contain(`'(- *)`);
}

unittest {
    auto script = ZshCompletion.generate(completionProgram());
    expect(script).to.contain(`'*'{-v,--verbose}'[Verbose]'`);
    expect(script).to.contain(`'*'{-p=,--port=}'[Port]:port: '`);
    expect(script).to.contain(`'*--format=[Output format]:format:(json yaml)'`);
    expect(script).to.contain(`'*--config=[Config file]:path:_files'`);
    expect(script).to.contain(`'*--root=[Root]:dir:_files -/'`);
    expect(script).to.contain(`'*--name=[Name]:name: '`);
}

unittest {
    auto script = ZshCompletion.generate(completionProgram());
    expect(script).to.contain(`':Document root:_files -/'`);
    expect(script).to.contain(`'*:Ids: '`);
    expect(script).to.contain(`':Remote name:(a b)'`);
    expect(script).to.contain(`':Remote name: '`);
}

unittest {
    auto program = new TestProgram("app").command(new TestCommand("go").argument("[name]", "Name"));
    expect(ZshCompletion.generate(program)).to.contain(`'::Name: '`);
}

unittest {
    auto script = ZshCompletion.generate(new TestProgram("app").command(new TestCommand("go")));
    expect(script).to.contain("_app_1() {\n    return 1\n}\n");
}

unittest {
    auto script = ZshCompletion.generate(new TestProgram("app").option("-x, --xx", "Use [a]: b"));
    expect(script).to.contain(`'*'{-x,--xx}'[Use \[a\]\: b]'`);
}

unittest {
    auto program = new TestProgram("app").command(new TestCommand("go").argument("<kind:a b|c>", "Kind"));
    expect(ZshCompletion.generate(program)).to.contain(`':Kind:(a\ b c)'`);
}

unittest {
    auto program = new TestProgram("app").command(new TestCommand("install")
        .add(Option.fromString("-r, --registry <name>", "Registry").completer((prefix) => ["npm"]))
        .add(Option.fromString("-f, --format <format:a|b>", "Format").completer((prefix) => ["c"]))
        .add(Argument.fromString("<package>", "Package").completer((prefix) => ["alpha"])));
    auto script = ZshCompletion.generate(program);
    expect(script).to.contain("_app_suggest() {\n");
    expect(script).to.contain("compadd -a values\n");
    expect(script).to.contain("'app' completion suggest -- \"$1\" \"$PREFIX\"");
    expect(script).to.contain("_app_suggest_1() {\n    _app_suggest 'install:--registry'\n}\n");
    expect(script).to.contain("_app_suggest_2() {\n    _app_suggest 'install:--format'\n}\n");
    expect(script).to.contain("_app_suggest_3() {\n    _app_suggest 'install:0'\n}\n");
    expect(script).to.contain(`'*'{-r=,--registry=}'[Registry]:name:_app_suggest_1'`);
    expect(script).to.contain(`'*'{-f=,--format=}'[Format]:format:_app_suggest_2'`);
    expect(script).to.contain(`':Package:_app_suggest_3'`);
    expect(script).to.not.contain("(a b)");
}

unittest {
    expect(ZshCompletion.generate(completionProgram())).to.not.contain("_suggest");
}
