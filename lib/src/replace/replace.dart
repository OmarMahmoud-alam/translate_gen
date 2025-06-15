import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:translatehelper/src/extract/exception_rules.dart';
import 'package:yaml/yaml.dart';

class Replace {
  final String baseDir;
  final String folderPath;
  final ExceptionRules rules;
  final Map<String, String> replaceMap = {};

  Replace(
      {required this.baseDir, required this.rules, required this.folderPath});

  Future<void> process() async {
    final replaceFilePath =
        p.join('assets', 'translationsHelper', 'replace.json');
    final replaceFile = File(replaceFilePath);
    stderr.write('Processing replace file: $replaceFilePath\n');

    if (await replaceFile.exists()) {
      stderr.write('Replace file exists.\n');
      final content = await replaceFile.readAsString();
      stderr.write('Read replace file content.\n');
      replaceMap.addAll(Map<String, String>.from(jsonDecode(content)));
    }

    final dartFiles = await _collectDartFiles(Directory(folderPath));
    for (final file in dartFiles) {
      await _processFile(file, replaceMap);
    }

    // Save updated replaceMap
    //   await replaceFile
    //     .writeAsString(jsonEncode(replaceMap, toEncodable: (e) => e));
  }

  Future<List<File>> _collectDartFiles(Directory dir) async {
    final files = <File>[];

    await for (var entity in dir.list(recursive: true)) {
      if (entity is File &&
          entity.path.endsWith('.dart') &&
          !_isInIgnoredFolder(entity.path)) {
        files.add(entity);
      }
    }

    return files;
  }

  bool _isInIgnoredFolder(String filePath) {
    return rules.folderExceptions
        .any((folder) => filePath.contains('/$folder/'));
  }

  Future<void> _processFile(File file, Map<String, String> replaceMap) async {
    final originalContent = await file.readAsString();
    var updatedContent = originalContent;
    bool changed = false;

    // First, replace existing values in replaceMap with {key}
    replaceMap.forEach((key, value) {
      final placeholder = rules.key.replaceAll('{key}', key); // e.g., '{key}'
      if (updatedContent.contains(value)) {
        updatedContent = updatedContent.replaceAll(value, placeholder);
        changed = true;
      }
    });

    // Then apply regex extractFilter to find new strings to add
    /*  for (var regex in rules.extractFilter) {
   final matches = regex.allMatches(originalContent).toList();

      for (final match in matches) {
        final fullMatch = match.group(0)!;
        final innerText = match.group(1)!;

        if (fullMatch.contains('{')) continue; // Skip already processed

        final key = replaceMap[innerText] ?? _generateKey(innerText);
        final replacement = rules.key.replaceAll('{key}', key);

        if (!replaceMap.containsKey(innerText)) {
          replaceMap[innerText] = key;
        }

        updatedContent = updatedContent.replaceAll(fullMatch, replacement);
        changed = true;
      }
    } */

    if (changed) {
      await file.writeAsString(updatedContent);
      print('Updated: ${file.path}');
    }
  }

  String _generateKey(String text) {
    return text
        .replaceAll(RegExp(r'[^\u0621-\u064A0-9a-zA-Z]+'),
            '_') // Keep Arabic, letters, numbers
        .toLowerCase()
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
  }
}
