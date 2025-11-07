abstract class LanguageDetector {
  String detectFromFileName(String fileName);

  String detectFromExtension(String extension);

  String detectFromContent(String content);

  List<String> getSupportedLanguages();

  String getFileExtension(String language);
}
