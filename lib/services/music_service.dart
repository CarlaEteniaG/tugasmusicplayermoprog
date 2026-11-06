import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/song.dart';

class MusicService {
  final http.Client client = http.Client();

  Future<List<Song>> cariLagu(String kataKunci) async {
    final url = Uri.https('itunes.apple.com',
      '/search',
      <String, String>{
        'term': kataKunci.trim(),
        'limit': '10',
        'entity': 'song',
      },
    );

    final response = await client.get(url).timeout(Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('HTTP Error: ${response.statusCode}');
    }

    final data = jsonDecode(response.body);
    if (data is! Map<String, dynamic> || data['results'] is! List) {
      throw FormatException('Format JSON dari iTunes tidak sesuai.');
    }

    final hasil = data['results'] as List;
    return hasil
        .whereType<Map>()
        .map((item) => Song.fromJson(Map<String, dynamic>.from(item)))
        .where((song) => song.trackName.isNotEmpty)
        .toList();
  }

  void dispose() {
    client.close();
  }
}
