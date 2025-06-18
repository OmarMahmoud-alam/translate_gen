import 'package:translate_gen/src/extract/extract.dart';
import 'package:translate_gen/src/replace/replace.dart';
import 'package:translate_gen/src/utils/generator/generator_exception.dart';
import 'package:translate_gen/src/utils/utils.dart';
import 'package:args/args.dart';

Future<void> main(List<String> args) async {
  try {
    final parser = ArgParser()
      ..addOption('path', abbr: 'p', help: 'Project base path');

    final result = parser.parse(args);
    final path = result['path'] ?? 'lib';
    if (path == null) {
      print('Please pass --path=<your_project_path>');
      return;
    }

    final replace = Replace(
        baseDir: '',
        rules: await Extract.loadExceptionRules(path),
        folderPath: path);
    await replace.process();
    print('✅ Replaced stringsw in files at: $path');
  } on GeneratorException catch (e) {
    exitWithError(e.message);
  } catch (e) {
    exitWithError('Failed to generate localization files.\n$e');
  }
}
