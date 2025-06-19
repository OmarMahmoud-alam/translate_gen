import 'package:translate_gen/src/translate/gemini_translator.dart';
import 'package:translate_gen/src/translate/open_router_translator.dart';
import 'package:translate_gen/src/translate/phrase_translator.dart';
import 'package:translate_gen/src/translate/translation_provider.dart';

class TranslatorFactory {
  static PhraseTranslator create({
    required TranslationProvider provider,
    required String apiKey,
  }) {
    final deepSeekApi =
        "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";

    switch (provider) {
      case TranslationProvider.gemini:
        return GeminiTranslator(apiKey: apiKey);
      case TranslationProvider.kimiDev72b:
        return OpenRouterTranslator(
            apiKey: deepSeekApi, modelName: provider.modelname);
      case TranslationProvider.deepseekR1:
        return OpenRouterTranslator(
            apiKey: deepSeekApi, modelName: provider.modelname);
    }
  }
}
