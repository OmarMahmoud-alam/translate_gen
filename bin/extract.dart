import 'dart:io';

import 'package:translate_kit/src/extract/extract.dart';
import 'package:translate_kit/src/utils/generator/generator_exception.dart';
import 'package:translate_kit/src/prepaire_file.dart/create_prepaire_file.dart';
import 'package:translate_kit/src/utils/utils.dart';
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

    final extractor = await Extract.create(folderPath: path);
    final strings = await extractor.extractStringsFromFolder();
    final map = await extractor.generateTranslationMap(strings);
    await extractor.saveTranslations(
        map, 'assets/translationsHelper/${extractor.rules.extractOutput}');
  } on GeneratorException catch (e) {
    exitWithError(e.message);
  } catch (e, trace) {
    stderr.write(trace);
    exitWithError('Failed to generate localization files.\n$e');
  }
}
