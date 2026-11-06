import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/song.dart';

class ProfileService {
  static Box get settingsBox => Hive.box('settings');

  static Future<Map<String, String>> ambilProfil() async {
    return {
      'nama': settingsBox.get('username', defaultValue: 'Carla Etenia Gunawidjaja').toString(),
      'email': settingsBox.get('email', defaultValue: 'carla.825240127@stu.untar.ac.id').toString(),
    };
  }

  static Future<void> simpanEmail(String email) async {
    await settingsBox.put('email', email.trim());
  }

  static Future<List<Song>> ambilFavorit() async {
    final data = settingsBox.get('lagu_favorit', defaultValue: <String>[]);
    final daftar = List<String>.from(data is List ? data : []);
    List<Song> hasil = [];

    for (final isi in daftar) {
      try {
        final lagu = jsonDecode(isi);
        if (lagu is Map<String, dynamic>) {
          hasil.add(Song.fromJson(lagu));
        }
      } catch (e) {
        //membuat data favorit lain tetap dibaca ketika salah satu JSON tidak valid
      }
    }
    return hasil;
  }

  static Future<bool> sudahFavorit(Song song) async {
    final daftar = await ambilFavorit();
    return daftar.any((item) => item.id == song.id);
  }

  static Future<bool> ubahFavorit(Song song) async {
    final daftar = await ambilFavorit();
    final index = daftar.indexWhere((item) => item.id == song.id);
    final menjadiFavorit = index == -1;

    if (menjadiFavorit) {
      daftar.add(song);
    } else {
      daftar.removeAt(index);
    }

    await settingsBox.put('lagu_favorit',
        daftar.map((item) => jsonEncode(item.toJson())).toList());
    return menjadiFavorit;
  }
}
