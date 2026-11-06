import 'package:flutter/material.dart';
import '../models/song.dart';
import '../services/profile_service.dart';
import 'player_page.dart';

class ProfilePage extends StatefulWidget {
  final String username;
  final bool isDarkMode;
  final Future<void> Function(String) onSave;
  final Future<void> Function(bool) onThemeChanged;

  const ProfilePage({
    super.key,
    required this.username,
    required this.isDarkMode,
    required this.onSave,
    required this.onThemeChanged,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late TextEditingController controller;
  final emailController = TextEditingController(); //kolom email
  List<Song> laguFavorit = []; //daftar lagu favorit
  String username = '';
  bool isDarkMode = false;
  bool isLoading = true;
  bool isEditing = false;
  bool sedangMenyimpan = false;
  String pesan = '';

  @override
  void initState() {
    super.initState();
    username = widget.username;
    isDarkMode = widget.isDarkMode;
    controller = TextEditingController(text: widget.username);
    loadData();
  }

  //mengambil email dan favorit. Nama dan dark mode dari hive
  Future<void> loadData() async {
    try {
      final profil = await ProfileService.ambilProfil();
      final favorit = await ProfileService.ambilFavorit();
      if (!mounted) return;
      setState(() {
        emailController.text = profil['email'] ?? '';
        laguFavorit = favorit;
        isLoading = false;
        pesan = '';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        pesan = 'Gagal mengambil data profil. Coba lagi.';
      });
      debugPrint('Profile Error: $e');
    }
  }

  // menyimpan nama dan email dari controller
  Future<void> simpanProfil() async {
    final name = controller.text.trim();
    final email = emailController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nama tidak boleh kosong')),
      );
      return;
    }
    if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Format email belum benar')),
      );
      return;
    }

    setState(() {
      sedangMenyimpan = true;
    });

    try {
      await widget.onSave(name); // saveUsername() dari Catatan MoProg
      await ProfileService.simpanEmail(email);
      if (!mounted) return;
      setState(() {
        username = name;
        isEditing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profil berhasil disimpan')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan profil')),
      );
      debugPrint('Save Profile Error: $e');
    } finally {
      if (mounted) {
        setState(() {
          sedangMenyimpan = false;
        });
      }
    }
  }

  //untuk membuka lagu favorit dengan Navigator.push()
  Future<void> bukaLagu(Song song) async {
    await Navigator.push(context, MaterialPageRoute(
      builder: (context) => PlayerPage(song: song, daftarLagu: laguFavorit),
    ));
    if (!mounted) return;
    await loadData();
  }

  @override
  void dispose() {
    controller.dispose();
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Profile'),
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
            tooltip: 'Refresh favorit',
            onPressed: loadData,
            icon: Icon(Icons.refresh),
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SafeArea(
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [ //profil
              Align(
                alignment: Alignment.topCenter,
                child: Container(
                  width: double.infinity,
                  margin: EdgeInsets.all(20),
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isSmallWidth = constraints.maxWidth < 600;

                      final avatar = CircleAvatar(
                        radius: 40,
                        child: ClipOval(
                          child: Image.asset(
                            'assets/me.jpg',
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(Icons.person, size: 48);
                            },
                          ),
                        ),
                      );

                      final profileDetails = Column(
                        crossAxisAlignment: isSmallWidth
                            ? CrossAxisAlignment.center
                            : CrossAxisAlignment.start,
                        children: [
                          Text(
                            username.isEmpty ? 'Selamat datang!' : username,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 6),
                          Text(
                            emailController.text,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: isSmallWidth
                                ? MainAxisAlignment.center
                                : MainAxisAlignment.start,
                            children: [
                              Icon(Icons.location_on, size: 16, color: Colors.red),
                              SizedBox(width: 4),
                              Text('Jakarta, Indonesia',
                                  style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer)),
                            ],
                          ),
                        ],
                      );

                      if (isSmallWidth) {
                        return Column(
                          children: [
                            avatar,
                            SizedBox(height: 15),
                            profileDetails,
                          ],
                        );
                      } else {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            avatar,
                            SizedBox(width: 15),
                            Expanded(child: profileDetails),
                          ],
                        );
                      }
                    },
                  ),
                ),
              ),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    //tombol edit profile
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            isEditing = !isEditing;
                          });
                        },
                        icon: Icon(Icons.edit, size: 18),
                        label: Text(isEditing ? 'Tutup Edit Profile' : 'Edit Profile'),
                      ),
                    ),
                    if (isEditing)
                      Card(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            children: [
                              SizedBox(height: 8),
                              TextField(
                                controller: controller,
                                decoration: InputDecoration(
                                  labelText: 'Nama Pengguna',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              SizedBox(height: 12),
                              TextField(
                                controller: emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  labelText: 'Email',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: sedangMenyimpan ? null : simpanProfil,
                                child: Text('Simpan Profil'),
                              ),
                            ],
                          ),
                        ),
                      ),

                    SizedBox(height: 15),
                    //darkmode
                    SwitchListTile(
                      title: Text('Mode Gelap'),
                      subtitle: Text('Pilihan tema disimpan'),
                      value: isDarkMode,
                      onChanged: (value) async {
                        try {
                          await widget.onThemeChanged(value);
                          if (!mounted) return;
                          setState(() {
                            isDarkMode = value;
                          });
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Gagal menyimpan tema')),
                          );
                        }
                      },
                    ),
                    Divider(height: 32),
                    Row(
                      children: [
                        Icon(Icons.favorite, color: Colors.pinkAccent),
                        SizedBox(width: 8),
                        Text('Lagu Favorit (${laguFavorit.length})',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    SizedBox(height: 10),
                    if (laguFavorit.isEmpty)
                      Card(
                        child: Padding(
                          padding: EdgeInsets.all(18),
                          child: Text('Belum ada lagu favorit. Buka detail lagu dan tekan ikon hati.'),
                        ),
                      ),
                    //daftar lagu favorit dari penyimpanan hive.
                    ...laguFavorit.map((song) {
                      return Card(
                        child: ListTile(
                          leading: song.artworkUrl100.isEmpty
                              ? Icon(Icons.music_note)
                              : Image.network(song.artworkUrl100,
                              width: 45, height: 45, fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Icon(Icons.music_note)),
                          title: Text(song.trackName,
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text(song.artistName,
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          trailing: Icon(Icons.chevron_right),
                          onTap: () => bukaLagu(song),
                        ),
                      );
                    }),
                    if (pesan.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(pesan, style: TextStyle(color: Colors.red)),
                      ),
                    SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
