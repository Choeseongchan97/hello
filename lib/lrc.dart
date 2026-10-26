class LyricLine {
  final double? t;
  final String text;
  const LyricLine(this.t, this.text);
}

final _tagRe = RegExp(r'\[(\d{1,2}):(\d{1,2})(?:[.:](\d{1,3}))?\]');
final _anyTag = RegExp(r'\[[^\]]*\]');

/// .lrc 싱크 가사를 읽는다. 시간 태그가 없으면 일반 가사(t == null)로 돌려준다.
List<LyricLine> parseLrc(String? src) {
  if (src == null || src.trim().isEmpty) return const [];
  final out = <LyricLine>[];
  var timed = false;
  for (final line in src.split(RegExp(r'\r?\n'))) {
    final tags = _tagRe.allMatches(line).toList();
    final text = line.replaceAll(_anyTag, '').trim();
    if (tags.isNotEmpty) {
      timed = true;
      for (final m in tags) {
        final frac = m.group(3);
        double t = int.parse(m.group(1)!) * 60.0 + int.parse(m.group(2)!);
        if (frac != null) t += double.parse('0.${frac.padRight(3, '0')}');
        out.add(LyricLine(t, text.isEmpty ? '♪' : text));
      }
    } else if (text.isNotEmpty && !line.trimLeft().startsWith('[')) {
      out.add(LyricLine(null, text));
    }
  }
  if (timed) {
    final r = out.where((l) => l.t != null).toList();
    r.sort((a, b) => a.t!.compareTo(b.t!));
    return r;
  }
  return out;
}

bool isTimed(List<LyricLine> l) => l.isNotEmpty && l.first.t != null;

int activeLine(List<LyricLine> l, double sec) {
  if (!isTimed(l)) return -1;
  var a = -1;
  for (var i = 0; i < l.length; i++) {
    if (l[i].t! <= sec) {
      a = i;
    } else {
      break;
    }
  }
  return a;
}
