import std.stdio;
import std.string;

import cmd.program;

void main(string[] argv)
{
    auto args = new Program("split")
        .description("Split a string")
        .versionString("1.0.0")
        .versionOption("--version", "Show version information")
        .helpOption("-h, --help", "Show help for command")
        .argument("<string>", "String to split")
        .option("-s, --separator <char>", "Separator character")
        .option("--first", "Return only the first element")
        .parse(argv);

    auto parts = args.argument("string").split(args.option("separator"));
    if (args.flag("first"))
        writeln(parts[0]);
    else
        writeln(parts);
}
