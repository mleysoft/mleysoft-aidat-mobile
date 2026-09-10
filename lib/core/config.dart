class AppConfig {
  static const apiBase = String.fromEnvironment(
    'API_BASE',
    defaultValue: 'https://mleysoft.com/system/aidat/api/mobile',
  );
  static const lime = 0xFFB9FF00;
  static String get webRoot => apiBase.replaceFirst(RegExp(r'/api/mobile/?$'), '');
  static String legalUrl(String page) => '$webRoot/$page';
  static String webSessionUrl(String token) => '$apiBase/web-session.php?token=${Uri.encodeQueryComponent(token)}';
}
