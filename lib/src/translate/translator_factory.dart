import 'package:translate_gen/src/translate/gemini_translator.dart';
import 'package:translate_gen/src/translate/open_router_translator.dart';
import 'package:translate_gen/src/translate/phrase_translator.dart';
import 'package:translate_gen/src/translate/translation_provider.dart';

class TranslatorFactory {
  static PhraseTranslator create({
    required TranslationProvider provider,
    required String apiKey,
  }) {


    switch (provider) {
      case TranslationProvider.gemini:
        return GeminiTranslator(apiKey: apiKey);
      case TranslationProvider.kimiDev72b:
        return OpenRouterTranslator(
          apiKey: apiKey, modelName: provider.modelname);
      case TranslationProvider.deepseekR1:
        return OpenRouterTranslator(
            apiKey: apiKey, modelName: provider.modelname);
    }
  }
}
