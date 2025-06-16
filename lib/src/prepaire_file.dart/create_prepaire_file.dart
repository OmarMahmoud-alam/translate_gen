import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;

void createPrepaireFiles({String baseDir = ''}) {
  try {
    final dir = Directory(p.join(baseDir, 'assets', 'translationsHelper'));
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    final prepairePath = p.join(dir.path, 'prepaire.dart');
    final replacePath = p.join(dir.path, 'replace.json');

    // File(prepairePath).writeAsStringSync(_prettyJson(prepaireContent));
    File(replacePath).writeAsStringSync('{}');
    writeDartConfig(prepairePath);
    stderr.writeln('✅ Prepaire files created at: ${dir.path}');
  } catch (e) {
    stderr.writeln('❌ Error creating prepaire files: $e');
  }
}

String _prettyJson(Map<String, dynamic> json) {
  return JsonEncoder.withIndent('  ').convert(json);
}

void writeDartConfig(String path) {
  final content = '''
import 'package:translatehelper/src/extract/exception_rules.dart';

final translationConfig = ExceptionRules(
  textExceptions: ['import'],
  lineExceptions: ['line_start_to_skip'],
  contentExceptions: ['substring_to_skip'],
  folderExceptions: [''],
  extractFilter: [
    RegExp(r"'[\\u0600-\\u06FF].*?'", multiLine: true),
    RegExp(r'"[\\u0600-\\u06FF].*?"', multiLine: true),
  ],
  import: ["import 'package:easy_localization/easy_localization.dart';"],
  key: "'{key}'.tr()",
  keyWithVariable: "'{key}'.tr(args: [{args}])",
);
''';

  File(path).writeAsStringSync(content);
}
