import 'dart:io';

import 'package:translate_gen/src/translate/translation_provider.dart';

class ExceptionRules {
  List<String> textExceptions;
  List<String> lineExceptions;
  List<String> contentExceptions;
  List<String> folderExceptions;
  List<String> import;
  List<RegExp> extractFilter;
  String key;
  String geminiKey;
  String keyWithVariable;
  String extractOutput;
  TranslationProvider aiModel;
  bool translate;

  ExceptionRules({
    required this.textExceptions,
    required this.lineExceptions,
    required this.contentExceptions,
    required this.folderExceptions,
    required this.import,
    required this.extractFilter,
    required this.key,
    required this.geminiKey,
    required this.keyWithVariable,
    required this.extractOutput,
    required this.aiModel,
    required this.translate,
  });

  factory ExceptionRules.fromJson(Map<String, dynamic> json) {
    return ExceptionRules(
      textExceptions: List<String>.from(json['textExceptions'] ?? []),
      lineExceptions: List<String>.from(json['lineExceptions'] ?? []),
      contentExceptions: List<String>.from(json['contentExceptions'] ?? []),
      folderExceptions: List<String>.from(json['folderExceptions'] ?? []),
      import: List<String>.from(json['import'] ?? []),
      extractFilter: List<RegExp>.from(json['extractFilter'] ?? []),
      key: json['key'] ?? '',
      geminiKey: json['geminiKey'] ?? '',
      keyWithVariable: json['keyWithVariable'] ?? '',
      extractOutput: json['extractOutput'] ?? '',
      aiModel: TranslationProvider.values.firstWhere(
        (p) => p.name.toLowerCase() == json['aiModel'].toString().toLowerCase(),
      ),
      translate: json['translate'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'textExceptions': textExceptions,
      'lineExceptions': lineExceptions,
      'contentExceptions': contentExceptions,
      'folderExceptions': folderExceptions,
      'import': import,
      'extractFilter': extractFilter,
      'key': key,
      'geminiKey': geminiKey,
      'keyWithVariable': keyWithVariable,
      'extractOutput': extractOutput,
      'aiModel': aiModel,
      'translate': translate,
    };
  }

  factory ExceptionRules.fromSourceString(String source) {
    // stderr.write(source);
    String? extractBalancedBracketContent(String source, String fieldName) {
      final startPattern = '$fieldName: [';
      final startIndex = source.indexOf(startPattern);
      if (startIndex == -1) return null;

      int bracketCount = 0;
      int i = source.indexOf('[', startIndex);
      if (i == -1) return null;

      int start = i;
      for (; i < source.length; i++) {
        if (source[i] == '[') bracketCount++;
        if (source[i] == ']') bracketCount--;
        if (bracketCount == 0) break;
      }

      if (bracketCount != 0) return null;

      return source.substring(start + 1, i); // inside brackets
    }

    List<String> parseStringList(String name) {
      final regex = RegExp('$name:\\s*\\[(.*?)\\]', dotAll: true);
      final match = regex.firstMatch(source);
      if (match == null) return [];

      // Split on commas, but only those NOT inside quotes
      final listStr = match.group(1)!;
      return RegExp(r'''(['"])(.*?[^\\])\1''')
          .allMatches(listStr)
          .map((m) => m.group(2)!)
          .toList();
    }

    List<String> extractRegExpBlocks(String source) {
      final List<String> blocks = [];
      final pattern = 'RegExp(';

      int index = 0;
      while ((index = source.indexOf(pattern, index)) != -1) {
        int start = index + pattern.length - 1;
        int openParens = 1;
        int i = start + 1;

        while (i < source.length && openParens > 0) {
          if (source[i] == '(') openParens++;
          if (source[i] == ')') openParens--;
          i++;
        }

        if (openParens == 0) {
          blocks.add(source.substring(index, i));
          index = i;
        } else {
          break; // Unbalanced
        }
      }

      return blocks;
    }

    List<RegExp> parseRegExpListFromStrings(List<String> lines) {
      final List<RegExp> result = [];

      for (final line in lines) {
        final trimmed = line.trim();
        if (!trimmed.startsWith('RegExp(') || !trimmed.endsWith(')')) continue;

        final inside =
            trimmed.substring(7, trimmed.length - 1); // inside RegExp(...)
        final patternMatch = RegExp(r'''r(['\"])(.*?)\1''').firstMatch(inside);
        if (patternMatch == null) continue;

        final rawPattern = patternMatch.group(2)!;

        // Defaults
        bool multiLine = false;
        bool caseSensitive = true;
        bool unicode = false;
        bool dotAll = false;

        // Parse flags after pattern
        final remaining = inside.substring(patternMatch.end).trim();
        if (remaining.isNotEmpty) {
          final options =
              RegExp(r'(\w+):\s*(true|false)').allMatches(remaining);
          for (final match in options) {
            final key = match.group(1);
            final value = match.group(2)?.trim() == 'true';

            switch (key) {
              case 'multiLine':
                multiLine = value;
                break;
              case 'caseSensitive':
                caseSensitive = value;
                break;
              case 'unicode':
                unicode = value;
                break;
              case 'dotAll':
                dotAll = value;
                break;
            }
          }
        }

        result.add(RegExp(
          rawPattern,
          multiLine: multiLine,
          caseSensitive: caseSensitive,
          unicode: unicode,
          dotAll: dotAll,
        ));
      }

      return result;
    }

    List<RegExp> parseRegExpList() {
      // Match all RegExp(...) anywhere in the source (not just extractFilter)
      final reg = extractBalancedBracketContent(source, 'extractFilter');
      if (reg == null) return [];

      final regexlist = extractRegExpBlocks(reg);
      final listBody = parseRegExpListFromStrings(regexlist);

/*       stderr.writeln("///");
      stderr.write("extractFilter: [\n$listBody\n],");
      stderr.writeln("///"); */
      return listBody;
    }

    String parseString(String name) {
      final regex = RegExp('$name:\\s*([\'"])(.*?)\\1', dotAll: true);
      final match = regex.firstMatch(source);
      return match?.group(2) ?? '';
    }

    String parseStringEnum(String name) {
      final regex = RegExp('$name:\\s*([\\w\\.]+)', dotAll: true);
      final match = regex.firstMatch(source);
      return match?.group(1) ?? '';
    }

    TranslationProvider parseEnumFromSource(String key,
        {TranslationProvider fallback = TranslationProvider.gemini}) {
      final value = parseStringEnum(key);
      return TranslationProvider.values.firstWhere(
        (e) => e.toString() == value,
        orElse: () => fallback,
      );
    }

    bool parseBool(String name) {
      final regex = RegExp('$name:\\s*(true|false)', caseSensitive: false);
      final match = regex.firstMatch(source);
      return match?.group(1)?.trim().toLowerCase() == 'true';
    }

    return ExceptionRules(
      textExceptions: parseStringList('textExceptions'),
      lineExceptions: parseStringList('lineExceptions'),
      contentExceptions: parseStringList('contentExceptions'),
      folderExceptions: parseStringList('folderExceptions'),
      extractFilter: parseRegExpList(),
      import: parseStringList('import'),
      key: parseString('key'),
      aiModel: parseEnumFromSource('aiModel'),
      geminiKey: parseString('geminiKey'),
      keyWithVariable: parseString('keyWithVariable'),
      extractOutput: parseString('extractOutput'),
      translate: parseBool('translate'),
    );
  }
}
