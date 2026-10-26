import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:path_provider/path_provider.dart';

import 'golgol.dart';

class Track {
  final String id;
  String title;
  String artist;
  String album;
  final String path;
  String? coverPath;
  String lrc;
  final bool builtin;
  final bool external; // 기기에 원래 있던 파일 (지워도 파일은 남김)
  final int added;
  int durationMs;

  Track({
    required this.id,
    required this.title,
    required this.artist,
    this.album = '',
    required this.path,
    this.coverPath,
    this.lrc = '',
    this.builtin = false,
    this.external = false,
    required this.added,
    this.durationMs = 0,
  });

  String get albumName => album.isEmpty ? '앨범 정보 없음' : album;
  String get folder {
    final i = path.lastIndexOf('/');
    if (i <= 0) return '/';
    final d = path.substring(0, i);
    final j = d.lastIndexOf('/');
    return j < 0 ? d : d.substring(j + 1);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'artist': artist,
        'album': album,
        'path': path,
        'cover': coverPath,
        'lrc': lrc,
        'external': external,
        'added': added,
        'dur': durationMs,
      };

  factory Track.fromJson(Map<String, dynamic> j) => Track(
        id: j['id'] as String,
        title: (j['title'] ?? '') as String,
        artist: (j['artist'] ?? '') as String,
        album: (j['album'] ?? '') as String,
        path: j['path'] as String,
        coverPath: j['cover'] as String?,
        lrc: (j['lrc'] ?? '') as String,
        external: (j['external'] ?? false) as bool,
        added: ((j['added'] ?? 0) as num).toInt(),
        durationMs: ((j['dur'] ?? 0) as num).toInt(),
      );
}

class Playlist {
  final String id;
  String name;
  List<String> trackIds;
  Playlist({required this.id, required this.name, List<String>? trackIds}) : trackIds = trackIds ?? [];

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'tracks': trackIds};
  factory Playlist.fromJson(Map<String, dynamic> j) => Playlist(
        id: j['id'] as String,
        name: (j['name'] ?? '플레이리스트') as String,
        trackIds: List<String>.from((j['tracks'] ?? const []) as List),
      );
}

class Store {
  late Directory root;
  late Directory musicDir;
  late Directory coverDir;

  Future<void> init() async {
    root = await getApplicationDocumentsDirectory();
    musicDir = Directory('${root.path}/music');
    coverDir = Directory('${root.path}/covers');
    await musicDir.create(recursive: true);
    await coverDir.create(recursive: true);
  }

  File _file(String n) => File('${root.path}/$n');

  Future<dynamic> readJson(String n) async {
    try {
      final f = _file(n);
      if (!await f.exists()) return null;
      return jsonDecode(await f.readAsString());
    } catch (_) {
      return null;
    }
  }

  Future<void> writeJson(String n, Object v) async {
    try {
      final tmp = _file('$n.tmp');
      await tmp.writeAsString(jsonEncode(v), flush: true);
      await tmp.rename(_file(n).path);
    } catch (_) {}
  }

  Future<String> ensureGolgol() async {
    final f = _file('golgol_v1.wav');
    if (!await f.exists()) {
      final bytes = await Isolate.run(makeGolgolWav);
      await f.writeAsBytes(bytes, flush: true);
    }
    return f.path;
  }
}
