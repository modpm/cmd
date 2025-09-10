# cmd

[![Documentation](https://img.shields.io/badge/Documentation-blue)](https://modpm.github.io/cmd)
[![GitHub](https://img.shields.io/badge/GitHub-181717?logo=github)](https://github.com/modpm/cmd)
[![CI](https://github.com/modpm/cmd/actions/workflows/ci.yaml/badge.svg)](https://github.com/modpm/cmd/actions/workflows/ci.yaml)
[![Version](https://img.shields.io/dub/v/cmd)](https://code.dlang.org/packages/cmd)
[![Licence](https://img.shields.io/dub/l/cmd)](https://code.dlang.org/packages/cmd)
[![Score](https://img.shields.io/dub/score/cmd)](https://code.dlang.org/packages/cmd)
[![Downloads](https://img.shields.io/dub/dt/cmd)](https://code.dlang.org/packages/cmd)

Simple, intuitive library for building CLI applications in D.

Please see the [API Reference Documentation](https://modpm.github.io/cmd).

## Highlights

- Nested subcommands (commands may contain other commands).
- Required (`<>`) and optional (`[]`) arguments and options.
- Variadic arguments (`...`) for accepting multiple values.
- Built-in help and usage generation.
- Accepts `--option=value` and `--option value` forms.
- Repeated options are collected as arrays.

## Quick start

A minimal example that splits a string.

```d
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
```

> [!NOTE]
>
> `versionOption` enables a version flag for your program (e.g., `--version`), and helpOption enables a help flag
> (e.g., `-h` or `--help`). When specified, these flags are handled automatically:
> the library will print the version or help message and exit.

## Subcommands

Add subcommands with .command(); subcommands may themselves have nested subcommands. Example with a single subcommand:

```d
import std.stdio;
import cmd.program;

void main(string[] args)
{
    new Program("example")
        .description("An example CLI program using cmd")
        .helpOption("-h, --help", "Show help for command")
        .command(new Command("greet")
            .description("Greet someone")
            .option("--excited", "Add excitement to the greeting")
            .argument("<name>", "Name of the person to greet")
            .action((args) {
                auto msg = "Hello, " ~ args.argument("name");
                if (args.flag("excited"))
                    msg ~= "!!!";
                writeln(msg);
                return 0;
            })
        )
        .run(args);
}
```

Invoke as: `example greet [options] <name>`.

> [!IMPORTANT]
>
> A command cannot have both subcommands and arguments.

## Flags and options

Use `.option()` to add options or flags to a command.

- Options require a parameter.
- Make an option required by wrapping the parameter name in `<>`, e.g. --target `<target>`.
- Make an option optional by wrapping it in `[]`. A default value can be provided for optional options.
- An option with no parameter is a flag; flags are boolean and indicate presence.
- Options and flags may have a short name (`-x`), a long name (`--example`), or both (`-x, --example`).

Example:

```d
auto args = new Program("example")
    .option("-f, --foo <param>", "Option with a required parameterer")
    .option("-b [bar]", "Option with an optional parameter and default value", "defaultValue")
    .option("--flag", "A boolean flag")
    .parse(argv);
```

Use `args.hasOption(name)` to check if an optional option without a default value is present before accessing it.
To get the first value of an option, use `args.option(name)`. To get all values, use `args.optionList(name)`.

To check a flag, use `args.flag(name)`.

> [!NOTE]
>
> `name` can be either the short or long name. For explicitness, you can prefix with a single or double dash,
> e.g. `args.option("-o")` or `args.option("--option")`.

## Arguments

Define positional arguments with `.argument()`.

- Required positional arguments are wrapped in `<>`.
- Optional positional arguments are wrapped in `[]`.
- A variadic (rest) argument is expressed with `...` and if used must be the final argument.
  A required variadic argument requires at least one value; an optional variadic argument accepts zero or more.

Example:

```d
new Program("example")
    .argument("<input>", "Input string or value")
    .argument("[output]", "Optional output string or value")
    .argument("<items...>", "One or more items to process")
```

## Custom command classes

Create modular command implementations by extending `Command`:

```d
module example.greet_command;

import std.stdio;
import cmd.command;

class GreetCommand : Command
{
    public this()
    {
        super("greet")
            .description("Greet someone")
            .option("--excited", "Add excitement to the greeting")
            .argument("<name>", "Name of the person to greet")
            .action((args) {
                auto msg = "Hello, " ~ args.argument("name");
                if (args.flag("excited"))
                    msg ~= "!!!";
                writeln(msg);
                return 0;
            });
    }
}
```

To attach it as a subcommand: `.command(new GreetCommand())`.

# Built-in help command

`HelpCommand` is included to enable `help` as a subcommand:

```d
new Program("example")
    .command(new HelpCommand())
```

Usage: `help [command...]`

Examples:
- `example help` — show help for the program.
- `example help greet` — show help for the `greet` subcommand.
