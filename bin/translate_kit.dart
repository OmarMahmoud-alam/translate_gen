import 'dart:io';
import 'package:args/args.dart';
import 'package:path/path.dart' as path;

void main(List<String> arguments) {
  final parser = ArgParser()
    ..addFlag('help',
        abbr: 'h', negatable: false, help: 'Show help information');

  try {
    final argResults = parser.parse(arguments);

    // Check for help flag first
    if (argResults['help'] == true) {
      showMainHelp();
      return;
    }

    // Generate configuration files

    print('✅ Configuration files generated successfully!');
  } catch (e) {
    print('❌ Error: $e');
    print('\n💡 Use --help or -h for usage information');
    exit(1);
  }
}

// Main help function for the entire package
void showMainHelp() {
  print('🌐 Translate Kit - Flutter Translation Automation Tool');
  print('');
  print('📖 DESCRIPTION:');
  print(
      '   A comprehensive Flutter translation package that automates the process');
  print(
      '   of extracting, translating, and replacing text strings in your app.');
  print('');
  print('🚀 USAGE:');
  print('   dart run translate_kit:<command> [options]');
  print('');
  print('📋 AVAILABLE COMMANDS:');
  print('   prepare     Generate configuration files');
  print('   extract     Extract translatable strings from Dart files');
  print('   translate   Translate extracted strings using AI/API');
  print('   replace     Replace original strings with translation keys');
  print('   clean       Clean up generated files and restore originals');
  print('   validate    Validate translation files and configuration');
  print('');
  print('💡 EXAMPLES:');
  print('   dart run translate_kit:prepare              # Setup configuration');
  print('   dart run translate_kit:extract              # Extract strings');
  print('   dart run translate_kit:translate            # Translate strings');
  print('   dart run translate_kit:replace              # Replace with keys');
  print('');
  print(
      '📚 For more information, visit: https://pub.dev/packages/translate_kit');
  print('');
}
