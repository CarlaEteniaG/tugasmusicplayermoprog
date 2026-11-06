import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/song.dart'; //model data JSON lagu
import 'services/music_service.dart'; //HTTP dan parsing JSON
import 'pages/player_page.dart'; //halaman pemutar lagu
import 'pages/profile_page.dart'; //halaman profil

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('settings');
  runApp(const MyThemeApp());
}

class MyThemeApp extends StatefulWidget {
  const MyThemeApp({super.key});

  @override
  State<MyThemeApp> createState() => _MyThemeAppState();
}

class _MyThemeAppState extends State<MyThemeApp> {
  String username = '';
  bool isDarkMode = false;
  bool isLoading = true;

  late Box settingsBox;

  @override
  void initState() {
    super.initState();
    settingsBox = Hive.box('settings');
    loadData();
  }

  //untuk membaca nama pengguna dan tema dari hive
  Future<void> loadData() async {
    setState(() {
      username = settingsBox.get('username', defaultValue: 'Carla Etenia Gunawidjaja');
      isDarkMode = settingsBox.get('isDarkMode', defaultValue: false);
      isLoading = false;
    });
  }

  //untuk menyimpan nama lewat Hive
  Future<void> saveUsername(String name) async {
    await settingsBox.put('username', name);

    setState(() {
      username = name;
    });
  }

  //membuat perubahan tema tetap tersimpan saat aplikasinya ditutup
  Future<void> changeTheme(bool value) async {
    await settingsBox.put('isDarkMode', value);

    setState(() {
      isDarkMode = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.blue,
        brightness: Brightness.dark,
      ),
      home: isLoading
          ? Scaffold(body: Center(child: CircularProgressIndicator()))
          : MyApp(
        username: username,
        isDarkMode: isDarkMode,
        onSave: saveUsername,
        onThemeChanged: changeTheme,
      ),
    );
  }
}

class MyApp extends StatefulWidget {
  final String username;
  final bool isDarkMode;
  final Future<void> Function(String) onSave;
  final Future<void> Function(bool) onThemeChanged;

  const MyApp({
    super.key,
    required this.username,
    required this.isDarkMode,
    required this.onSave,
    required this.onThemeChanged,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final controller = TextEditingController();
  List songs= [];

  //untuk mengatur loading dan pesan error saat mencari lagu
  final musicService = MusicService();
  bool sedangMencari = false;
  bool hanyaAdaPreview = false;
  String pesan = 'Ketik judul lagu atau nama penyanyi untuk mulai mencari.';
  String pesanError = '';

  Future<void> cariLagu() async {
    if (sedangMencari) return;
    if (controller.text.trim().isEmpty) {
      setState(() {
        songs = [];
        pesan = 'Masukkan judul lagu atau artist terlebih dahulu.';
        pesanError = '';
      });
      return;
    }

    setState(() {
      sedangMencari = true;
      pesan = '';
      pesanError = '';
    });

    try {
      final hasil = await musicService.cariLagu(controller.text);
      if (!mounted) return;

      setState(() {
        songs = hasil;
        pesan = songs.isEmpty ? 'Lagu tidak ditemukan. Coba kata kunci lain.' : '';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        songs = [];
        pesanError = 'Gagal mengambil lagu. Periksa internet dan coba lagi.';
      });
      debugPrint('HTTP Error: $e');
    } finally {
      if (mounted) {
        setState(() {
          sedangMencari = false;
        });
      }
    }
  }

  //untuk menutup controller dan koneksi HTTP saat halaman dibuang
  @override
  void dispose() {
    controller.dispose();
    musicService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //menfilter lagu yang memiliki audio preview
    final List<Song> laguDitampilkan = songs
        .whereType<Song>()
        .where((lagu) => !hanyaAdaPreview || lagu.adaPreview)
        .toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Music Player'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          //untuk refresh data dari API tanpa memulai aplikasi ulang
          IconButton(
            tooltip: 'Refresh lagu',
            onPressed: sedangMencari ? null : cariLagu,
            icon: Icon(Icons.refresh),
          ),
          //ke halaman ketiga menggunakan Navigator.push()
          IconButton(
            tooltip: 'Profil',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (context) => ProfilePage(
                  username: widget.username,
                  isDarkMode: widget.isDarkMode,
                  onSave: widget.onSave,
                  onThemeChanged: widget.onThemeChanged,
                ),
              ));
            },
            icon: Icon(Icons.person_outline),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            //header
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Temukan lagu favoritmu',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onPrimaryContainer)),
                  SizedBox(height: 5),
                  Text('Cari di iTunes dan dengarkan cuplikan audionya.',
                      style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer)),
                ],
              ),
            ),
            SizedBox(height: 14),
            TextField(
              controller: controller,
              onSubmitted: (_) => cariLagu(),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                labelText:'Judul lagu atau artist',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
            ),
            SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: sedangMencari ? null : cariLagu,
                icon: Icon(Icons.search),
                label: Text('cari lagu'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: EdgeInsets.all(13),
                ),
              ),
            ),
            SizedBox(height: 8),
            //untuk menampilkan hanya lagu yang bisa diputar
            Row(
              children: [
                Expanded(
                  child: CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text('Hanya lagu dengan audio',
                        style: TextStyle(fontSize: 13)),
                    value: hanyaAdaPreview,
                    onChanged: (value) {
                      setState(() {
                        hanyaAdaPreview = value ?? false;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ),
                Text('${laguDitampilkan.length} lagu',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ],
            ),
            if (sedangMencari) LinearProgressIndicator(),
            if (pesanError.isNotEmpty)
              Padding(
                padding: EdgeInsets.all(10),
                child: Column(
                  children: [
                    Text(pesanError,
                        style: TextStyle(color: Colors.red),
                        textAlign: TextAlign.center),
                    TextButton(onPressed: cariLagu, child: Text('Coba lagi')),
                  ],
                ),
              ),
            if (pesan.isNotEmpty)
              Padding(
                padding: EdgeInsets.all(12),
                child: Text(pesan, textAlign: TextAlign.center),
              ),
            if (!sedangMencari && songs.isNotEmpty && laguDitampilkan.isEmpty)
              Padding(
                padding: EdgeInsets.all(10),
                child: Text('Tidak ada lagu dengan preview pada hasil ini.'),
              ),
            Expanded(child:
            //untuk bisa menarik daftar ke bawah untuk refresh
            RefreshIndicator(
              onRefresh: cariLagu,
              child: ListView.builder(
                  physics: AlwaysScrollableScrollPhysics(),
                  itemCount: laguDitampilkan.length,
                  itemBuilder: (context, index) {
                    final Song song = laguDitampilkan[index];
                    return Card(
                      color: Theme.of(context).colorScheme.surface,
                      margin: EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: song.artworkUrl100.isEmpty
                              ? Container(width: 54, height: 54,
                              color: Theme.of(context).colorScheme.primaryContainer,
                              child: Icon(Icons.music_note))
                              : Image.network(song.artworkUrl100,
                              width: 54, height: 54, fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(Icons.music_note, size: 40)),
                        ),
                        title: Text(song.trackName,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(song.artistName,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: Icon(Icons.chevron_right),
                        //mengirim data Song ke halaman detail
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(
                            builder: (context) => PlayerPage(song: song, daftarLagu: laguDitampilkan),
                          ));
                        },
                      ),
                    );
                  }),
            ),
            )
          ],
        ),
      ),
    );
  }
}
