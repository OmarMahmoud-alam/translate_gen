enum TranslationProvider {
  gemini,
  kimiDev72b,
  deepseekR1,
}

extension TranslationProviderExtension on TranslationProvider {
  String get modelname {
    switch (this) {
      case TranslationProvider.gemini:
        return 'gemini-2.5-flash';
      case TranslationProvider.kimiDev72b:
        return 'moonshotai/kimi-dev-72b:free';
      case TranslationProvider.deepseekR1:
        return 'deepseek/deepseek-r1-0528:free';
    }
  }
}
