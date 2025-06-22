# translate_gen Package

This package provides tools to assist with translation tasks in Flutter projects, including preparing configuration files, extracting translatable strings, and replacing them based on a configuration. It supports multiple AI translation providers including Gemini and DeepSeek R1.

## Installation

Add the following to your `pubspec.yaml`:

```yaml
dev_dependencies:
  translate_gen: ^1.0.5
```

Run `flutter pub get` to install the package.

## Commands

### 1. Prepare Configuration 

The `prepare` command generates a configuration file (`prepare.dart`) and an empty `replace.json` file under the `assets/translate_gen` directory. You can choose between two configuration types: **normal** or **easy** (for easy_localization package).

**Command:** 

```bash
flutter pub run translate_gen:prepare
```

**Command with Options:**

```bash
# For normal translation setup
flutter pub run translate_gen:prepare --type normal

# For easy_localization package setup (default)
flutter pub run translate_gen:prepare --type easy
```

**Output:** 

- Creates `assets/translate_gen/prepare.dart` with the following content:

**For Easy Localization (default):**
```dart
import 'package:translate_gen/src/extract/exception_rules.dart';
import 'package:translate_gen/src/translate/translation_provider.dart';

final translationConfig = ExceptionRules(
  textExceptions: ['import'],
  lineExceptions: ['line_start_to_skip'],
  contentExceptions: ['substring_to_skip'],
  folderExceptions: [''],
  extractFilter: [
    RegExp(r"'[^']*[\u0600-\u06FF][^']*'"),
    RegExp(r'"[^"]*[\u0600-\u06FF][^"]*"')
  ],
  import: [
    "import 'package:easy_localization/easy_localization.dart';",
    "import 'package:$projectName/core/app_strings/locale_keys.dart';"
  ],
  key: "LocaleKeys.{key}.tr()",
  keyWithVariable: "LocaleKeys.{key}.tr(args: [{args}])",
  translate: true,
  extractOutput: 'replace.json',
  aiKey: '', // Required only when using TranslationProvider.gemini
  aiModel: TranslationProvider.deepseekR1, // Available options: gemini, deepseekR1
);
```

**For Normal Translation:**
```dart
import 'package:translate_gen/src/extract/exception_rules.dart';
import 'package:translate_gen/src/translate/translation_provider.dart';

final translationConfig = ExceptionRules(
  textExceptions: ['import'],
  lineExceptions: ['line_start_to_skip'],
  contentExceptions: ['substring_to_skip'],
  folderExceptions: [''],
  extractFilter: [
    RegExp(r"'[^']*[\u0600-\u06FF][^']*'"),
    RegExp(r'"[^"]*[\u0600-\u06FF][^"]*"')
  ],
  import: [],
  key: "s.current.{key}",
  keyWithVariable: "s.current.{key}({args})", //not work in flutter_localization only in easy_localization
  translate: true,
  extractOutput: 'replace.json',
  aiKey: '', // Required only when using TranslationProvider.gemini
  aiModel: TranslationProvider.deepseekR1, // Available options: gemini, deepseekR1
);
```

- Creates `assets/translate_gen/replace.json` as an empty JSON file: 

```json
{}
```

**Purpose:** 

This command sets up the necessary configuration for the translation process, defining rules for exceptions, filters for extracting translatable strings (e.g., Arabic text), and the format for translation keys. 

- **Easy type**: Configured for use with the `easy_localization` package, including the necessary import and `.tr()` method calls
- **Normal type**: Basic configuration without external package dependencies, suitable for custom translation implementations

## AI Translation Configuration

The package supports multiple AI translation providers:

### Available AI Models

- **TranslationProvider.deepseekR1**: DeepSeek R1 model (default)
- **TranslationProvider.gemini**: Google Gemini model

### Gemini Configuration

When using Google Gemini as your AI model, you must provide a valid API key:

1. Set the `aiModel` to `TranslationProvider.gemini`
2. Add your Gemini API key to the `aiKey` field

**Example configuration for Gemini:**
```dart
final translationConfig = ExceptionRules(
  // ... other configuration ...
  aiKey: 'your-gemini-api-key-here',
  aiModel: TranslationProvider.gemini,
);
```

**Note:** The `aiKey` field is only required when using `TranslationProvider.gemini`. You can leave it empty when using other AI models.

### 2. Extract Translatable Strings

The `extract` command scans the specified path (or default path) for translatable strings and generates key-value pairs to be stored in `replace.json`.

**Command:**
```bash
flutter pub run translate_gen:extract [--path='lib/core']
```

**Parameters:**
- `--path`: Optional. Specifies the directory to scan for translatable strings. Defaults to `lib/core` if not provided.

**Output:**
- Updates `assets/translate_gen/replace.json` with extracted strings in the format:

```json
{
  "key1": "translatable string 1",
  "key2": "translatable string 2"
}
```

**Purpose:** This command identifies strings (e.g., Arabic text matching the regex patterns in `prepare.dart`) and prepares them for translation by storing them in `replace.json`. The AI model specified in the configuration will be used for automatic translation.

### 3. Replace Strings

The `replace` command replaces strings in the specified path (or default path) with translation keys based on the content of `replace.json`.

**Command:**
```bash
flutter pub run translate_gen:replace [--path='lib/core']
```

**Parameters:**
- `--path`: Optional. Specifies the directory where strings will be replaced. Defaults to `lib/core` if not provided.

**Behavior:**
- Reads `replace.json` to get key-value pairs
- Replaces matching strings in the specified path with translation keys in the format defined in `prepare.dart` (e.g., `LocaleKeys.{key}.tr()` or `LocaleKeys.{key}.tr(args: [{args}])` for strings with variables)
- Adds necessary import statements (e.g., `import 'package:easy_localization/easy_localization.dart';`) to files as specified in the configuration

**Purpose:** This command automates the replacement of hard-coded strings with translation keys, enabling easy localization using the `easy_localization` package.

## Directory Structure

After running the `prepare` command, the following structure is created:

```
assets/
└── translate_gen/
    ├── prepare.dart
    └── replace.json
```

## Configuration Parameters

### ExceptionRules Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `textExceptions` | `List<String>` | Text patterns to exclude from extraction |
| `lineExceptions` | `List<String>` | Line patterns to skip during extraction |
| `contentExceptions` | `List<String>` | Content substrings to skip |
| `folderExceptions` | `List<String>` | Folders to exclude from scanning |
| `extractFilter` | `List<RegExp>` | Regex patterns to match translatable strings |
| `import` | `List<String>` | Import statements to add to files |
| `key` | `String` | Format for translation keys |
| `keyWithVariable` | `String` | Format for translation keys with variables |
| `translate` | `bool` | Enable/disable automatic translation |
| `extractOutput` | `String` | Output file for extracted strings |
| `aiKey` | `String` | API key for Gemini (required only for Gemini) |
| `aiModel` | `TranslationProvider` | AI model to use for translation |

## Notes

- The `extractFilter` in `prepare.dart` is configured to detect Arabic strings (Unicode range `\u0600-\u06FF`). Modify the regex patterns to support other languages if needed
- The `replace.json` file is overwritten during the `extract` command, so back up any manual changes before running it
- Before running the `replace` command, make sure `replace.json` has the following content (with at least an empty object `{}`)
- When using Gemini, ensure you have a valid API key from Google AI Studio
- DeepSeek R1 is the default AI model and doesn't require additional API key configuration
- The AI translation feature requires an internet connection to communicate with the selected AI provider