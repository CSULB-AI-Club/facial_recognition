class ApiConfig {
  static const String serverIP = '10.232.232.101';
  static const int serverPort = 5001;
  static const String baseUrl = 'http://$serverIP:$serverPort';

  // Get full URL for a specific endpoint
  static String getUrl(String endpoint) {
    // Remove leading slash if present
    if (endpoint.startsWith('/')) {
      endpoint = endpoint.substring(1);
    }
    final url = '$baseUrl/$endpoint';
    print("API URL: $url"); // Debug print
    return url;
  }
} 