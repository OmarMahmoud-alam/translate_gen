import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;

void createPrepaireFiles({String baseDir = ''}) {
  try {
    final dir = Directory(p.join(baseDir, 'assets', 'translationsHelper'));
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    final prepairePath = p.join(dir.path, 'prepaire.json');
    final replacePath = p.join(dir.path, 'replace.json');

    final prepaireContent = {
      "textExceptions": ["import"],
      "lineExceptions": ["line_start_to_skip"],
      "contentExceptions": ["substring_to_skip"],
      "folderExceptions": [""],
      "extractFilter": [
        "[']([\\u0600-\\u06FF].*?)[']",
        "[\"]([\\u0600-\\u06FF].*?)[\"]"
      ],
      "import": ["import 'package:easy_localization/easy_localization.dart';"],
      "key": "'{key}'.tr()",
      "keyWithVariable": "'{key}'.tr(args: [{args}])"
    };

    File(prepairePath).writeAsStringSync(_prettyJson(prepaireContent));
    File(replacePath).writeAsStringSync('{}');

    stderr.writeln('✅ Prepaire files created at: ${dir.path}');
  } catch (e) {
    stderr.writeln('❌ Error creating prepaire files: $e');
  }
}

String _prettyJson(Map<String, dynamic> json) {
  return JsonEncoder.withIndent('  ').convert(json);
}
