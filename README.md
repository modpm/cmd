# cmd

[![Documentation](https://img.shields.io/badge/Documentation-blue)](https://modpm.github.io/cmd)
[![GitHub](https://img.shields.io/badge/GitHub-181717?logo=github)](https://github.com/modpm/cmd)
[![CI](https://github.com/modpm/cmd/actions/workflows/build.yaml/badge.svg)](https://github.com/modpm/cmd/actions/workflows/build.yaml)
[![Version](https://img.shields.io/dub/v/cmd)](https://code.dlang.org/packages/cmd)
[![Licence](https://img.shields.io/dub/l/cmd)](https://github.com/modpm/cmd/blob/main/COPYING)
[![Score](https://img.shields.io/dub/score/cmd)](https://code.dlang.org/packages/cmd)
[![Downloads](https://img.shields.io/dub/dt/cmd)](https://code.dlang.org/packages/cmd)

A simple, intuitive library for building CLI applications in D.

**[API Reference Documentation](https://modpm.github.io/cmd)**

## Features

- **Nested subcommands** — Supports hierarchical command structures, allowing commands to contain other commands.
- **Flexible arguments** — Required (`<>`) and optional (`[]`) arguments with variadic support (`...`).
- **Rich option handling** — Supports `--option=value` and `--option value` forms.
- **Automatic help generation** — Built-in help and usage text generation.
- **Array collection** — Repeated options are automatically collected as arrays.
- **Type-safe parsing** — Clean API for accessing parsed arguments and options.

## Quick Start

Here’s a minimal example that splits a string:

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

### Usage

```bash
$ ./split "hello,world,foo" --separator ","
["hello", "world", "foo"]

$ ./split "hello,world,foo" --separator "," --first
hello
```

**Note:** [`versionOption()`](https://modpm.github.io/cmd/cmd.program.Program.versionOption.2.html) enables a version flag for your program (e.g., `--version`), and [`helpOption()`](https://modpm.github.io/cmd/cmd.program.Program.helpOption.1.html) enables a help flag (e.g., `-h` or `--help`). When specified, these flags are handled automatically: the library will print the version or help message and exit.

## Options and Flags

Use [`option()`](https://modpm.github.io/cmd/cmd.command.Command.option.html) to add named parameters to your commands:

### Option Types

```d
ParsedArgs args = new Program("example")
    // Required option - user must provide a value
    .option("-t, --target <name>", "Target name")

    // Optional with default value
    .option("-p, --port [number]", "Port number", "8080")

    // Optional without default
    .option("-c, --config [file]", "Configuration file")

    // Boolean flag - without a parameter
    .option("--verbose", "Enable verbose output")
    .option("-q, --quiet", "Suppress output")

    .parse(argv);
```

### Accessing Values

Please see the API reference page for [`ParsedArgs`](https://modpm.github.io/cmd/cmd.parsed_args.ParsedArgs.html).

```d
// Get option value (first occurrence)
const string target = args.option("target");
const string port = args.option("port");


// Get all values for repeated options
// const string[] targets = args.optionList("target");

// Check if optional option is present
if (args.hasOption("--config")) {
    const string config = args.option("--config");
    // ...
}

// Check boolean flags
if (args.flag("verbose"))
    writeln("Verbose mode enabled");
const bool quiet = args.flag("-q");
```

You can access options using:
- `option("target")` - access by long name (explicit for long names)
- `option("t")` - access by short name (implicit, could be ambiguous)
- `option("-t")` - access by short name (explicit)
- `option("--target")` - access by long name (explicit, stylistic)

(also applies for `hasOption()`, `flag()`, etc.)

## Arguments

Use [`argument()`](https://modpm.github.io/cmd/cmd.command.Command.argument.html) to add positional arguments that users provide in order:

```d
new Program("file-processor")
    .argument("<input>", "Input file path")    // Required
    .argument("[output]", "Output file path")  // Optional
```

### Variadic Arguments

Variadic (rest) arguments can be added as the last argument in your command to accept multiple values. Optional variadic `[files...]` accepts ≥ 0 values, required variadic `<files...>` needs ≥ 1.

```d
new Program("search")
    // …
    .argument("<files...>", "Files to search")
```

### Accessing Arguments
```d
const string inputFile = args.argument("input");

// Check if optional argument was provided
if (args.hasArgument("output")) {
    const string outputFile = args.argument("output");
}

// Get all values of variadic
const string[] files = args.argumentList("files");
```


**Note:** Required arguments after optional ones are technically allowed, but behave counter-intuitively and ambiguously for the user. It is strongly recommended not to use optional positional arguments before required ones—consider re-ordering the arguments, or using named parameters (options).

## Working with Subcommands

Build complex CLI applications with nested subcommands using [`command()`](https://modpm.github.io/cmd/cmd.command.Command.command.html). Here’s an example with basic subcommands.

```d
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
                if (args.flag("excited"))
                    msg ~= "!!!";
                writeln(msg);
                return 0;
            })
        )
        .run(args);
}
```

### Usage

```bash
$ ./subcommands split "hello,world" --separator ","
$ ./subcommands greet Alice --excited
$ ./subcommands split --help  # Shows help for the split subcommand
```

**Important:** A command cannot have both subcommands and arguments. Choose one pattern per command level.

Commands can be nested endlessly.

## Custom Command Classes

Create modular command implementations by extending [`Command`](https://modpm.github.io/cmd/cmd.command.Command.html) (or [`Program`](https://modpm.github.io/cmd/cmd.program.Program.html)):

```d
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
```

### Integration
```d
// …
import modular.commands.greet;
import cmd.program;

void main(string[] args)
{
    new Program("modular")
        .command(new GreetCommand())
        .run(args);
}
```

## Built-in Help Command

Enable `help` as a subcommand using [`HelpCommand`](https://modpm.github.io/cmd/cmd.help_command.HelpCommand.html):

```d
// …
import cmd.help_command;

new Program("myapp")
    .description("My CLI application")
    .command(new Command("deploy").description("Deploy the application"))
    .command(new Command("status").description("Check application status"))
    .command(new HelpCommand())  // Adds the built-in ‘help’ subcommand
    .run(args);
```

### Usage

```bash
$ myapp help         # Show help for program
$ myapp help deploy  # Show help for deploy command
```

## Error Handling

The library provides clear error messages for common mistakes during args parsing and exits with status code `2`:

```
error: unknown command 'unknown-command'
error: missing value for option 'target'
error: unknown option 'invalid-option'
error: unexpected argument 'extra'
error: missing required option '-t, --target <name>'
error: missing required argument 'input'
```

You can also trigger custom errors in your command actions using the [`error(string)`](https://modpm.github.io/cmd/cmd.command.Command.error.1.html) and [`noreturn error(string, int)`](https://modpm.github.io/cmd/cmd.command.Command.error.2.html) methods on `Command`:

```d
.action((args) {
    if (someCondition) {
        args.command.error("error message");     // Does not exit (only prints error)
        // or
        args.command.error("error message", 1);  // Exits with status
    }
    return 0;
});
```

The `error` methods can be overridden to customise the error format.

## Licence

Copyright © 2025 Zefir Kirilov.

This project is licenced under the [GPL-3.0](https://github.com/modpm/cmd/blob/main/COPYING) licence.
