import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:translate_gen/src/translate/phrase_translator.dart';

class OpenRouterTranslator implements PhraseTranslator {
  final String apiKey;
  final String modelName;

  OpenRouterTranslator({required this.apiKey, required this.modelName});

  @override
  Future<List<String>> translate(List<String> phrases) async {
    stderr.write('Translating ${phrases.length} phrases via OpenRouter...\n');

    final uri = Uri.parse('https://openrouter.ai/api/v1/chat/completions');

    final joinedPhrases = phrases
        .asMap()
        .entries
        .map((entry) => '${entry.key + 1}. ${entry.value}')
        .join('\n');

    final instruction = '''
You are a tool that converts Arabic phrases into valid Flutter (Dart) variable names.

Your task:
- For each Arabic phrase below, translate its meaning to English
- Convert each into a valid camelCase variable name (e.g., "Order Details" → orderDetails)
- Do not return any special characters, numbers at the start, or spaces
- Avoid Dart reserved words like "class", "new", etc.
- Output only the variable names in a numbered list, one per line, and in the same order.

Arabic phrases:
$joinedPhrases
''';

    final headers = {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
    };

    final payload = {
      "model": modelName,
      "messages": [
        {"role": "user", "content": instruction}
      ]
    };

    final response =
        await http.post(uri, headers: headers, body: jsonEncode(payload));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final text = data['choices'][0]['message']['content'] as String;
      return _extractVariableNames(text);
    } else {
      print('OpenRouter translation failed: ${response.body}');
      return phrases;
    }
  }

  @override
  Future<List<String>> englishKey(List<String> phrases) async {
    stderr.write('Translating ${phrases.length} phrases via OpenRouter...\n');

    final uri = Uri.parse('https://openrouter.ai/api/v1/chat/completions');

    final joinedPhrases = phrases
        .asMap()
        .entries
        .map((entry) => '${entry.key + 1}. ${entry.value}')
        .join('\n');

    final instruction = '''
You are a tool that converts English phrases into valid Dart variable names.

Instructions:
- For each English phrase listed below:
  1. Understand its meaning.
  2. Create a descriptive camelCase variable name based on that meaning.
- The generated variable names must:
  - Use camelCase formatting (e.g., "Order Details" → orderDetails)
  - Contain only English letters (no special characters, numbers at the beginning, or spaces)
  - Avoid using any Dart reserved keywords (e.g., "class", "new", etc.)
- Return only the final variable names, formatted as a numbered list, one per line, and in the same order.

English phrases:
$joinedPhrases
''';

    final headers = {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
    };

    final payload = {
      "model": modelName,
      "messages": [
        {"role": "user", "content": instruction}
      ]
    };

    final response =
        await http.post(uri, headers: headers, body: jsonEncode(payload));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final text = data['choices'][0]['message']['content'] as String;
      return _extractVariableNames(text);
    } else {
      print('OpenRouter translation failed: ${response.body}');
      return phrases;
    }
  }

  List<String> _extractVariableNames(String response) {
    return LineSplitter.split(response)
        .map((line) => line.trim())
        .where((line) => RegExp(r'^\d+\.\s').hasMatch(line))
        .map((line) => line
            .replaceFirst(RegExp(r'^\d+\.\s*'), '')
            .replaceAll('`', '')
            .trim())
        .toList();
  }
}
