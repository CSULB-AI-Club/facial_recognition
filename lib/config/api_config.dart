class ApiConfig {
  static const String serverIP = '192.168.1.66';
  static const int serverPort = 5001;
  static const String baseUrl = 'http://$serverIP:$serverPort';

  // Get full URL for a specific endpoint
  static String getUrl(String endpoint) {
    // Remove leading slash if present
    if (endpoint.startsWith('/')) {
      endpoint = endpoint.substring(1);
    }
    return '$baseUrl/$endpoint';
  }
} 