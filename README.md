# translate_kit Package

This package provides tools to assist with translation tasks in Flutter projects, including preparing configuration files, extracting translatable strings, and replacing them based on a configuration.

## Installation

Add the following to your `pubspec.yaml`:

```yaml
dev_dependencies:
  translate_kit: ^1.0.0
```
or 

```yaml
dev_dependencies:
  translate_kit:
    git:
      url: https://github.com/OmarMahmoud-alam/translate_kit.git
```
Run `flutter pub get` to install the package.

## Commands

### 1. Prepare Configuration 

The `prepare` command generates a configuration file (`prepare.dart`) and an empty `replace.json` file under the `assets/translate_kit` directory. You can choose between two configuration types: **normal** or **easy** (for easy_localization package).

**Command:** 

```bash
flutter pub run translate_kit:prepare
```

**Command with Options:**

```bash
# For normal translation setup
flutter pub run translate_kit:prepare --type normal

# For easy_localization package setup (default)
flutter pub run translate_kit:prepare --type easy
```

**Output:** 

- Creates `assets/translate_kit/prepare.dart` with the following content:

**For Easy Localization (default):**
```dart
import 'package:translate_kit/src/extract/exception_rules.dart';

final translationConfig = ExceptionRules(
  textExceptions: ['import'],
  lineExceptions: ['line_start_to_skip'],
  contentExceptions: ['substring_to_skip'],
  folderExceptions: [''],
  extractFilter: [
    RegExp(r"'[^']*[\u0600-\u06FF][^']*'"),
    RegExp(r'"[^"]*[\u0600-\u06FF][^"]*"')
  ],
  "import": [
    "import 'package:easy_localization/easy_localization.dart';",
    "import 'package:{{projectName}}/core/app_strings/locale_keys.dart';"
  ],
  "key": " LocaleKeys.{key}.tr()",
  "keyWithVariable": "LocaleKeys.{key}.tr(args: [{args}])"
  translate: true,
);
```

**For Normal Translation:**
```dart
import 'package:translate_kit/src/extract/exception_rules.dart';

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
  key: s.current.{key},
  keyWithVariable: s.current.{key}({args}), //not work in flutter_localization only in easy_localization
  translate: true,
);
```

- Creates `assets/translate_kit/replace.json` as an empty JSON file: 

```json
{}
```

**Purpose:** 

This command sets up the necessary configuration for the translation process, defining rules for exceptions, filters for extracting translatable strings (e.g., Arabic text), and the format for translation keys. 

- **Easy type**: Configured for use with the `easy_localization` package, including the necessary import and `.tr()` method calls
- **Normal type**: Basic configuration without external package dependencies, suitable for custom translation implementations
### 2. Extract Translatable Strings

The `extract` command scans the specified path (or default path) for translatable strings and generates key-value pairs to be stored in `replace.json`.

**Command:**
```bash
flutter pub run translate_kit:extract [--path='lib/core']
```

**Parameters:**
- `--path`: Optional. Specifies the directory to scan for translatable strings. Defaults to `lib/core` if not provided.

**Output:**
- Updates `assets/translate_kit/en2.json` with extracted strings in the format:

```json
{
  "key1": "translatable string 1",
  "key2": "translatable string 2"
}
```

**Purpose:** This command identifies strings (e.g., Arabic text matching the regex patterns in `prepare.dart`) and prepares them for translation by storing them in `replace.json`.

### 3. Replace Strings

The `replace` command replaces strings in the specified path (or default path) with translation keys based on the content of `replace.json`.

**Command:**
```bash
flutter pub run translate_kit:replace [--path='lib/core']
```

**Parameters:**
- `--path`: Optional. Specifies the directory where strings will be replaced. Defaults to `lib/core` if not provided.

**Behavior:**
- Reads `replace.json` to get key-value pairs
- Replaces matching strings in the specified path with translation keys in the format defined in `prepare.dart` (e.g., `'{key}'.tr()` or `'{key}'.tr(args: [{args}])` for strings with variables)
- Adds necessary import statements (e.g., `import 'package:easy_localization/easy_localization.dart';`) to files as specified in the configuration

**Purpose:** This command automates the replacement of hard-coded strings with translation keys, enabling easy localization using the `easy_localization` package.

## Directory Structure

After running the `prepare` command, the following structure is created:

```
assets/
└── translate_kit/
    ├── en2.json
    ├── prepare.dart
    └── replace.json
```

## Notes

- The `extractFilter` in `prepare.dart` is configured to detect Arabic strings (Unicode range `\u0600-\u06FF`). Modify the regex patterns to support other languages if needed
- The `en2.json` file is overwritten during the `extract` command, so back up any manual changes before running it
- Before running the `replace` command, make sure `replace.json` has the following content (with at least an empty object `{}`):