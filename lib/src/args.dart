import 'dart:io';
import 'package:args/args.dart';

final argParser = ArgParser(
    allowTrailingOptions: true,
    usageLineLength: stdout.hasTerminal ? stdout.terminalColumns : null)
  ..addOption(outputOptionFlag,
      abbr: 'o',
      help: 'Set where to write formatted output.',
      allowed: ['write', 'show', 'json', 'none'],
      allowedHelp: {
        'write': 'Overwrite formatted files on disk.',
        'show': 'Print code to terminal.',
        'none': 'Discard output.'
      },
      defaultsTo: 'write');

final outputOptionFlag = 'output';

class FormatConfig {
  final OutputOption outputOption;

  FormatConfig({required this.outputOption});

  factory FormatConfig.fromArgs(ArgResults argResults) => FormatConfig(
      outputOption:
          OutputOption.fromArgument(argResults[outputOptionFlag] as String));
}

enum OutputOption {
  write,
  show,
  none;

  factory OutputOption.fromArgument(String arg) {
    switch (arg) {
      case 'write':
        return OutputOption.write;
      case 'show':
        return OutputOption.show;
      case 'none':
        return OutputOption.none;
      default:
        throw ArgumentError('Unrecognized output option $arg');
    }
  }
}
