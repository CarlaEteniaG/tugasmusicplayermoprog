import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/song.dart';
import '../services/profile_service.dart';

//menampilkan detail lagu serta memutar preview dari iTunes
class PlayerPage extends StatefulWidget {
  final Song song;
  final List<Song> daftarLagu;

  const PlayerPage({super.key, required this.song, this.daftarLagu = const []});

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  final player = AudioPlayer();
  late Song laguSekarang;
  late List<Song> daftarLagu;
  int indexLagu = 0;
  Duration posisi = Duration.zero;
  Duration durasi = Duration.zero;
  bool sedangDiputar = false;
  bool sedangMemuat = false;
  bool sudahDimulai = false;
  bool ulangi = false;
  bool favorit = false;
  bool sedangSimpanFavorit = false;
  String pesan = '';

  StreamSubscription<Duration>? posisiSubscription;
  StreamSubscription<Duration>? durasiSubscription;
  StreamSubscription<PlayerState>? statusSubscription;
  StreamSubscription<void>? selesaiSubscription;

  @override
  void initState() {
    super.initState();
    //untuk mengetahui posisi lagu yang sedang diputar
    daftarLagu = widget.daftarLagu.isEmpty ? [widget.song] : widget.daftarLagu;
    indexLagu = daftarLagu.indexWhere((lagu) => lagu.id == widget.song.id);
    if (indexLagu == -1) {
      daftarLagu = [widget.song];
      indexLagu = 0;
    }
    laguSekarang = daftarLagu[indexLagu];
    cekFavorit();

    //agar suara, progress, durasi, dan tombol mengikuti status audio
    posisiSubscription = player.onPositionChanged.listen((value) {
      if (mounted) {
        setState(() {
          posisi = value;
        });
      }
    });

    durasiSubscription = player.onDurationChanged.listen((value) {
      if (mounted) {
        setState(() {
          durasi = value;
        });
      }
    });

    statusSubscription = player.onPlayerStateChanged.listen((value) {
      if (mounted) {
        setState(() {
          sedangDiputar = value == PlayerState.playing;
        });
      }
    });

    //untuk memutar lagu berikutnya secara otomatis kalau preview selesai
    selesaiSubscription = player.onPlayerComplete.listen((event) async {
      if (!mounted || ulangi) return;
      if (cariIndexLagu(1) != -1) {
        await gantiLagu(1);
      } else {
        setState(() {
          posisi = Duration.zero;
          sedangDiputar = false;
          sudahDimulai = false;
        });
      }
    });
  }

  Future<void> cekFavorit() async {
    final lagu = laguSekarang;
    try {
      final hasil = await ProfileService.sudahFavorit(lagu);
      if (mounted && lagu.id == laguSekarang.id) {
        setState(() {
          favorit = hasil;
        });
      }
    } catch (e) {
      debugPrint('Favorite Error: $e');
    }
  }

  //untuk menyimpan atau menghapus lagu dari halaman favorit
  Future<void> ubahFavorit() async {
    if (sedangSimpanFavorit) return;
    setState(() {
      sedangSimpanFavorit = true;
    });

    try {
      final hasil = await ProfileService.ubahFavorit(laguSekarang);
      if (mounted) {
        setState(() {
          favorit = hasil;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(hasil ? 'Ditambahkan ke favorit' : 'Dihapus dari favorit'),
        ));
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          pesan = 'Gagal menyimpan favorit.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          sedangSimpanFavorit = false;
        });
      }
    }
  }

  //untuk memutar lagu dari previewurl
  Future<void> putarLagu() async {
    final url = laguSekarang.previewUrl;
    if (url.isEmpty) {
      setState(() {
        pesan = 'Preview audio lagu ini tidak tersedia di iTunes.';
      });
      return;
    }
    if (sedangMemuat) return;

    setState(() {
      sedangMemuat = true;
      pesan = '';
    });

    try {
      if (sedangDiputar) {
        await player.pause();
      } else if (sudahDimulai) {
        await player.resume();
      } else {
        await player.play(UrlSource(url));
        if (!mounted) return;
        setState(() {
          sudahDimulai = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          pesan = 'Audio tidak bisa diputar. Coba lagi atau pilih lagu lain.';
          sudahDimulai = false;
          sedangDiputar = false;
        });
      }
      debugPrint('Audio Error: $e');
    } finally {
      if (mounted) {
        setState(() {
          sedangMemuat = false;
        });
      }
    }
  }

  //untuk mencari lagu sebelumnya atau berikutnya yang ada audionya
  int cariIndexLagu(int arah) {
    int tujuan = indexLagu + arah;
    while (tujuan >= 0 && tujuan < daftarLagu.length) {
      if (daftarLagu[tujuan].adaPreview) return tujuan;
      tujuan += arah;
    }
    return -1;
  }

  //untuk pindah lagu tanpa kembali ke halaman search
  Future<void> gantiLagu(int arah) async {
    if (sedangMemuat || sedangSimpanFavorit) return;
    final tujuan = cariIndexLagu(arah);
    if (tujuan == -1) return;

    setState(() {
      sedangMemuat = true;
      pesan = '';
    });

    try {
      await player.stop();
      if (!mounted) return;
      setState(() {
        indexLagu = tujuan;
        laguSekarang = daftarLagu[tujuan];
        posisi = Duration.zero;
        durasi = Duration.zero;
        sedangDiputar = false;
        sudahDimulai = false;
        favorit = false;
      });
      cekFavorit();
      await player.play(UrlSource(laguSekarang.previewUrl));
      if (!mounted) return;
      setState(() {
        sudahDimulai = true;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          pesan = 'Audio tidak bisa diputar. Coba lagi atau pilih lagu lain.';
          sudahDimulai = false;
          sedangDiputar = false;
        });
      }
      debugPrint('Next Song Error: $e');
    } finally {
      if (mounted) {
        setState(() {
          sedangMemuat = false;
        });
      }
    }
  }

  Future<void> stopLagu() async {
    try {
      await player.stop();
      if (mounted) {
        setState(() {
          posisi = Duration.zero;
          sedangDiputar = false;
          sudahDimulai = false;
        });
      }
    } catch (e) {
      debugPrint('Stop Error: $e');
    }
  }

  Future<void> lompatDetik(int detik) async {
    if (!sudahDimulai || durasi == Duration.zero) return;
    var tujuan = posisi + Duration(seconds: detik);
    if (tujuan.isNegative) tujuan = Duration.zero;
    if (tujuan > durasi) tujuan = durasi;
    try {
      await player.seek(tujuan);
    } catch (e) {
      debugPrint('Seek Error: $e');
    }
  }

  Future<void> aturRepeat() async {
    try {
      final nilaiBaru = !ulangi;
      await player.setReleaseMode(
        nilaiBaru ? ReleaseMode.loop : ReleaseMode.release,
      );
      if (mounted) {
        setState(() {
          ulangi = nilaiBaru;
        });
      }
    } catch (e) {
      debugPrint('Repeat Error: $e');
    }
  }

  String formatWaktu(Duration waktu) {
    final menit = waktu.inMinutes;
    final detik = waktu.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$menit:$detik';
  }

  @override
  void dispose() {
    posisiSubscription?.cancel();
    durasiSubscription?.cancel();
    statusSubscription?.cancel();
    selesaiSubscription?.cancel();
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final song = laguSekarang;
    final tahun = song.releaseDate.length >= 4
        ? song.releaseDate.substring(0, 4) : '-';
    final lamaKatalog = Duration(milliseconds: song.trackTimeMillis);
    final batas = durasi.inMilliseconds > 0
        ? durasi.inMilliseconds.toDouble() : 1.0;
    final nilai = posisi.inMilliseconds.toDouble().clamp(0.0, batas).toDouble();
    final lebarLayar = MediaQuery.of(context).size.width;
    final ukuranGambar = lebarLayar * 0.67 > 280.0
        ? 280.0 : lebarLayar * 0.67;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Now Playing'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            tooltip: 'Favorit',
            onPressed: sedangSimpanFavorit ? null : ubahFavorit,
            icon: Icon(favorit ? Icons.favorite : Icons.favorite_border,
                color: favorit ? Colors.pinkAccent : Theme.of(context).colorScheme.onPrimary),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              //mengambil cover lagu dari API
              Container(
                width: ukuranGambar,
                height: ukuranGambar,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: song.artworkUrl100.isEmpty
                      ? Icon(Icons.album, size: 100)
                      : Image.network(song.artworkUrl100,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Icon(Icons.album, size: 100)),
                ),
              ),
              SizedBox(height: 20),
              Text(song.trackName, textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              SizedBox(height: 5),
              Text(song.artistName, textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 17, color: Theme.of(context).colorScheme.onSurfaceVariant)),
              SizedBox(height: 8),
              Text('iTunes Preview',
                  style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.primary)),
              SizedBox(height: 15),
              //membuat progress bar bisa digeser selama audio dijalankan
              Slider(
                value: nilai,
                max: batas,
                activeColor: Color(0xFF243B73),
                onChanged: durasi == Duration.zero || !sudahDimulai
                    ? null : (value) {
                  setState(() {
                    posisi = Duration(milliseconds: value.toInt());
                  });
                },
                onChangeEnd: durasi == Duration.zero || !sudahDimulai
                    ? null : (value) async {
                  try {
                    await player.seek(Duration(milliseconds: value.toInt()));
                  } catch (e) {
                    debugPrint('Seek Error: $e');
                  }
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(formatWaktu(posisi)),
                  Text(formatWaktu(durasi)),
                ],
              ),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    tooltip: 'Ulangi',
                    onPressed: aturRepeat,
                    icon: Icon(Icons.repeat,
                        color: ulangi ? Colors.indigo : Colors.grey),
                  ),
                  IconButton(
                    tooltip: 'Mundur 10 detik',
                    onPressed: () => lompatDetik(-10),
                    icon: Icon(Icons.replay_10, size: 30),
                  ),
                  IconButton(
                    tooltip: sedangDiputar ? 'Pause' : 'Play',
                    onPressed: sedangMemuat ? null : putarLagu,
                    icon: sedangMemuat
                        ? SizedBox(width: 40, height: 40,
                        child: CircularProgressIndicator())
                        : Icon(sedangDiputar ? Icons.pause_circle : Icons.play_circle,
                        size: 58, color: Theme.of(context).colorScheme.primary),
                  ),
                  IconButton(
                    tooltip: 'Maju 10 detik',
                    onPressed: () => lompatDetik(10),
                    icon: Icon(Icons.forward_10, size: 30),
                  ),
                  IconButton(
                    tooltip: 'Stop',
                    onPressed: sedangMemuat ? null : stopLagu,
                    icon: Icon(Icons.stop_circle_outlined, size: 30),
                  ),
                ],
              ),
              //untuk pindah ke lagu sebelumnya dan berikutnya
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    tooltip: 'Lagu sebelumnya',
                    onPressed: sedangMemuat || sedangSimpanFavorit || cariIndexLagu(-1) == -1
                        ? null : () => gantiLagu(-1),
                    icon: Icon(Icons.skip_previous, size: 32),
                  ),
                  SizedBox(width: 30),
                  IconButton(
                    tooltip: 'Lagu berikutnya',
                    onPressed: sedangMemuat || sedangSimpanFavorit || cariIndexLagu(1) == -1
                        ? null : () => gantiLagu(1),
                    icon: Icon(Icons.skip_next, size: 32),
                  ),
                ],
              ),
              if (pesan.isNotEmpty)
                Padding(
                  padding: EdgeInsets.all(10),
                  child: Text(pesan,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.red)),
                ),
              SizedBox(height: 20),
              // TAMBAHAN: deskripsi menggunakan metadata asli dari iTunes.
              Card(
                color: Theme.of(context).colorScheme.surface,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Deskripsi Lagu',
                          style: TextStyle(fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary)),
                      Divider(),
                      Text('Judul: ${song.trackName}'),
                      Text('Penyanyi: ${song.artistName}'),
                      Text('Album: ${song.collectionName.isEmpty ? '-' : song.collectionName}'),
                      Text('Genre: ${song.primaryGenreName.isEmpty ? '-' : song.primaryGenreName}'),
                      Text('Tahun rilis: $tahun'),
                      Text('Durasi lagu asli: ${formatWaktu(lamaKatalog)}'),
                      SizedBox(height: 12),
                      SizedBox(height: 8),
                      Text('Audio preview provided courtesy of iTunes.',
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
