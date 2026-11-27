module cmd.completion_command;

import std.algorithm;
import std.array;
import std.conv;
import std.exception : ifThrown;
import std.path;
import std.process;
import std.stdio;
import std.string : lastIndexOf;

import cmd.bash_completion;
import cmd.command;
import cmd.fish_completion;
import cmd.nu_completion;
import cmd.program;
import cmd.pwsh_completion;
import cmd.zsh_completion;

/**
 * Command to generate shell completion scripts and to provide dynamic suggestions to them.
 */
class CompletionCommand : Command {
    private struct Shell {
        string name;
        string function(const(Program)) generate;
    }

    private static immutable Shell[] shells = [
        Shell("bash", &BashCompletion.generate),
        Shell("zsh", &ZshCompletion.generate),
        Shell("fish", &FishCompletion.generate),
        Shell("nu", &NuCompletion.generate),
        Shell("pwsh", &PwshCompletion.generate),
    ];

    /**
     * Constructs a new CompletionCommand instance.
     *
     * Params:
     *   description = Command description.
     */
    public this(string description = "Shell completion") {
        super("completion")
            .description(description)
            .command(new Command("generate")
                .description("Generate shell completion script")
                .argument(
                    "[shell:" ~ shells.map!(s => s.name).join("|") ~ "]",
                    "Shell to generate the script for, defaults to the login shell"
                )
                .action((args) {
                    string name;
                    if (args.hasArgument("shell"))
                        name = args.argument("shell");
                    else {
                        name = baseName(environment.get("SHELL", ""));
                        if (!shells.any!(s => s.name == name))
                            error("cannot detect the login shell, specify one of: " ~ shells.map!(s => s.name).join(", "), 2);
                    }
                    write(shells.find!(s => s.name == name).front.generate(args.program));
                    return 0;
                }))
            .command(new Command("suggest")
                .description("Print the suggestions for an option or argument")
                .argument("<parameter>", "Option or argument to suggest values for, e.g. serve:--registry or serve:0")
                .argument("[prefix]", "Typed prefix of the value", "")
                .action((args) {
                    const parameter = args.argument("parameter");
                    const separator = parameter.lastIndexOf(':');
                    if (separator < 0)
                        error("invalid parameter '" ~ parameter ~ "': expected command path and name separated by ':'", 2);

                    Command command = cast(Command) args.program;
                    foreach (word; parameter[0..separator].split(' ').filter!(w => !w.empty())) {
                        command = cast(Command) command.findCommand(word);
                        if (command is null)
                            error("unknown command '" ~ word ~ "' in parameter '" ~ parameter ~ "'", 2);
                    }

                    const name = parameter[separator + 1..$];
                    string[] delegate(string) const source;
                    if (name.startsWith("-")) {
                        foreach (opt; command.options)
                            if (opt.matches(name) && opt.hasCompleter())
                                source = &opt.complete;
                    } else {
                        const index = name.to!size_t.ifThrown(size_t.max);
                        if (index < command.arguments.length && command.arguments[index].hasCompleter())
                            source = &command.arguments[index].complete;
                    }
                    if (source is null)
                        error("no suggestions for parameter '" ~ parameter ~ "'", 2);

                    try {
                        foreach (value; source(args.argument("prefix")))
                            writeln(value);
                    } catch (Exception) {
                    }
                    return 0;
                }));
    }
}
