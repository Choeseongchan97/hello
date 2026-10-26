import 'package:flutter_test/flutter_test.dart';
import 'package:renyang_musics/lrc.dart';

void main() {
  test('lrc 싱크 가사를 시간 순서로 읽는다', () {
    final l = parseLrc('[00:05.00]둘\n[00:01.50]하나');
    expect(l.length, 2);
    expect(l.first.text, '하나');
    expect(activeLine(l, 2.0), 0);
  });
}
