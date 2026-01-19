import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/app_constants.dart';

class YouTubeService {
  final String _baseUrl = 'https://www.googleapis.com/youtube/v3';

  Future<Map<String, dynamic>?> getVideoDetails(String videoId) async {
    final url = Uri.parse(
        '$_baseUrl/videos?part=snippet,status&id=$videoId&key=${AppConstants.youtubeApiKey}');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['items'] != null && data['items'].isNotEmpty) {
          final item = data['items'][0];
          final snippet = item['snippet'];
          // final status = item['status']; // Can check if 'live' later

          return {
            'title': snippet['title'],
            'description': snippet['description'],
            // 'channelTitle': snippet['channelTitle'],
            // 'liveBroadcastContent': snippet['liveBroadcastContent'], // 'live', 'upcoming', 'none'
          };
        }
      } else {
        print('YouTube API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('YouTube Service Error: $e');
    }
    return null;
  }
}
