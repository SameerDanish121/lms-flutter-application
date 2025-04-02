class ApiConfig {

  static String _apiBaseUrl = 'http://192.168.0.108:8000/api/';

  static String get apiBaseUrl => _apiBaseUrl;

  static set apiBaseUrl(String newUrl) {
    _apiBaseUrl = newUrl;
  }
}
