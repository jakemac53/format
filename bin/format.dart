import 'dart:io';

import 'package:dart_style/dart_style.dart';
import 'package:glob/glob.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

void main(List<String> args) async {
  var configFile = File(p.absolute('format.yaml'));
  Object? configYaml;
  while (true) {
    if (await configFile.exists()) {
      print('loading config from ${configFile.path}');
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
  final pageWidth = configYaml['page_width'] ?? 80;
  if (pageWidth is! int) {
    throw YamlException('Expected an integer for `page_width`', pageWidth.span);
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
  if (args.isEmpty) {
    allFiles = Directory.current.list(recursive: true);
  } else {
    if (args.length > 1)
      throw ArgumentError('Only one path is supported right now');
    final path = args.first;
    if (await FileSystemEntity.isDirectory(path)) {
      allFiles = Directory(path).list(recursive: true);
    } else {
      allFiles = Stream.fromIterable([File(path)]);
    }
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
      await file.writeAsString(formatted);
    }
  });
}

extension _AnyMatches on List<Glob> {
  bool anyMatches(String path) => any((glob) => glob.matches(path));
}
