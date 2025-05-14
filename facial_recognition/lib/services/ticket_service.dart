import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:facial_recognition/config/api_config.dart';

class TicketService {
  // Activate a ticket for a specific duration
  static Future<Map<String, dynamic>> activateTicket(String ticketId, String userId, {int durationMinutes = 5}) async {
    final url = '${ApiConfig.getUrl('activate_ticket_temporary')}';
    
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'ticket_id': ticketId,
          'user_id': userId,
          'duration_minutes': durationMinutes
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to activate ticket');
      }
    } catch (e) {
      throw Exception('Error activating ticket: $e');
    }
  }
} 