module modular.commands.greet;

import std.stdio;

import cmd.command;
import cmd.parsed_args;

class GreetCommand : Command
{
    public this()
    {
        super("greet")
            .description("Greet someone")
            .argument("<name>", "Name of the person to greet")
            .option("--excited", "Add excitement to the greeting")
            .action(&execute);
    }

    private int execute(ParsedArgs args)
    {
        auto msg = "Hello, " ~ args.argument("name");
        if (args.flag("excited"))
            msg ~= "!!!";
        writeln(msg);
        return 0;
    }
}

import modular.commands.greet;
import cmd.program;

void main(string[] args)
{
    new Program("modular")
        .command(new GreetCommand())
        .run(args);
}
