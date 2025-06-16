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
    try {
      final file =
          File(p.join('assets', 'translationsHelper', 'prepaire.dart'));
      if (!await file.exists()) {
        throw Exception('prepaire.dart not found at ${file.path}');
      }

      final content = await file.readAsString();
      return _parseDartConfig(content);
      //final jsonMap = json.decode(content);
      // return ExceptionRules.fromJson(jsonMap);}
    } catch (e, trace) {
      stderr.write(trace);
      throw Exception('Failed to load exception rules: $e');
    }
  }

  static ExceptionRules _parseDartConfig(String dartCode) {
    // Extract the ExceptionRules constructor arguments
    final startIndex = dartCode.indexOf('ExceptionRules(');
    if (startIndex == -1)
      throw Exception('ExceptionRules not found in Dart file');

    final endIndex = dartCode.lastIndexOf(');');
    if (endIndex == -1)
      throw Exception('Malformed ExceptionRules in Dart file');

    final argsString =
        dartCode.substring(startIndex + 'ExceptionRules('.length, endIndex);

    // Convert to a Map (now handles RegExp and lists properly)
    final argsMap = _parseDartArgsToMap(argsString);

    return ExceptionRules.fromJson(argsMap);
  }

  static Map<String, dynamic> _parseDartArgsToMap(String argsString) {
    // This is a simplified parser (for exact parsing, consider using `package:analyzer`)
    final argsMap = <String, dynamic>{};

    // Example: Split by commas (naive approach)
    final argPairs = argsString.split(',');
    for (final pair in argPairs) {
      final parts = pair.split(':');
      if (parts.length != 2) continue;

      final key = parts[0].trim();
      final value = parts[1].trim();

      // Basic parsing (extend for lists, RegExp, etc.)
      if (value.startsWith('[') &&
          value.endsWith(']') &&
          key != 'extractFilter') {
        // Parse lists
        final items = value
            .substring(1, value.length - 1)
            .split(',')
            .map((e) => e.trim())
            .toList();

        argsMap[key] = items;
      } else if (key == 'extractFilter') {
        // Parse RegExp
        final items = value
            .substring(1, value.length - 1)
            .split('),')
            .map((e) => _parseRegExp(e.trim()))
            .toList();
        argsMap[key] = items;
      } else {
        argsMap[key] = value;
      }
      if (key == 'extractFilter') {
        stderr.write(argsMap[key]);
      }
    }

    return argsMap;
  }

  static RegExp _parseRegExp(String regExpStr) {
    // Extract inner content: RegExp( ... )
    final innerContent =
        regExpStr.substring('RegExp('.length, regExpStr.length - 1).trim();
    final parts = innerContent.split(',');
    final innerContentList = parts.map((e) => e.trim()).toList();
    stderr.write(innerContent);
    // Check for raw string (r'...') or normal string ('...')

    if (innerContentList.isEmpty) {
      throw FormatException('Invalid RegExp pattern: $regExpStr');
    }

    final pattern = innerContentList[0];
    final flagsPart = innerContentList.sublist(1);

    // Parse flags (multiLine: true, caseSensitive: false, etc.)
    bool multiLine = false;
    bool caseSensitive = true;
    bool unicode = false;
    bool dotAll = false;

   
      for (final flag in flagsPart) {
        final parts = flag.split(':').map((e) => e.trim()).toList();
        
      
      }
    

    return RegExp(
      pattern,
      multiLine: multiLine,
      caseSensitive: caseSensitive,
      unicode: unicode,
      dotAll: dotAll,
    );
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
        final regExp = filter;
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
    final uri = Uri.parse(
        'https://api.mymemory.translated.net/get?q=$text&langpair=ar|en');
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final translated = data['responseData']['translatedText'] ?? text;
      return translated;
    } else {
      stderr
          .write('Translation failed for "$text"\n${response.body.toString()}');
      print('Translation failed for "$text"');
      return text;
    }
  }
}
