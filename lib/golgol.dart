import 'dart:math';
import 'dart:typed_data';

const golgolLrc = '''[00:00.50](골골골… 르냥이가 노래를 시작해요)
[00:05.00]햇살 내린 창가에 동그랗게 누워
[00:10.30]꼬리는 살랑살랑 눈은 스르르
[00:15.60]골골 골골 작은 엔진 소리
[00:21.00]오늘도 수고했다냥 토닥토닥
[00:26.30]말랑한 발바닥 꾹꾹 꾹꾹
[00:31.60]따뜻한 무릎 위가 제일 좋아
[00:37.00]골골 골골 너랑 나랑
[00:42.30]내일도 같이 듣자 르냥골골송
[00:47.00](골골… 쿨쿨…)''';

/// 르냥골골송: 고양이 골골 소리 + 오르골 멜로디를 직접 합성해서 WAV로 만든다.
Uint8List makeGolgolWav() {
  const sr = 22050;
  const dur = 52;
  const n = sr * dur;
  final out = Float64List(n);
  final rnd = Random(7);

  // 골골 소리: 낮게 거른 잡음을 초당 24~27번 맥박처럼 울리고, 숨 들이쉬고 내쉬는 흐름을 준다
  var lp = 0.0, lp2 = 0.0;
  for (var i = 0; i < n; i++) {
    final t = i / sr;
    final wn = rnd.nextDouble() * 2 - 1;
    lp += (wn - lp) * 0.06;
    lp2 += (lp - lp2) * 0.08;
    final cyc = (t % 2.6) / 2.6;
    final inhale = cyc < 0.42;
    final rate = inhale ? 27.0 : 24.0;
    final br = inhale ? sin(cyc / 0.42 * pi) * 0.55 : sin((cyc - 0.42) / 0.58 * pi);
    final s = 0.5 + 0.5 * sin(2 * pi * rate * t);
    final pulse = s * s * s;
    final fade = min(1.0, t / 1.5) * min(1.0, (dur - t) / 3);
    out[i] = lp2 * pulse * br * 2.2 * fade;
  }

  // 오르골 멜로디 (92bpm)
  double f(int m) => 440 * pow(2, (m - 69) / 12).toDouble();
  void note(int m, double t0, double len, double vol) {
    if (m < 0) return;
    final fr = f(m);
    final s = (t0 * sr).floor();
    final e = min(n, s + (len * sr).floor());
    for (var i = s; i < e; i++) {
      final t = (i - s) / sr;
      final env = exp(-t * 3.2) * min(1.0, t * 400);
      out[i] += vol *
          env *
          (sin(2 * pi * fr * t) + 0.35 * sin(2 * pi * fr * 2 * t) + 0.12 * sin(2 * pi * fr * 3.01 * t));
    }
  }

  const a = [72, 76, 79, 76, 74, 72, 74, 76, 77, 76, 74, 72, 74, -1, 79, -1, 72, 76, 79, 81, 79, 76, 74, 72, 74, 76, 74, 71, 72, -1, -1, -1];
  const b = [48, 55, 52, 55, 53, 60, 55, 59];
  const beat = 60 / 92;
  const step = beat / 2;
  var t = 2.0;
  while (t < dur - 4) {
    for (var k = 0; k < a.length && t < dur - 4; k++) {
      note(a[k], t, 1.4, 0.16);
      if (k % 4 == 0) note(b[(k ~/ 4) % b.length], t, 2.2, 0.12);
      t += step;
    }
  }
  note(84, dur - 4.2, 3.5, 0.12);
  note(79, dur - 3.9, 3.5, 0.09);

  // WAV 16bit mono
  final bd = ByteData(44 + n * 2);
  void w(int o, String s) {
    for (var i = 0; i < s.length; i++) {
      bd.setUint8(o + i, s.codeUnitAt(i));
    }
  }

  w(0, 'RIFF');
  bd.setUint32(4, 36 + n * 2, Endian.little);
  w(8, 'WAVE');
  w(12, 'fmt ');
  bd.setUint32(16, 16, Endian.little);
  bd.setUint16(20, 1, Endian.little);
  bd.setUint16(22, 1, Endian.little);
  bd.setUint32(24, sr, Endian.little);
  bd.setUint32(28, sr * 2, Endian.little);
  bd.setUint16(32, 2, Endian.little);
  bd.setUint16(34, 16, Endian.little);
  w(36, 'data');
  bd.setUint32(40, n * 2, Endian.little);
  for (var i = 0; i < n; i++) {
    final s = max(-1.0, min(1.0, out[i] * 0.9));
    bd.setInt16(44 + i * 2, (s * 32767).round(), Endian.little);
  }
  return bd.buffer.asUint8List();
}
