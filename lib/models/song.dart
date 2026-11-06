//MODEL: mengubah JSON dari iTunes menjadi data lagu yang mudah digunakan
class Song {
  final String id;
  final String trackName;
  final String artistName;
  final String collectionName;
  final String primaryGenreName;
  final String releaseDate;
  final String artworkUrl100;
  final String previewUrl;
  final String trackViewUrl;
  final int trackTimeMillis;

  const Song({
    required this.id,
    required this.trackName,
    required this.artistName,
    required this.collectionName,
    required this.primaryGenreName,
    required this.releaseDate,
    required this.artworkUrl100,
    required this.previewUrl,
    required this.trackViewUrl,
    required this.trackTimeMillis,
  });

  //mengubah nilai yang tidak ada di JSON menjadi 0
  factory Song.fromJson(Map<String, dynamic> json) {
    String teks(String key) => json[key]?.toString() ?? '';
    final durasi = json['trackTimeMillis'];
    final durasiAngka = durasi is num
        ? durasi.toInt()
        : int.tryParse(durasi?.toString() ?? '') ?? 0;

    return Song(
      id: teks('trackId').isNotEmpty
          ? teks('trackId')
          : '${teks('artistName')}-${teks('trackName')}',
      trackName: teks('trackName'),
      artistName: teks('artistName'),
      collectionName: teks('collectionName'),
      primaryGenreName: teks('primaryGenreName'),
      releaseDate: teks('releaseDate'),
      artworkUrl100: teks('artworkUrl100'),
      previewUrl: teks('previewUrl'),
      trackViewUrl: teks('trackViewUrl'),
      trackTimeMillis: durasiAngka,
    );
  }

  //untuk menyimpan lagu favorit di hp
  Map<String, dynamic> toJson() {
    return {
      'trackId': id,
      'trackName': trackName,
      'artistName': artistName,
      'collectionName': collectionName,
      'primaryGenreName': primaryGenreName,
      'releaseDate': releaseDate,
      'artworkUrl100': artworkUrl100,
      'previewUrl': previewUrl,
      'trackViewUrl': trackViewUrl,
      'trackTimeMillis': trackTimeMillis,
    };
  }

  bool get adaPreview => previewUrl.trim().isNotEmpty;
}
