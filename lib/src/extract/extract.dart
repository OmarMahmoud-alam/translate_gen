import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:translate_kit/src/extract/exception_rules.dart';
import 'package:http/http.dart' as http;
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:crypto/crypto.dart';

class Extract {
  String baseDir;
  late ExceptionRules rules;
  String folderPath;
  Extract._(this.baseDir, this.rules, this.folderPath);

  static Future<Extract> create(
      {String baseDir = '', String folderPath = 'lib'}) async {
    final rules = await loadExceptionRules(baseDir);
    return Extract._(baseDir, rules, folderPath);
  }

  static Future<ExceptionRules> loadExceptionRules(String baseDir) async {
    try {
      final file =
          File(p.join('assets', 'translationsHelper', 'prepaire.dart'));
      if (!await file.exists()) {
        throw Exception('prepaire.dart not found at ${file.path}');
      }

      final content = await file.readAsString();
      final result = parseString(content: content);
      final unit = result.unit;

      for (final declaration in unit.declarations) {
        if (declaration is TopLevelVariableDeclaration) {
          for (final variable in declaration.variables.variables) {
            final name = variable.name.lexeme;
            if (name == 'translationConfig') {
              final initializer = variable.initializer;
              if (initializer != null) {
                //  stderr.write(initializer.toSource());
                return ExceptionRules.fromSourceString(initializer.toSource());
              }
            }
          }
        }
      }

      throw Exception('can not find translationConfig');
    } catch (e, trace) {
      stderr.write(trace);
      throw Exception('Failed to load exception rules: $e');
    }
  }

  Future<List<String>> extractStringsFromFolder() async {
    List<String> strings = [];

    final entities = Directory(folderPath).listSync(recursive: true);
    for (final entity in entities) {
      if (entity is File && entity.path.endsWith('.dart')) {
        final relativeParts =
            p.split(p.relative(entity.path, from: folderPath));
        if (relativeParts
            .any((part) => rules.folderExceptions.contains(part))) {
          continue;
        }

        strings.addAll(await extractStringsFromFile(
          entity,
        ));
      }
    }
    // stderr.write("extractedStrings  $strings");

    return strings;
  }

  Future<List<String>> extractStringsFromFile(File file) async {
    final content = await file.readAsLines();
    final extractedStrings = <String>[];
    //stderr.write(rules.extractFilter);
    for (final line in content) {
      if (line.startsWith('import') ||
          rules.lineExceptions.any((exc) => line.startsWith(exc))) {
        continue;
      }
      Iterable<String> matches;

      if (rules.extractFilter.isEmpty) {
        final regex = RegExp(r'''(["'])(?:(?=(\\?))\2.)*?\1''');
        matches = regex.allMatches(line).map((m) => m.group(0)!).toList();
      } else {
        matches = rules.extractFilter.expand((filter) {
          return filter
              .allMatches(line)
              .map((m) => m.groupCount >= 1 ? m.group(1)! : m.group(0)!);
        });
      }

      final filtered = matches.where((str) =>
          !rules.textExceptions.contains(str) &&
          !rules.contentExceptions.any((exc) => str.contains(exc)));

      extractedStrings.addAll(filtered);
    }

    return extractedStrings;
  }

  Future<Map<String, String>> generateTranslationMap(
      List<String> strings) async {
    final map = <String, String>{};

    for (final s in strings) {
      final str = s.trim().replaceAll(RegExp(r'''^['"]|['"]$'''), '');
      String key;

      if (_isArabic(str) && rules.translate) {
        key = await _translateToEnglish(str);
      } else {
        key = str;
      }

      key = key.replaceAll(RegExp(r'\s+'), '_').toLowerCase();
      map[key] = str;
    }

    return map;
  }

  bool _isArabic(String text) {
    final arabicRegex = RegExp(r'[\u0621-\u064A]');
    return arabicRegex.hasMatch(text);
  }

  Future<void> saveTranslations(
      Map<String, String> translations, String outputPath) async {
    final file = File(outputPath);
    final dir = file.parent;
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final existing =
        await file.exists() ? json.decode(await file.readAsString()) : {};
    final combined = {...existing, ...translations};

    await file.writeAsString(JsonEncoder.withIndent('  ').convert(combined));
  }

  Future<String> _translateToEnglish(String text) async {
    stderr.write('Translating "$text" to English...\n');
    final uri = Uri.parse(
        'https://api.mymemory.translated.net/get?q=$text&langpair=ar|en');
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final translated = data['responseData']['translatedText'] ?? text;
      return translated;
    } else {
      //  stderr
      //    .write('Translation failed for "$text"\n${response.body.toString()}');
      print('Translation failed ${response.body.toString()}');
      return generateShortKey(text);
    }
  }

  String generateShortKey(String text) {
    // Clean text: remove $, { }, ., :, etc.
    final cleaned = text
        .replaceAll(RegExp(r'[\$\{\}\.\:\(\)\[\]]'), '')
        .replaceAll(RegExp(r'[^\w\s]'), '');

    // Lowercase + split
    final words = cleaned.trim().toLowerCase().split(RegExp(r'\s+'));

    // Common stopwords to skip
    const stopwords = {
      'a',
      'the',
      'is',
      'to',
      'of',
      'and',
      'in',
      'on',
      'up',
      'only',
      'can',
      'you'
    };

    // Keep important words
    final filtered = words.where((w) => !stopwords.contains(w)).toList();

    // Join up to 3 words
    String joined = filtered.take(3).join('_');

    // If too long or empty, fallback to hash
    if (joined.isEmpty || joined.length > 12) {
      final bytes = utf8.encode(text);
      final digest = md5.convert(bytes).toString(); // 32 chars
      return digest.substring(0, 8);
    }

    return joined;
  }
}
