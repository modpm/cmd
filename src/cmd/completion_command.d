module cmd.completion_command;

import std.stdio;

import cmd.bash_completion;
import cmd.command;
import cmd.zsh_completion;

/**
 * Command to generate shell completion scripts.
 */
class CompletionCommand : Command {
    /**
     * Constructs a new CompletionCommand instance.
     *
     * Params:
     *   description = Command description.
     */
    public this(string description = "Generate shell completion script") {
        super("completion")
            .description(description)
            .command(new Command("bash")
                .description("Generate completion script for bash")
                .action((args) {
                    write(BashCompletion.generate(args.program));
                    return 0;
                })
            )
            .command(new Command("zsh")
                .description("Generate completion script for zsh")
                .action((args) {
                    write(ZshCompletion.generate(args.program));
                    return 0;
                })
            );
    }
}
