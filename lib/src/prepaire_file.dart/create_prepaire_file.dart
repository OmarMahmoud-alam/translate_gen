import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

void createPrepaireFiles({String baseDir = '', String type = 'normal'}) async {
  try {
    final dir = Directory(p.join(baseDir, 'assets', 'translationsHelper'));
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    final prepairePath = p.join(dir.path, 'prepaire.dart');
    final replacePath = p.join(dir.path, 'replace.json');

    final pubspec = File(p.join(baseDir, 'pubspec.yaml'));
    final yaml = loadYaml(await pubspec.readAsString());
    final projectName = yaml['name'];

    final replaceFile = File(replacePath);
    replaceFile.writeAsStringSync('{"projectName": "$projectName"}');
    if (type != 'normal') {
      writeEasyLocalizationDartConfig(prepairePath, projectName);
    } else {
      writeNormalLocalizationDartConfig(prepairePath);
    }
    stderr.writeln('✅ Prepaire files created at: ${dir.path}');
  } catch (e) {
    stderr.writeln('❌ Error creating prepaire files: $e');
  }
}

void writeEasyLocalizationDartConfig(String path, String projectName) {
  final content = '''
import 'package:translate_kit/src/extract/exception_rules.dart';

final translationConfig = ExceptionRules(
  textExceptions: ['import'],
  lineExceptions: ['line_start_to_skip'],
  contentExceptions: ['substring_to_skip'],
  folderExceptions: [''],
  extractFilter: [
    RegExp(r"'[^']*[\u0600-\u06FF][^']*'"), //  RegExp(r"'[^']*[\u0600-\u06FF][^']*'"),
    RegExp(r'"[^"]*[\u0600-\u06FF][^"]*"') //    RegExp(r'"[^"]*[\u0600-\u06FF][^"]*"')

  ],
  import: [
    "import 'package:easy_localization/easy_localization.dart';",
    "import 'package:$projectName/core/app_strings/locale_keys.dart';"
  ],
  key:  "LocaleKeys.{key}.tr()",
  keyWithVariable: "LocaleKeys.{key}.tr(args: [{args}])",
  translate: true,
  extractOutput: 'replace.json',

);
''';

  File(path).writeAsStringSync(content);
}

void writeNormalLocalizationDartConfig(String path) {
  final content = '''
import 'package:translate_kit/src/extract/exception_rules.dart';

final translationConfig = ExceptionRules(
  textExceptions: ['import'],
  lineExceptions: ['line_start_to_skip'],
  contentExceptions: ['substring_to_skip'],
  folderExceptions: [''],
  extractFilter: [
    RegExp(r"'[^']*[\u0600-\u06FF][^']*'"),//  RegExp(r"'[^']*[\u0600-\u06FF][^']*'"),
    RegExp(r'"[^"]*[\u0600-\u06FF][^"]*"')//    RegExp(r'"[^"]*[\u0600-\u06FF][^"]*"')
  ],
  import: [
    "import 'package:flutter_localization/flutter_localization.dart';",
  ],
  key:  "s.current.{key}",
  keyWithVariable:" s.current.{key}({args})", //not work in flutter_localization only in easy_localization
  translate: true,
 extractOutput: 'replace.json',

);
''';

  File(path).writeAsStringSync(content);
}
