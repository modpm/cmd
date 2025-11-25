import std.stdio;
import std.string;

import cmd.program;
import cmd.command;

void main(string[] args)
{
    new Program("subcommands")
        .description("A CLI application with subcommands")
        .versionString("1.0.0")
        .helpOption("-h, --help", "Show help for command")
        .command(new Command("split")
            .description("Split a string")
            .argument("<string>", "String to split")
            .option("-s, --separator <char>", "Separator character")
            .action((args) {
                auto parts = args.argument("string").split(args.option("separator"));
                writeln(parts);
                return 0;
            })
        )
        .command(new Command("greet")
            .description("Greet someone")
            .argument("<name>", "Name of the person to greet")
            .option("--excited", "Add excitement to the greeting")
            .action((args) {
                auto msg = "Hello, " ~ args.argument("name");
                if (args.hasFlag("excited"))
                    msg ~= "!!!";
                writeln(msg);
                return 0;
            })
        )
        .run(args);
}
