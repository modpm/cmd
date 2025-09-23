module cmd.help_command;

import cmd.command;

/**
 * Command to display help for commands.
 */
class HelpCommand : Command {
    /**
     * Constructs a new HelpCommand instance.
     *
     * Params:
     *   description = Command description.
     */
    public this(string description = "Show help for command") {
        super("help")
            .description(description)
            .argument("[command...]", "Command to show help for")
            .action((args) {
                if (!args.hasArgument("command"))
                    return args.program.printHelp();

                Command target = cast(Command) args.program;
                foreach (cmd; args.argumentList("command")) {
                    target = cast(Command) target.findCommand(cmd);
                    if (target is null)
                        error("unknown command: " ~ cmd, 2);
                }
                return target.printHelp();
            });
    }
}
