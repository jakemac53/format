import 'dart:io';

import 'package:dart_style/dart_style.dart';
import 'package:format/src/args.dart';
import 'package:glob/glob.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

void main(List<String> args) async {
  final parsedArgs = argParser.parse(args);
  if (parsedArgs[helpFlag] as bool) {
    print('''
Idiomatically format Dart source code, with support for format.dart.yml files.

Usage: format [options...] <files or directories...>]
${argParser.usage}
''');
    return;
  }
  final config = FormatConfig.fromArgs(parsedArgs);
  final paths = parsedArgs.rest;
  if (paths.isEmpty) {
    throw ArgumentError('Must provide a path to format');
  }
  await Future.wait([
    for (var path in paths) formatPath(path, config),
  ]);
}

Future<void> formatPath(String path, FormatConfig config) async {
  var configFile = File(p.absolute('format.dart.yaml'));
  Object? configYaml;
  while (true) {
    if (await configFile.exists()) {
      print('Formatting $path with config from ${configFile.path}');
      configYaml =
          loadYaml(await configFile.readAsString(), sourceUrl: configFile.uri);
      break;
    }
    var parentDir = p.dirname(configFile.path);
    var parentParentDir = p.dirname(parentDir);
    if (parentParentDir == parentDir) {
      break;
    }
    configFile = File(p.join(parentParentDir, 'format.yaml'));
  }
  if (configYaml is! YamlMap) {
    throw ArgumentError(
        'Expected the ${configFile.uri} to contain a Map, but got $configYaml');
  }
  final pageWidth = configYaml['line_length'] ?? 80;
  if (pageWidth is! int) {
    throw YamlException(
        'Expected an integer for `line_length`', pageWidth.span);
  }
  final formatter = DartFormatter(pageWidth: pageWidth);

  final includes = configYaml['include'] as YamlNode? ?? ['**/*.dart'];
  if (includes is! List || !includes.every((element) => element is String)) {
    throw YamlException('Expected a list of strings for `include`',
        (includes as YamlList).span);
  }
  final includeGlobs = [
    for (var include in includes) Glob(include),
  ];
  final excludes = configYaml['exclude'] as YamlNode? ?? [];
  if (excludes is! List || !excludes.every((element) => element is String)) {
    throw YamlException('Expected a list of strings for `exclude`',
        (excludes as YamlList).span);
  }
  final excludeGlobs = [
    for (var exclude in excludes) Glob(exclude),
  ];
  final Stream<FileSystemEntity> allFiles;
  if (await FileSystemEntity.isDirectory(path)) {
    allFiles = Directory(path).list(recursive: true);
  } else {
    allFiles = Stream.fromIterable([File(path)]);
  }

  allFiles.listen((file) async {
    if (file is! File) return;
    var path = p.relative(file.path, from: p.dirname(configFile.path));
    if (!includeGlobs.anyMatches(path) || excludeGlobs.anyMatches(path)) {
      return;
    }
    var original = await file.readAsStringSync();
    var formatted = formatter.format(original, uri: file.uri);
    if (original == formatted) {
      print('Unchanged ${path}');
    } else {
      print('Changed ${path}');
      if (config.setExitIfChanged) exitCode = 1;
      switch (config.outputConfig) {
        case OutputConfig.write:
          await file.writeAsString(formatted);
          break;
        case OutputConfig.show:
          print(formatted);
          break;
        case OutputConfig.none:
          break;
      }
    }
  });
}

extension _AnyMatches on List<Glob> {
  bool anyMatches(String path) => any((glob) => glob.matches(path));
}
