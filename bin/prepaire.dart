import 'package:translate_kit/src/utils/generator/generator_exception.dart';
import 'package:translate_kit/src/prepaire_file.dart/create_prepaire_file.dart';
import 'package:translate_kit/src/utils/utils.dart';

Future<void> main(List<String> args) async {
  try {
    var generator = createPrepaireFiles();
    //await generator.generateAsync();
  } on GeneratorException catch (e) {
    exitWithError(e.message);
  } catch (e) {
    exitWithError('Failed to generate localization files.\n$e');
  }
}
