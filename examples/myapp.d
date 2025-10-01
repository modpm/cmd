import cmd.program;
import cmd.command;
import cmd.help_command;

void main(string[] args) {
    new Program("myapp")
        .description("My CLI application")
        .command(new Command("deploy").description("Deploy the application"))
        .command(new Command("status").description("Check application status"))
        .command(new HelpCommand())  // Adds the built-in ‘help’ subcommand
        .run(args);
}
