class ExceptionRules {
  List<String> textExceptions;
  List<String> lineExceptions;
  List<String> contentExceptions;
  List<String> folderExceptions;
  List<String> import;
  List<RegExp> extractFilter;
  String key;
  String keyWithVariable;

  ExceptionRules({
    required this.textExceptions,
    required this.lineExceptions,
    required this.contentExceptions,
    required this.folderExceptions,
    required this.import,
    required this.extractFilter,
    required this.key,
    required this.keyWithVariable,
  });

  factory ExceptionRules.fromJson(Map<String, dynamic> json) {
    return ExceptionRules(
      textExceptions: List<String>.from(json['textExceptions'] ?? []),
      lineExceptions: List<String>.from(json['lineExceptions'] ?? []),
      contentExceptions: List<String>.from(json['contentExceptions'] ?? []),
      folderExceptions: List<String>.from(json['folderExceptions'] ?? []),
      import: List<String>.from(json['import'] ?? []),
      extractFilter: List<RegExp>.from(json['extractFilter'] ?? []),
      key: json['key'] ?? '',
      keyWithVariable: json['keyWithVariable'] ?? '',
    );
  }
}
