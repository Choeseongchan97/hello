import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

/// MP3 안에 들어있는 ID3v2 태그(곡명, 가수, 앨범, 커버, 가사)를 읽는다.
class Id3Tags {
  String? title, artist, album, lyrics, coverMime;
  Uint8List? cover;
}

String _dec(Uint8List b, int enc) {
  try {
    if (enc == 0) return latin1.decode(b, allowInvalid: true);
    if (enc == 3) return utf8.decode(b, allowMalformed: true);
    var be = enc == 2;
    var start = 0;
    if (enc == 1 && b.length >= 2) {
      if (b[0] == 0xFE && b[1] == 0xFF) {
        be = true;
        start = 2;
      } else if (b[0] == 0xFF && b[1] == 0xFE) {
        be = false;
        start = 2;
      }
    }
    final codes = <int>[];
    for (var i = start; i + 1 < b.length; i += 2) {
      codes.add(be ? (b[i] << 8) | b[i + 1] : (b[i + 1] << 8) | b[i]);
    }
    return String.fromCharCodes(codes);
  } catch (_) {
    return '';
  }
}

String _clean(String s) => s.replaceAll('\u0000', '').trim();

int _term(Uint8List b, int from, int enc) {
  final wide = enc == 1 || enc == 2;
  if (wide) {
    for (var i = from; i + 1 < b.length; i += 2) {
      if (b[i] == 0 && b[i + 1] == 0) return i;
    }
  } else {
    for (var i = from; i < b.length; i++) {
      if (b[i] == 0) return i;
    }
  }
  return b.length;
}

final _frameId = RegExp(r'^[A-Z0-9]{4}$');

Future<Id3Tags> readId3(String path) async {
  final r = Id3Tags();
  RandomAccessFile? f;
  try {
    f = await File(path).open();
    final head = await f.read(10);
    if (head.length < 10 || head[0] != 0x49 || head[1] != 0x44 || head[2] != 0x33) return r;
    final ver = head[3];
    if (ver < 3) return r;
    final size = (head[6] << 21) | (head[7] << 14) | (head[8] << 7) | head[9];
    final b = await f.read(size);
    var p = 0;
    if ((head[5] & 0x40) != 0 && b.length > 4) {
      p = ver == 4
          ? ((b[0] << 21) | (b[1] << 14) | (b[2] << 7) | b[3])
          : ((b[0] << 24) | (b[1] << 16) | (b[2] << 8) | b[3]) + 4;
    }
    while (p + 10 < b.length) {
      final id = String.fromCharCodes(b.sublist(p, p + 4));
      if (!_frameId.hasMatch(id)) break;
      final fs = ver == 4
          ? ((b[p + 4] << 21) | (b[p + 5] << 14) | (b[p + 6] << 7) | b[p + 7])
          : ((b[p + 4] << 24) | (b[p + 5] << 16) | (b[p + 6] << 8) | b[p + 7]);
      final start = p + 10;
      final end = math.min(start + fs, b.length);
      p = start + fs;
      if (fs <= 0 || end <= start) continue;
      final d = Uint8List.sublistView(b, start, end);
      final enc = d[0];
      final wide = enc == 1 || enc == 2;
      switch (id) {
        case 'TIT2':
          r.title = _clean(_dec(Uint8List.sublistView(d, 1), enc));
        case 'TPE1':
          r.artist = _clean(_dec(Uint8List.sublistView(d, 1), enc));
        case 'TALB':
          r.album = _clean(_dec(Uint8List.sublistView(d, 1), enc));
        case 'USLT':
          if (d.length > 4) {
            final e = _term(d, 4, enc);
            final q = e + (wide ? 2 : 1);
            if (q < d.length) r.lyrics = _clean(_dec(Uint8List.sublistView(d, q), enc));
          }
        case 'APIC':
          if (r.cover == null) {
            var e = 1;
            while (e < d.length && d[e] != 0) {
              e++;
            }
            final mime = latin1.decode(d.sublist(1, e), allowInvalid: true);
            var q = e + 2; // null + picture type
            if (q < d.length) {
              final e2 = _term(d, q, enc);
              q = e2 + (wide ? 2 : 1);
              if (q < d.length) {
                r.cover = Uint8List.fromList(d.sublist(q));
                r.coverMime = mime;
              }
            }
          }
      }
    }
  } catch (_) {
    // 태그가 깨져 있어도 파일 이름으로 대신 보여준다
  } finally {
    await f?.close();
  }
  return r;
}

/// 가사 파일 글자 인코딩: UTF-8을 먼저 보고, 안 되면 latin1로 읽는다.
String decodeText(List<int> bytes) {
  var b = bytes;
  if (b.length >= 3 && b[0] == 0xEF && b[1] == 0xBB && b[2] == 0xBF) b = b.sublist(3);
  if (b.length >= 2 && b[0] == 0xFF && b[1] == 0xFE) return _dec(Uint8List.fromList(b), 1);
  if (b.length >= 2 && b[0] == 0xFE && b[1] == 0xFF) return _dec(Uint8List.fromList(b), 1);
  try {
    return utf8.decode(b);
  } catch (_) {
    return utf8.decode(b, allowMalformed: true);
  }
}
