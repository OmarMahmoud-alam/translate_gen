import 'package:translate_kit/src/utils/generator/generator_exception.dart';
import 'package:translate_kit/src/prepaire_file.dart/create_prepaire_file.dart';
import 'package:translate_kit/src/utils/utils.dart';
import 'package:args/args.dart';

Future<void> main(List<String> args) async {
  try {
    final parser = ArgParser()
      ..addOption(
        'type',
        abbr: 't',
        help: 'Configuration type (normal or easy)',
        allowed: ['normal', 'easy'],
        defaultsTo: 'easy',
      );

    final results = parser.parse(args);

    final type = results['type']; // Should work for both -t and --type
    print('Type: $type');
    if (type == null) {
      print('Please pass --type=<your_project_path>');
      return;
    }

    var generator = createPrepaireFiles(type: type);

    //await generator.generateAsync();
  } on GeneratorException catch (e) {
    exitWithError(e.message);
  } catch (e) {
    exitWithError('Failed to generate localization files.\n$e');
  }
}
