import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:translatehelper/src/extract/exception_rules.dart';
import 'package:http/http.dart' as http;

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
    final file = File(p.join('assets', 'translationsHelper', 'prepaire.json'));
    if (!await file.exists()) {
      throw Exception('prepaire.json not found at ${file.path}');
    }

    final content = await file.readAsString();
    final jsonMap = json.decode(content);
    return ExceptionRules.fromJson(jsonMap);
  }

  Future<List<String>> extractStringsFromFolder() async {
    List<String> strings = [];

    final entities = Directory(folderPath).listSync(recursive: true);
    for (final entity in entities) {
      if (entity is File && entity.path.endsWith('.dart')) {
        final relativeParts =
            p.split(p.relative(entity.path, from: folderPath));
        if (relativeParts.any((part) => rules.folderExceptions.contains(part)))
          continue;

        strings.addAll(await extractStringsFromFile(
          entity,
        ));
      }
    }

    return strings;
  }

  Future<List<String>> extractStringsFromFile(File file) async {
    final content = await file.readAsLines();
    final extractedStrings = <String>[];

    for (final line in content) {
      if (line.startsWith('import') ||
          rules.lineExceptions.any((exc) => line.startsWith(exc))) {
        continue;
      }

      final matches = rules.extractFilter.expand((filter) {
        final regExp = RegExp(filter, multiLine: true);
        return regExp.allMatches(line).map((m) => m.group(1) ?? '');
      });

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
      String key;

      if (_isArabic(s)) {
        key = await _translateToEnglish(s);
      } else {
        key = s;
      }

      key = key.replaceAll(RegExp(r'\s+'), '_').toLowerCase();
      map[key] = s;
    }

    return map;
  }

  bool _isArabic(String text) {
    final arabicRegex = RegExp(r'[^\u0621-\u064A0-9a-zA-Z]+');
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
    final response = await http.post(
      Uri.parse('https://libretranslate.com/translate'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'q': text,
        'source': 'ar',
        'target': 'en',
        'format': 'text',
      }),
    );

    // final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      return data['translatedText'] ?? text;
    } else {
      print('Translation failed for "$text"');
      return text;
    }
  }
}
