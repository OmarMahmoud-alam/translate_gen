import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:translate_kit/src/extract/exception_rules.dart';
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
        .any((folder) => filePath.contains('/$folder'));
  }

  List<String> extractVariables(String value) {
    final variableRegex =
        RegExp(r'\$\{(\w+(?:\.\w+)*)\}|\$(\w+)', multiLine: true);
    final matches = <String>[];

    for (final match in variableRegex.allMatches(value)) {
      final variable = match.group(1) ?? match.group(2);
      if (variable != null) {
        matches.add(variable);
      }
    }

    return matches;
  }

  Future<void> _processFile(File file, Map<String, String> replaceMap) async {
    final originalContent = await file.readAsString();
    var updatedContent = originalContent;
    bool changed = false;

    replaceMap.forEach((key, value) {
      final variableMatches = extractVariables(value);

      final placeholder = rules.key.replaceAll('{key}', key); // e.g., {send}

      final placeholderWithVariable = rules.keyWithVariable
          .replaceAll('{key}', key)
          .replaceAll('{args}', variableMatches.join(','));
      final singleQuoted = "'$value'";
      final doubleQuoted = '"$value"';

      if (updatedContent.contains(singleQuoted)) {
        if (variableMatches.isNotEmpty) {
          updatedContent =
              updatedContent.replaceAll(singleQuoted, placeholderWithVariable);
        } else {
          updatedContent = updatedContent.replaceAll(singleQuoted, placeholder);
        }
        changed = true;
      }

      if (updatedContent.contains(doubleQuoted)) {
        if (variableMatches.isNotEmpty) {
          updatedContent =
              updatedContent.replaceAll(doubleQuoted, placeholderWithVariable);
        } else {
          updatedContent = updatedContent.replaceAll(doubleQuoted, placeholder);
        }
        changed = true;
      }
    });

    if (changed) {
      for (final import in rules.import) {
        if (!updatedContent.contains(import)) {
          updatedContent = "$import\n$updatedContent";
          //   continue; // Insert only once
        }
      }
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
