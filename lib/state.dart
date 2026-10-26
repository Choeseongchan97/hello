import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:permission_handler/permission_handler.dart';

import 'golgol.dart';
import 'id3.dart';
import 'lrc.dart';
import 'models.dart';

final messengerKey = GlobalKey<ScaffoldMessengerState>();
late AppState app;

const audioExts = {'mp3', 'm4a', 'aac', 'wav', 'ogg', 'oga', 'opus', 'flac', 'wma', 'amr'};
const eqLabels = ['60', '230', '910', '3.6k', '14k'];
const eqPresets = <String, List<double>>{
  '기본': [0, 0, 0, 0, 0],
  '베이스 쿵쿵': [6, 4, 0, -1, 1],
  '보컬 또렷': [-2, 0, 3, 4, 2],
  '골골 포근': [3, 2, 0, -2, -4],
  '반짝 고음': [-1, 0, 1, 4, 6],
  '클래식': [4, 2, -1, 2, 4],
  '록': [5, 2, -2, 3, 5],
};
const sortNames = {'added': '추가한 순', 'title': '제목 순', 'artist': '가수 순', 'album': '앨범 순'};

String ext(String p) {
  final i = p.lastIndexOf('.');
  return i < 0 ? '' : p.substring(i + 1).toLowerCase();
}

String baseName(String p) {
  final s = p.split('/').last;
  final i = s.lastIndexOf('.');
  return i <= 0 ? s : s.substring(0, i);
}

String fmtDur(Duration d) {
  final s = d.inSeconds;
  final h = s ~/ 3600;
  final m = (s % 3600) ~/ 60;
  final ss = (s % 60).toString().padLeft(2, '0');
  return h > 0 ? '$h:${m.toString().padLeft(2, '0')}:$ss' : '$m:$ss';
}

class AppState extends ChangeNotifier {
  final store = Store();
  late final AudioPlayer player;
  AndroidEqualizer? eq;
  AndroidEqualizerParameters? eqParams;

  List<Track> tracks = [];
  final Map<String, Track> _byId = {};
  List<Playlist> playlists = [];
  Set<String> favorites = {};
  Map<String, int> playCounts = {};
  Map<String, int> lastPlayed = {};

  // 지금 재생 목록
  List<String> queue = [];
  List<int> order = [];
  int idx = -1;
  String queueName = '전체 노래';

  bool shuffle = false;
  int repeat = 1; // 0 끔, 1 전체, 2 한 곡
  double speed = 1.0;
  int volume = 80; // 0~100
  Map<String, double> offsets = {};
  List<double> eqGains = [0, 0, 0, 0, 0];
  String? eqPreset = '기본';
  bool eqOn = true;
  String sortMode = 'added';

  List<LyricLine> lyrics = const [];
  Duration? abA, abB;
  Timer? sleepTimer;
  DateTime? sleepAt;
  bool sleepAfterTrack = false;
  bool _counted = false;
  bool scanning = false;
  Timer? _saveT;

  Track? byId(String id) => _byId[id];
  Track? get current {
    if (idx < 0 || idx >= order.length) return null;
    final q = order[idx];
    if (q < 0 || q >= queue.length) return null;
    return _byId[queue[q]];
  }

  double get offset => offsets[current?.id] ?? 0;

  void say(String m) {
    messengerKey.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(m), duration: const Duration(milliseconds: 1800)));
  }

  void _reindex() {
    _byId
      ..clear()
      ..addEntries(tracks.map((t) => MapEntry(t.id, t)));
  }

  // ---------------- 시작 ----------------
  Future<void> init() async {
    if (Platform.isAndroid) {
      eq = AndroidEqualizer();
      player = AudioPlayer(audioPipeline: AudioPipeline(androidAudioEffects: [eq!]));
    } else {
      player = AudioPlayer();
    }
    await store.init();
    final golPath = await store.ensureGolgol();
    tracks = [
      Track(
        id: 'golgol',
        title: '르냥골골송',
        artist: '르냥이',
        album: '르냥뮤직스 오리지널',
        path: golPath,
        lrc: golgolLrc,
        builtin: true,
        added: 0,
        durationMs: 52000,
      ),
    ];
    final saved = await store.readJson('library.json');
    if (saved is List) {
      for (final e in saved) {
        try {
          tracks.add(Track.fromJson(Map<String, dynamic>.from(e as Map)));
        } catch (_) {}
      }
    }
    _reindex();
    final pl = await store.readJson('playlists.json');
    if (pl is List) {
      for (final e in pl) {
        try {
          playlists.add(Playlist.fromJson(Map<String, dynamic>.from(e as Map)));
        } catch (_) {}
      }
    } else {
      playlists = [Playlist(id: 'p_default', name: '르냥이 최애곡', trackIds: ['golgol'])];
    }
    String? lastId;
    final s = await store.readJson('settings.json');
    if (s is Map) {
      shuffle = (s['shuffle'] ?? false) as bool;
      repeat = ((s['repeat'] ?? 1) as num).toInt();
      speed = ((s['speed'] ?? 1.0) as num).toDouble();
      volume = math.max(0, math.min(100, ((s['volume'] ?? 80) as num).toInt()));
      sortMode = (s['sort'] ?? 'added') as String;
      eqOn = (s['eqOn'] ?? true) as bool;
      eqPreset = s['eqPreset'] as String?;
      final g = s['eq'];
      if (g is List && g.length == 5) eqGains = g.map((e) => (e as num).toDouble()).toList();
      final o = s['offsets'];
      if (o is Map) o.forEach((k, v) => offsets[k as String] = (v as num).toDouble());
      final f = s['favorites'];
      if (f is List) favorites = f.cast<String>().toSet();
      final pc = s['playCounts'];
      if (pc is Map) pc.forEach((k, v) => playCounts[k as String] = (v as num).toInt());
      final lp = s['lastPlayed'];
      if (lp is Map) lp.forEach((k, v) => lastPlayed[k as String] = (v as num).toInt());
      lastId = s['last'] as String?;
    }

    player.processingStateStream.listen((st) {
      if (st == ProcessingState.completed) _onEnded();
    });
    player.playingStream.listen((p) {
      if (p) _countOnce();
      notifyListeners();
    });
    player.positionStream.listen(_onPos);
    await player.setVolume(volume / 100);
    await setQueue(tracks.map((t) => t.id).toList(), startId: lastId, autoplay: false);
  }

  // ---------------- 저장 ----------------
  void _saveSoon() {
    _saveT?.cancel();
    _saveT = Timer(const Duration(milliseconds: 600), saveNow);
  }

  Future<void> saveNow() async {
    await store.writeJson('library.json', tracks.where((t) => !t.builtin).map((t) => t.toJson()).toList());
    await store.writeJson('playlists.json', playlists.map((p) => p.toJson()).toList());
    await store.writeJson('settings.json', {
      'shuffle': shuffle,
      'repeat': repeat,
      'speed': speed,
      'volume': volume,
      'sort': sortMode,
      'eqOn': eqOn,
      'eqPreset': eqPreset,
      'eq': eqGains,
      'offsets': offsets,
      'favorites': favorites.toList(),
      'playCounts': playCounts,
      'lastPlayed': lastPlayed,
      'last': current?.id,
    });
  }

  // ---------------- 재생 ----------------
  void _buildOrder(int startQ) {
    order = List.generate(queue.length, (i) => i);
    if (queue.isEmpty) {
      idx = -1;
      return;
    }
    startQ = math.max(0, math.min(queue.length - 1, startQ));
    if (shuffle) {
      order.shuffle();
      order.remove(startQ);
      order.insert(0, startQ);
      idx = 0;
    } else {
      idx = startQ;
    }
  }

  Future<void> setQueue(List<String> ids, {String? startId, bool autoplay = true, String? name}) async {
    queue = ids.where((id) => _byId.containsKey(id)).toList();
    if (name != null) queueName = name;
    if (queue.isEmpty) {
      order = [];
      idx = -1;
      notifyListeners();
      return;
    }
    final s = startId == null ? 0 : math.max(0, queue.indexOf(startId));
    _buildOrder(s);
    await _loadCurrent(autoplay);
  }

  Future<void> playShuffled(List<String> ids, {String? name}) async {
    if (ids.isEmpty) return;
    if (!shuffle) {
      shuffle = true;
    }
    final start = ids[math.Random().nextInt(ids.length)];
    await setQueue(ids, startId: start, name: name);
  }

  Future<void> playAt(int orderIndex) async {
    if (order.isEmpty) return;
    idx = ((orderIndex % order.length) + order.length) % order.length;
    await _loadCurrent(true);
  }

  Future<void> _loadCurrent(bool autoplay) async {
    final t = current;
    if (t == null) return;
    lyrics = parseLrc(t.lrc);
    abA = null;
    abB = null;
    _counted = false;
    notifyListeners();
    try {
      final d = await player.setAudioSource(AudioSource.file(
        t.path,
        tag: MediaItem(
          id: t.id,
          title: t.title,
          artist: t.artist,
          album: t.album.isEmpty ? '르냥뮤직스' : t.album,
          artUri: t.coverPath != null ? Uri.file(t.coverPath!) : null,
        ),
      ));
      if (d != null && d.inMilliseconds != t.durationMs) {
        t.durationMs = d.inMilliseconds;
      }
      await player.setSpeed(speed);
      unawaited(_initEq());
      if (autoplay) unawaited(player.play());
    } catch (_) {
      say('"${t.title}" 파일을 열 수 없어요. 지워졌거나 옮겨졌을 수 있어요');
    }
    _saveSoon();
    notifyListeners();
  }

  void _countOnce() {
    final t = current;
    if (t == null || _counted) return;
    _counted = true;
    playCounts[t.id] = (playCounts[t.id] ?? 0) + 1;
    lastPlayed[t.id] = DateTime.now().millisecondsSinceEpoch;
    _saveSoon();
  }

  void _onEnded() {
    if (sleepAfterTrack) {
      sleepAfterTrack = false;
      player.pause();
      player.seek(Duration.zero);
      say('잘 자라냥 🌙');
      notifyListeners();
      return;
    }
    if (repeat == 2) {
      player.seek(Duration.zero);
      player.play();
      return;
    }
    if (idx + 1 >= order.length && repeat == 0) {
      player.pause();
      player.seek(Duration.zero);
      return;
    }
    playAt(idx + 1);
  }

  void _onPos(Duration p) {
    final a = abA, b = abB;
    if (a != null && b != null && p >= b) player.seek(a);
  }

  Future<void> togglePlay() async {
    if (current == null) return;
    if (player.playing) {
      await player.pause();
    } else {
      if (player.processingState == ProcessingState.completed) await player.seek(Duration.zero);
      unawaited(player.play());
    }
  }

  Future<void> next() => playAt(idx + 1);
  Future<void> prev() async {
    if (player.position > const Duration(seconds: 3)) {
      await player.seek(Duration.zero);
    } else {
      await playAt(idx - 1);
    }
  }

  void toggleShuffle() {
    shuffle = !shuffle;
    final curQ = idx >= 0 && idx < order.length ? order[idx] : 0;
    _buildOrder(curQ);
    say(shuffle ? '섞어서 들어요' : '순서대로 들어요');
    _saveSoon();
    notifyListeners();
  }

  void cycleRepeat() {
    repeat = (repeat + 1) % 3;
    say(const ['반복 끔', '전체 반복', '한 곡 반복'][repeat]);
    _saveSoon();
    notifyListeners();
  }

  void playNext(Track t) {
    if (queue.isEmpty) {
      setQueue([t.id]);
      return;
    }
    queue.add(t.id);
    order.insert(idx + 1, queue.length - 1);
    say('다음 곡으로 넣었어요');
    notifyListeners();
  }

  void addToQueue(Track t) {
    queue.add(t.id);
    order.add(queue.length - 1);
    say('재생 목록 끝에 넣었어요');
    notifyListeners();
  }

  void removeFromQueue(int orderIndex) {
    if (orderIndex == idx) return;
    order.removeAt(orderIndex);
    if (orderIndex < idx) idx--;
    notifyListeners();
  }

  void moveInQueue(int from, int to) {
    if (to > from) to--;
    final curQ = order[idx];
    final v = order.removeAt(from);
    order.insert(to, v);
    idx = order.indexOf(curQ);
    notifyListeners();
  }

  // ---------------- 소리 ----------------
  void setVolume(int v) {
    volume = math.max(0, math.min(100, v));
    player.setVolume(volume / 100);
    _saveSoon();
    notifyListeners();
  }

  void setSpeed(double s) {
    speed = s;
    player.setSpeed(s);
    _saveSoon();
    notifyListeners();
  }

  Future<void> _initEq() async {
    final e = eq;
    if (e == null || eqParams != null) return;
    try {
      await e.setEnabled(eqOn);
      eqParams = await e.parameters.timeout(const Duration(seconds: 4));
      _pushEq();
      notifyListeners();
    } catch (_) {}
  }

  void _pushEq() {
    final p = eqParams;
    if (p == null) return;
    final n = p.bands.length;
    for (var i = 0; i < n; i++) {
      final src = eqGains[math.min(4, (i * 5) ~/ math.max(1, n))];
      final g = math.max(p.minDecibels, math.min(p.maxDecibels, src));
      p.bands[i].setGain(g);
    }
  }

  void setEqOn(bool v) {
    eqOn = v;
    eq?.setEnabled(v);
    _saveSoon();
    notifyListeners();
  }

  void setEqBand(int i, double g) {
    eqGains[i] = g;
    eqPreset = null;
    _pushEq();
    _saveSoon();
    notifyListeners();
  }

  void setEqPreset(String name) {
    eqGains = List.of(eqPresets[name]!);
    eqPreset = name;
    _pushEq();
    _saveSoon();
    notifyListeners();
  }

  // ---------------- 잠자기 · 구간반복 · 가사싱크 ----------------
  void setSleep(int minutes) {
    sleepTimer?.cancel();
    sleepTimer = null;
    sleepAt = null;
    sleepAfterTrack = false;
    if (minutes > 0) {
      sleepAt = DateTime.now().add(Duration(minutes: minutes));
      sleepTimer = Timer(Duration(minutes: minutes), () {
        player.pause();
        sleepAt = null;
        say('잘 자라냥 🌙');
        notifyListeners();
      });
      say('$minutes분 뒤에 멈춰요');
    } else if (minutes == -1) {
      sleepAfterTrack = true;
      say('이 곡이 끝나면 멈춰요');
    }
    notifyListeners();
  }

  void tapAB() {
    final p = player.position;
    if (abA == null) {
      abA = p;
      say('A 지점을 찍었어요. 한 번 더 누르면 B 지점');
    } else if (abB == null) {
      if (p > abA! + const Duration(milliseconds: 500)) {
        abB = p;
        player.seek(abA!);
        say('A-B 구간을 반복해요');
      } else {
        abA = null;
        say('B는 A보다 뒤여야 해요');
      }
    } else {
      abA = null;
      abB = null;
      say('구간 반복을 껐어요');
    }
    notifyListeners();
  }

  void nudgeOffset(double d) {
    final t = current;
    if (t == null) return;
    offsets[t.id] = ((offset + d) * 10).round() / 10;
    _saveSoon();
    notifyListeners();
  }

  // ---------------- 보관함 ----------------
  List<Track> sorted(Iterable<Track> src) {
    final l = src.toList();
    int byStr(String a, String b) => a.toLowerCase().compareTo(b.toLowerCase());
    switch (sortMode) {
      case 'title':
        l.sort((a, b) => byStr(a.title, b.title));
      case 'artist':
        l.sort((a, b) => byStr(a.artist, b.artist) != 0 ? byStr(a.artist, b.artist) : byStr(a.title, b.title));
      case 'album':
        l.sort((a, b) => byStr(a.album, b.album) != 0 ? byStr(a.album, b.album) : byStr(a.title, b.title));
      default:
        l.sort((a, b) => a.added.compareTo(b.added));
    }
    return l;
  }

  void setSort(String m) {
    sortMode = m;
    _saveSoon();
    notifyListeners();
  }

  Map<String, List<Track>> groupBy(String Function(Track) key) {
    final m = <String, List<Track>>{};
    for (final t in tracks) {
      (m[key(t)] ??= []).add(t);
    }
    final keys = m.keys.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return {for (final k in keys) k: m[k]!};
  }

  List<Track> get favoriteTracks => tracks.where((t) => favorites.contains(t.id)).toList();
  List<Track> get recentTracks {
    final l = tracks.where((t) => lastPlayed.containsKey(t.id)).toList()
      ..sort((a, b) => lastPlayed[b.id]!.compareTo(lastPlayed[a.id]!));
    return l.take(50).toList();
  }

  List<Track> get topTracks {
    final l = tracks.where((t) => (playCounts[t.id] ?? 0) > 0).toList()
      ..sort((a, b) => playCounts[b.id]!.compareTo(playCounts[a.id]!));
    return l.take(50).toList();
  }

  void toggleFavorite(Track t) {
    if (!favorites.remove(t.id)) {
      favorites.add(t.id);
      say('즐겨찾기에 넣었어요 💗');
    } else {
      say('즐겨찾기에서 뺐어요');
    }
    _saveSoon();
    notifyListeners();
  }

  String _newId(String p) => '$p${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}${math.Random().nextInt(1 << 20).toRadixString(36)}';

  Future<Track> _makeTrack(String path, {required bool external, String lrc = ''}) async {
    final tg = await readId3(path);
    final id = _newId('t');
    final nm = baseName(path);
    var title = tg.title ?? '';
    var artist = tg.artist ?? '';
    if (title.isEmpty) {
      final parts = nm.split(' - ');
      if (parts.length > 1) {
        if (artist.isEmpty) artist = parts.first.trim();
        title = parts.sublist(1).join(' - ').trim();
      } else {
        title = nm;
      }
    }
    String? coverPath;
    if (tg.cover != null && tg.cover!.isNotEmpty) {
      final e = (tg.coverMime ?? '').contains('png') ? 'png' : 'jpg';
      final f = File('${store.coverDir.path}/$id.$e');
      try {
        await f.writeAsBytes(tg.cover!);
        coverPath = f.path;
      } catch (_) {}
    }
    return Track(
      id: id,
      title: title,
      artist: artist.isEmpty ? '알 수 없는 가수' : artist,
      album: tg.album ?? '',
      path: path,
      coverPath: coverPath,
      lrc: lrc.isNotEmpty ? lrc : (tg.lyrics ?? ''),
      external: external,
      added: DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// 파일 고르기로 노래(와 같은 이름의 .lrc)를 넣는다.
  Future<void> importFiles() async {
    FilePickerResult? res;
    try {
      res = await FilePicker.platform.pickFiles(allowMultiple: true, type: FileType.any);
    } catch (_) {
      say('파일 고르기를 열 수 없어요');
      return;
    }
    if (res == null) return;
    final files = res.files.where((f) => f.path != null).toList();
    final lrcMap = <String, String>{};
    for (final f in files.where((f) => const {'lrc', 'txt'}.contains(ext(f.name)))) {
      lrcMap[baseName(f.name).toLowerCase()] = decodeText(await File(f.path!).readAsBytes());
    }
    var added = 0;
    for (final f in files.where((f) => audioExts.contains(ext(f.name)))) {
      final id = _newId('f');
      final dest = '${store.musicDir.path}/$id.${ext(f.name)}';
      try {
        await File(f.path!).copy(dest);
      } catch (_) {
        continue;
      }
      final t = await _makeTrack(dest, external: false, lrc: lrcMap[baseName(f.name).toLowerCase()] ?? '');
      if (t.title == id) t.title = baseName(f.name);
      tracks.add(t);
      added++;
    }
    // 가사 파일만 골랐으면 이름이 같은 곡(없으면 지금 곡)에 붙인다
    var matched = 0;
    if (added == 0 && lrcMap.isNotEmpty) {
      lrcMap.forEach((k, v) {
        for (final t in tracks) {
          if (t.title.toLowerCase() == k || baseName(t.path).toLowerCase() == k) {
            t.lrc = v;
            matched++;
          }
        }
      });
      if (matched == 0 && current != null && lrcMap.length == 1) {
        current!.lrc = lrcMap.values.first;
        matched = 1;
      }
      lyrics = parseLrc(current?.lrc);
    }
    _reindex();
    _saveSoon();
    notifyListeners();
    if (added > 0) {
      say('노래 $added곡을 넣었다냥 🐾');
    } else if (matched > 0) {
      say('가사를 붙였어요');
    } else if (files.isNotEmpty) {
      say('넣을 수 있는 음악 파일이 없었어요');
    }
  }

  /// 기기 저장공간에서 음악 파일을 찾아 보관함에 넣는다 (알송의 '음악 검색').
  Future<void> scanDevice() async {
    if (!Platform.isAndroid) {
      say('아이폰은 파일에서 노래 넣기를 써주세요');
      return;
    }
    final st = await [Permission.audio, Permission.storage].request();
    final ok = st.values.any((s) => s.isGranted || s.isLimited);
    if (!ok) {
      say('음악 파일 접근을 허락해야 찾을 수 있어요');
      if (st.values.any((s) => s.isPermanentlyDenied)) await openAppSettings();
      return;
    }
    scanning = true;
    notifyListeners();
    final known = tracks.map((t) => t.path).toSet();
    final found = <String>[];
    final lrcs = <String, String>{};
    final roots = ['/storage/emulated/0'];
    final queueDirs = <(Directory, int)>[for (final r in roots) (Directory(r), 0)];
    while (queueDirs.isNotEmpty) {
      final (d, depth) = queueDirs.removeLast();
      try {
        await for (final e in d.list(followLinks: false)) {
          final name = e.path.split('/').last;
          if (name.startsWith('.')) continue;
          if (e is Directory) {
            if (depth < 7 && !(depth == 0 && name == 'Android')) queueDirs.add((e, depth + 1));
          } else if (e is File) {
            final x = ext(name);
            if (audioExts.contains(x) && !known.contains(e.path)) {
              found.add(e.path);
            } else if (x == 'lrc') {
              lrcs[e.path.substring(0, e.path.length - 4).toLowerCase()] = e.path;
            }
          }
        }
      } catch (_) {}
    }
    var added = 0;
    for (final p in found) {
      try {
        if (await File(p).length() < 30 * 1024) continue; // 알림음 같은 짧은 파일은 건너뜀
        final i = p.lastIndexOf('.');
        final lp = lrcs[p.substring(0, i).toLowerCase()];
        final lrc = lp != null ? decodeText(await File(lp).readAsBytes()) : '';
        tracks.add(await _makeTrack(p, external: true, lrc: lrc));
        added++;
      } catch (_) {}
    }
    scanning = false;
    _reindex();
    _saveSoon();
    notifyListeners();
    say(added > 0 ? '기기에서 노래 $added곡을 찾았다냥 🐾' : '새로 찾은 노래가 없어요');
  }

  Future<void> removeTrack(Track t) async {
    if (t.builtin) return;
    final wasCur = current?.id == t.id;
    final keep = wasCur ? null : current?.id;
    tracks.remove(t);
    _byId.remove(t.id);
    for (final p in playlists) {
      p.trackIds.remove(t.id);
    }
    favorites.remove(t.id);
    try {
      if (!t.external) await File(t.path).delete();
      if (t.coverPath != null) await File(t.coverPath!).delete();
    } catch (_) {}
    final ids = queue.where((id) => id != t.id).toList();
    if (wasCur) {
      await player.stop();
      await setQueue(ids.isEmpty ? tracks.map((x) => x.id).toList() : ids, autoplay: false);
    } else {
      final curQId = keep;
      queue = ids;
      _buildOrder(curQId == null ? 0 : math.max(0, queue.indexOf(curQId)));
    }
    _saveSoon();
    notifyListeners();
    say('보관함에서 뺐어요');
  }

  void editInfo(Track t, String title, String artist, String album) {
    if (title.trim().isNotEmpty) t.title = title.trim();
    t.artist = artist.trim().isEmpty ? '알 수 없는 가수' : artist.trim();
    t.album = album.trim();
    _saveSoon();
    notifyListeners();
  }

  void setLyrics(Track t, String text) {
    t.lrc = text;
    if (current?.id == t.id) lyrics = parseLrc(text);
    _saveSoon();
    notifyListeners();
  }

  Future<void> pickLyricsFile(Track t) async {
    try {
      final res = await FilePicker.platform.pickFiles(type: FileType.any);
      final p = res?.files.single.path;
      if (p == null) return;
      setLyrics(t, decodeText(await File(p).readAsBytes()));
      say('가사를 붙였어요');
    } catch (_) {
      say('가사 파일을 읽을 수 없어요');
    }
  }

  // ---------------- 플레이리스트 ----------------
  Playlist createPlaylist(String name) {
    final p = Playlist(id: _newId('p'), name: name.trim().isEmpty ? '새 플레이리스트' : name.trim());
    playlists.add(p);
    _saveSoon();
    notifyListeners();
    return p;
  }

  void renamePlaylist(Playlist p, String name) {
    if (name.trim().isEmpty) return;
    p.name = name.trim();
    _saveSoon();
    notifyListeners();
  }

  void deletePlaylist(Playlist p) {
    playlists.remove(p);
    _saveSoon();
    notifyListeners();
    say('플레이리스트를 지웠어요');
  }

  void addToPlaylist(Playlist p, List<String> ids) {
    var n = 0;
    for (final id in ids) {
      if (!p.trackIds.contains(id)) {
        p.trackIds.add(id);
        n++;
      }
    }
    _saveSoon();
    notifyListeners();
    say(n > 0 ? '"${p.name}"에 $n곡 담았어요' : '이미 담겨 있어요');
  }

  void removeFromPlaylist(Playlist p, int i) {
    p.trackIds.removeAt(i);
    _saveSoon();
    notifyListeners();
  }

  void reorderPlaylist(Playlist p, int from, int to) {
    if (to > from) to--;
    final v = p.trackIds.removeAt(from);
    p.trackIds.insert(to, v);
    _saveSoon();
    notifyListeners();
  }

  List<Track> playlistTracks(Playlist p) => p.trackIds.map((id) => _byId[id]).whereType<Track>().toList();
}
