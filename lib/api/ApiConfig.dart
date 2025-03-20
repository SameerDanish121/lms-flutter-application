class ApiConfig {
  static String _apiBaseUrl = 'http://192.168.0.108:8000/api/'; // Default URL
  // Getter for the API base URL
  static String get apiBaseUrl => _apiBaseUrl;
  static set apiBaseUrl(String newUrl) {
    _apiBaseUrl = newUrl;
  }
}
