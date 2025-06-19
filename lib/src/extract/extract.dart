import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:translate_gen/src/extract/exception_rules.dart';
import 'package:http/http.dart' as http;
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:translate_gen/src/span_print/span.dart';
import 'package:translate_gen/src/translate/translation_provider.dart';
import 'package:translate_gen/src/translate/translator_factory.dart';

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

    // Clean and classify
    final arabicList = <String>[];
    final passthroughList = <String>[];

    for (final s in strings) {
      final str = s.trim().replaceAll(RegExp(r'''^['"]|['"]$'''), '');
      if (_isArabic(str) &&
          rules.translate &&
          (rules.aiModel != TranslationProvider.gemini ||
              rules.geminiKey.isNotEmpty)) {
        arabicList.add(str);
      } else {
        passthroughList.add(str);
      }
    }

    // Step 1: Deduplicate
    final uniqueArabic = arabicList.toSet().toList();

    // Step 2: Translate in batches
    const int batchSize = 12;
    final uniqueTranslations = <String>[];
    final spinner = Spinner("Translating'");
    // spinner.start();
    for (int i = 0; i < uniqueArabic.length; i += batchSize) {
      final batch = uniqueArabic.sublist(
        i,
        i + batchSize > uniqueArabic.length
            ? uniqueArabic.length
            : i + batchSize,
      );

      final translator = TranslatorFactory.create(
        provider: rules.aiModel,
        apiKey: rules.geminiKey,
      );

      final result = await translator.translate(batch);
      uniqueTranslations.addAll(result);
    }

    // Step 3: Build translation cache
    final cache = <String, String>{};
    for (int i = 0; i < uniqueTranslations.length; i++) {
      final key =
          uniqueTranslations[i].replaceAll(RegExp(r'\s+'), '_').toLowerCase();
      cache[uniqueArabic[i]] = key;
    }

    // Step 4: Fill final map from original Arabic list (use cache)
    for (final arabic in arabicList) {
      final key = cache[arabic]!;
      map[key] = arabic;
    }

    // Step 5: Add passthroughs
    for (final str in passthroughList) {
      final key = str.replaceAll(RegExp(r'\s+'), '_').toLowerCase();
      map[key] = str;
    }
    spinner.stop();

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

  String generateShortKey2(String text) {
    // Step 1: Remove variables like $maxImages or ${...}
    text = text.replaceAll(RegExp(r'\$\w+'), '');
    text = text.replaceAll(RegExp(r'[{}]'), '');

    // Step 2: Remove all special characters, including . , : etc.
    text = text.replaceAll(RegExp(r'[^\w\s]'), '');

    // Step 3: Lowercase and split into words
    final words = text.trim().toLowerCase().split(RegExp(r'\s+|_+'));

    // Step 4: Filter out common stopwords
    const stopwords = {
      'only',
      'you',
      'this',
      'that',
    };
    final filtered =
        words.where((w) => w.isNotEmpty && !stopwords.contains(w)).toList();

    // Step 5: Join the first 2–3 important words
    String joined = filtered.take(5).join('_');

    // Step 6: Fallback to short hash if empty or too long
    /*  if (joined.isEmpty || joined.length > 12) {
      return md5.convert(utf8.encode(text)).toString().substring(0, 8);
    } */
    return joined;
  }
}
