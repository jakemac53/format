import 'dart:io';
import 'package:args/args.dart';

final argParser = ArgParser(
    allowTrailingOptions: true,
    usageLineLength: stdout.hasTerminal ? stdout.terminalColumns : null)
  ..addFlag(helpFlag,
      abbr: 'h', negatable: false, help: 'Show this usage information.')
  ..addOption(outputOption,
      abbr: 'o',
      help: 'Set where to write formatted output.',
      allowed: ['write', 'show', 'json', 'none'],
      allowedHelp: {
        'write': 'Overwrite formatted files on disk.',
        'show': 'Print code to terminal.',
        'none': 'Discard output.'
      },
      defaultsTo: 'write')
  ..addFlag(setExitIfChangedFlag,
      negatable: false,
      help: 'Return exit code 1 if there are any formatting changes.');

final helpFlag = 'help';
final outputOption = 'output';
final setExitIfChangedFlag = 'set-exit-if-changed';

class FormatConfig {
  final OutputConfig outputConfig;
  final bool setExitIfChanged;

  FormatConfig({required this.outputConfig, required this.setExitIfChanged});

  factory FormatConfig.fromArgs(ArgResults argResults) => FormatConfig(
      outputConfig:
          OutputConfig.fromArgument(argResults[outputOption] as String),
      setExitIfChanged: argResults[setExitIfChangedFlag] as bool);
}

enum OutputConfig {
  write,
  show,
  none;

  factory OutputConfig.fromArgument(String arg) {
    switch (arg) {
      case 'write':
        return OutputConfig.write;
      case 'show':
        return OutputConfig.show;
      case 'none':
        return OutputConfig.none;
      default:
        throw ArgumentError('Unrecognized output option $arg');
    }
  }
}
