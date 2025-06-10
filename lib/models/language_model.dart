class Language {
  final String name;
  final String code;
  final List<String> speakers;
  final String defaultSpeaker;

  Language({
    required this.name,
    required this.code,
    required this.speakers,
    required this.defaultSpeaker,
  });

  factory Language.fromJson(Map<String, dynamic> json) {
    return Language(
      name: '',
      code: json['code'] ?? '',
      speakers: List<String>.from(json['speakers'] ?? []),
      defaultSpeaker: json['default_speaker'] ?? '',
    );
  }
}

class TranslationResult {
  final String englishText;
  final String translatedText;
  final String audioUrl;
  final String language;
  final String speaker;

  TranslationResult({
    required this.englishText,
    required this.translatedText,
    required this.audioUrl,
    required this.language,
    required this.speaker,
  });

  factory TranslationResult.fromJson(Map<String, dynamic> json) {
    return TranslationResult(
      englishText: json['english_text'] ?? '',
      translatedText: json['translated_text'] ?? '',
      audioUrl: json['audio_url'] ?? '',
      language: json['language'] ?? '',
      speaker: json['speaker'] ?? '',
    );
  }
}
