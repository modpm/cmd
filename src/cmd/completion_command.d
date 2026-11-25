module cmd.completion_command;

import std.algorithm;
import std.array;
import std.path;
import std.process;
import std.stdio;

import cmd.bash_completion;
import cmd.command;
import cmd.fish_completion;
import cmd.program;
import cmd.zsh_completion;

/**
 * Command to generate shell completion scripts.
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
    ];

    /**
     * Constructs a new CompletionCommand instance.
     *
     * Params:
     *   description = Command description.
     */
    public this(string description = "Generate shell completion script") {
        super("completion")
            .description(description)
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
            });
    }
}
