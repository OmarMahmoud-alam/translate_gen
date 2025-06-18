import 'package:translate_kit/src/utils/generator/generator_exception.dart';
import 'package:translate_kit/src/prepaire_file.dart/create_prepaire_file.dart';
import 'package:translate_kit/src/utils/utils.dart';
import 'package:args/args.dart';

Future<void> main(List<String> args) async {
  try {
    final parser = ArgParser()
      ..addOption('type', abbr: 't', help: 'Project base path');

    final result = parser.parse(args);
    final path = result['path'] ?? 'normal';
    if (path == null) {
      print('Please pass --path=<your_project_path>');
      return;
    }

    var generator = createPrepaireFiles();

    //await generator.generateAsync();
  } on GeneratorException catch (e) {
    exitWithError(e.message);
  } catch (e) {
    exitWithError('Failed to generate localization files.\n$e');
  }
}
