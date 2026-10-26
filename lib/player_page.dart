import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';

import 'lrc.dart';
import 'state.dart';
import 'theme.dart';
import 'widgets.dart';

class PlayerPage extends StatefulWidget {
  const PlayerPage({super.key});
  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> with TickerProviderStateMixin {
  late final AnimationController bob = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
  late final AnimationController spin = AnimationController(vsync: this, duration: const Duration(seconds: 18));
  StreamSubscription<bool>? sub;
  bool showLyrics = false;

  @override
  void initState() {
    super.initState();
    sub = app.player.playingStream.listen((p) {
      if (!mounted) return;
      if (p) {
        bob.repeat();
        spin.repeat();
      } else {
        bob.stop();
        spin.stop();
      }
    });
  }

  @override
  void dispose() {
    sub?.cancel();
    bob.dispose();
    spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = RC.of(context);
    return Scaffold(
      body: Container(
        decoration: pageGradient(context),
        child: SafeArea(
          child: ListenableBuilder(
            listenable: app,
            builder: (context, _) {
              final t = app.current;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Column(children: [
                  Row(children: [
                    IconButton(
                        tooltip: '닫기',
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32)),
                    Expanded(
                      child: Column(children: [
                        Text('지금 재생', style: body(context, 12, color: c.muted)),
                        Text(app.queueName, maxLines: 1, overflow: TextOverflow.ellipsis, style: disp(context, 15)),
                      ]),
                    ),
                    IconButton(
                        tooltip: '재생 목록',
                        onPressed: () => showQueueSheet(context),
                        icon: const Icon(Icons.queue_music_rounded, size: 28)),
                  ]),
                  Expanded(
                    child: showLyrics
                        ? LyricsView(onClose: () => setState(() => showLyrics = false))
                        : GestureDetector(
                            onTap: () => setState(() => showLyrics = true),
                            child: LayoutBuilder(builder: (context, box) {
                              final s = math.min(box.maxWidth * .82, box.maxHeight - 70).clamp(120.0, 340.0).toDouble();
                              return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                CoverArt(size: s, bob: bob, spin: spin),
                                const SizedBox(height: 12),
                                SizedBox(height: 40, child: Viz(spin: spin)),
                                const LyricPeek(),
                              ]);
                            }),
                          ),
                  ),
                  const SizedBox(height: 6),
                  Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(t?.title ?? '노래를 골라주세요',
                            maxLines: 1, overflow: TextOverflow.ellipsis, style: disp(context, 23)),
                        Text(
                            t == null ? '' : '${t.artist}${t.album.isNotEmpty ? ' · ${t.album}' : ''}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: body(context, 14, color: c.muted)),
                      ]),
                    ),
                    if (t != null)
                      IconButton(
                        tooltip: '즐겨찾기',
                        onPressed: () => app.toggleFavorite(t),
                        icon: Icon(app.favorites.contains(t.id) ? Icons.favorite : Icons.favorite_border,
                            color: c.accent, size: 28),
                      ),
                  ]),
                  const SeekBar(),
                  const Controls(),
                  const VolumeRow(),
                  ToolsRow(
                    lyricsOn: showLyrics,
                    onLyrics: () => setState(() => showLyrics = !showLyrics),
                  ),
                  const SizedBox(height: 8),
                ]),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ---------------- 커버 + 골골 애니메이션 ----------------
class CoverArt extends StatelessWidget {
  final double size;
  final AnimationController bob, spin;
  const CoverArt({super.key, required this.size, required this.bob, required this.spin});

  @override
  Widget build(BuildContext context) {
    final c = RC.of(context);
    final t = app.current;
    final cp = t?.coverPath;
    final playing = app.player.playing;
    final disc = Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: c.bg2,
        border: Border.all(color: c.ink, width: 4),
        boxShadow: [BoxShadow(color: c.accent.withAlpha(60), blurRadius: 30, offset: const Offset(0, 12))],
      ),
      child: cp != null
          ? Image.file(File(cp),
              fit: BoxFit.cover, gaplessPlayback: true, errorBuilder: (_, __, ___) => Center(child: CatFace(size: size * .8)))
          : Center(child: CatFace(size: size * .82)),
    );
    return SizedBox(
      width: size + 40,
      height: size + 20,
      child: Stack(alignment: Alignment.center, clipBehavior: Clip.none, children: [
        if (cp != null)
          RotationTransition(turns: spin, child: disc)
        else
          AnimatedBuilder(
            animation: bob,
            builder: (_, child) => Transform.translate(
              offset: Offset(0, playing ? -5 * math.sin(bob.value * math.pi * 2).abs() : 0),
              child: child,
            ),
            child: disc,
          ),
        if (playing)
          AnimatedBuilder(
            animation: bob,
            builder: (_, __) {
              final v = bob.value;
              return Positioned(
                right: 4 - v * 10,
                top: size * .12 - v * 36,
                child: Opacity(
                  opacity: (1 - v).clamp(0.0, 1.0).toDouble(),
                  child: Text('골골', style: disp(context, 18 + v * 4, color: c.accent)),
                ),
              );
            },
          ),
        if (playing)
          AnimatedBuilder(
            animation: bob,
            builder: (_, __) {
              final v = (bob.value + .5) % 1;
              return Positioned(
                left: 6 + v * 4,
                top: size * .3 - v * 30,
                child: Opacity(
                  opacity: (1 - v).clamp(0.0, 1.0).toDouble(),
                  child: Text('♪', style: disp(context, 20, color: c.butter)),
                ),
              );
            },
          ),
      ]),
    );
  }
}

class Viz extends StatelessWidget {
  final AnimationController spin;
  const Viz({super.key, required this.spin});
  @override
  Widget build(BuildContext context) {
    final c = RC.of(context);
    return AnimatedBuilder(
      animation: spin,
      builder: (_, __) => CustomPaint(
        size: const Size(double.infinity, 40),
        painter: _VizPainter(spin.value * 18, app.player.playing, c.accent, c.butter, c.line),
      ),
    );
  }
}

class _VizPainter extends CustomPainter {
  final double t;
  final bool on;
  final Color a, b, off;
  _VizPainter(this.t, this.on, this.a, this.b, this.off);
  @override
  void paint(Canvas canvas, Size size) {
    const n = 26;
    const gap = 4.0;
    final bw = (size.width - gap * (n - 1)) / n;
    for (var i = 0; i < n; i++) {
      double v;
      if (on) {
        v = .25 +
            .35 * (math.sin(t * 7 + i * .8) * .5 + .5) +
            .3 * (math.sin(t * 11.3 + i * 1.7) * .5 + .5) * (math.sin(t * 2 + i) * .5 + .5);
      } else {
        v = .12 + .06 * math.sin(i * .9);
      }
      final h = math.max(5.0, v * size.height);
      final r = RRect.fromRectAndRadius(Rect.fromLTWH(i * (bw + gap), size.height - h, bw, h), Radius.circular(bw / 2));
      canvas.drawRRect(r, Paint()..color = on ? (i % 3 == 1 ? b : a) : off);
    }
  }

  @override
  bool shouldRepaint(covariant _VizPainter o) => true;
}

class LyricPeek extends StatelessWidget {
  const LyricPeek({super.key});
  @override
  Widget build(BuildContext context) {
    final c = RC.of(context);
    return StreamBuilder<Duration>(
      stream: app.player.positionStream,
      builder: (context, snap) {
        final sec = (snap.data?.inMilliseconds ?? 0) / 1000 + app.offset;
        final i = activeLine(app.lyrics, sec);
        final txt = i >= 0 ? app.lyrics[i].text : (app.lyrics.isEmpty ? '커버를 누르면 가사를 볼 수 있어요' : '');
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Text(txt,
                key: ValueKey(txt),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: i >= 0 ? disp(context, 16, color: c.accent) : body(context, 12, color: c.muted)),
          ),
        );
      },
    );
  }
}

// ---------------- 가사 화면 ----------------
class LyricsView extends StatefulWidget {
  final VoidCallback onClose;
  const LyricsView({super.key, required this.onClose});
  @override
  State<LyricsView> createState() => _LyricsViewState();
}

class _LyricsViewState extends State<LyricsView> {
  List<GlobalKey> keys = [];
  List<LyricLine>? _for;
  int last = -2;

  @override
  Widget build(BuildContext context) {
    final c = RC.of(context);
    final ls = app.lyrics;
    final t = app.current;
    if (!identical(_for, ls)) {
      _for = ls;
      keys = List.generate(ls.length, (_) => GlobalKey());
      last = -2;
    }
    return Column(children: [
      Expanded(
        child: ls.isEmpty
            ? EmptyState(
                title: '가사가 아직 없어요',
                text: '.lrc 싱크 가사 파일을 붙이거나\n직접 써서 넣을 수 있어요',
                actions: [
                  if (t != null) PillButton(label: '.lrc 붙이기', icon: Icons.attach_file, onTap: () => app.pickLyricsFile(t)),
                  if (t != null) PillButton(label: '직접 쓰기', icon: Icons.edit, onTap: () => _edit(t)),
                ],
              )
            : StreamBuilder<Duration>(
                stream: app.player.positionStream,
                builder: (context, snap) {
                  final sec = (snap.data?.inMilliseconds ?? 0) / 1000 + app.offset;
                  final a = activeLine(ls, sec);
                  if (a != last) {
                    last = a;
                    if (a >= 0) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        final cx = keys[a].currentContext;
                        if (cx != null) {
                          Scrollable.ensureVisible(cx,
                              alignment: .45, duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic);
                        }
                      });
                    }
                  }
                  final timed = isTimed(ls);
                  return ShaderMask(
                    shaderCallback: (r) => const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black, Colors.black, Colors.transparent],
                      stops: [0, .12, .88, 1],
                    ).createShader(r),
                    blendMode: BlendMode.dstIn,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(vertical: 90),
                      child: Column(children: [
                        for (var i = 0; i < ls.length; i++)
                          InkWell(
                            key: keys[i],
                            borderRadius: BorderRadius.circular(12),
                            onTap: timed
                                ? () {
                                    app.player.seek(Duration(
                                        milliseconds: math.max(0, ((ls[i].t! - app.offset) * 1000).round())));
                                    if (!app.player.playing) app.togglePlay();
                                  }
                                : null,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 8),
                              child: AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 200),
                                style: i == a
                                    ? disp(context, 21, color: c.ink)
                                    : body(context, 16, color: c.muted),
                                textAlign: TextAlign.center,
                                child: Text(i == a ? '🐾 ${ls[i].text}' : ls[i].text, textAlign: TextAlign.center),
                              ),
                            ),
                          ),
                      ]),
                    ),
                  );
                },
              ),
      ),
      Wrap(spacing: 6, runSpacing: 6, alignment: WrapAlignment.center, children: [
        PillButton(label: '−0.5초', onTap: () => app.nudgeOffset(-.5)),
        PillButton(label: '싱크 ${app.offset >= 0 ? '+' : ''}${app.offset.toStringAsFixed(1)}초', onTap: null),
        PillButton(label: '+0.5초', onTap: () => app.nudgeOffset(.5)),
        if (t != null) PillButton(label: '가사', icon: Icons.edit, onTap: () => _edit(t)),
        PillButton(label: '커버', icon: Icons.album_rounded, onTap: widget.onClose),
      ]),
      const SizedBox(height: 4),
    ]);
  }

  Future<void> _edit(t) async {
    final s = await askText(context,
        title: '가사', initial: t.lrc, hint: '[00:12.30] 가사 한 줄\n시간 없이 써도 돼요', multiline: true);
    if (s != null) app.setLyrics(t, s);
  }
}

// ---------------- 재생바 · 버튼 ----------------
class SeekBar extends StatefulWidget {
  const SeekBar({super.key});
  @override
  State<SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends State<SeekBar> {
  double? drag;
  @override
  Widget build(BuildContext context) {
    final c = RC.of(context);
    return StreamBuilder<Duration>(
      stream: app.player.positionStream,
      builder: (context, snap) {
        final pos = snap.data ?? Duration.zero;
        final dur = app.player.duration ?? Duration.zero;
        final max = math.max(1.0, dur.inMilliseconds.toDouble());
        final v = (drag ?? pos.inMilliseconds.toDouble()).clamp(0.0, max).toDouble();
        final a = app.abA, b = app.abB;
        return Column(children: [
          SizedBox(
            height: 36,
            child: Stack(alignment: Alignment.center, children: [
              if (a != null)
                LayoutBuilder(builder: (context, box) {
                  final w = box.maxWidth - 48;
                  final l = 24 + w * (a.inMilliseconds / max);
                  final r = b == null ? l + 3 : 24 + w * (b.inMilliseconds / max);
                  return Stack(children: [
                    Positioned(
                      left: l,
                      width: math.max(3, r - l),
                      top: 8,
                      bottom: 8,
                      child: Container(
                        decoration: BoxDecoration(color: c.butter.withAlpha(150), borderRadius: BorderRadius.circular(6)),
                      ),
                    ),
                  ]);
                }),
              Slider(
                value: v,
                max: max,
                onChanged: (x) => setState(() => drag = x),
                onChangeEnd: (x) {
                  app.player.seek(Duration(milliseconds: x.round()));
                  setState(() => drag = null);
                },
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Row(children: [
              Text(fmtDur(Duration(milliseconds: v.round())),
                  style: body(context, 12, color: c.muted).copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
              const Spacer(),
              if (a != null)
                Text(b == null ? 'A 지점 ${fmtDur(a)}' : 'A-B 반복 중',
                    style: disp(context, 12, color: c.accent)),
              const Spacer(),
              Text(fmtDur(dur),
                  style: body(context, 12, color: c.muted).copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
            ]),
          ),
        ]);
      },
    );
  }
}

class Controls extends StatelessWidget {
  const Controls({super.key});
  @override
  Widget build(BuildContext context) {
    final c = RC.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        IconButton(
          tooltip: '셔플',
          onPressed: app.toggleShuffle,
          icon: Icon(Icons.shuffle_rounded, color: app.shuffle ? c.accent : c.muted, size: 26),
        ),
        IconButton(
            tooltip: '이전 곡',
            onPressed: app.prev,
            icon: Icon(Icons.skip_previous_rounded, size: 40, color: c.ink)),
        Material(
          color: c.accent,
          shape: const CircleBorder(),
          elevation: 3,
          shadowColor: c.accent.withAlpha(120),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: app.togglePlay,
            child: SizedBox(
              width: 76,
              height: 76,
              child: Icon(app.player.playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  size: 44, color: c.accentInk),
            ),
          ),
        ),
        IconButton(
            tooltip: '다음 곡', onPressed: app.next, icon: Icon(Icons.skip_next_rounded, size: 40, color: c.ink)),
        IconButton(
          tooltip: const ['반복 끔', '전체 반복', '한 곡 반복'][app.repeat],
          onPressed: app.cycleRepeat,
          icon: Icon(app.repeat == 2 ? Icons.repeat_one_rounded : Icons.repeat_rounded,
              color: app.repeat > 0 ? c.accent : c.muted, size: 26),
        ),
      ]),
    );
  }
}

/// 소리 0~100: 슬라이더 + 한 칸씩 버튼 + 숫자
class VolumeRow extends StatelessWidget {
  const VolumeRow({super.key});
  @override
  Widget build(BuildContext context) {
    final c = RC.of(context);
    final v = app.volume;
    return Row(children: [
      IconButton(
        tooltip: '소리 1 줄이기',
        onPressed: v > 0 ? () => app.setVolume(v - 1) : null,
        icon: Icon(v == 0 ? Icons.volume_off_rounded : Icons.volume_down_rounded, color: c.muted),
      ),
      Expanded(
        child: Slider(
          value: v.toDouble(),
          min: 0,
          max: 100,
          divisions: 100,
          label: '$v',
          onChanged: (x) => app.setVolume(x.round()),
        ),
      ),
      IconButton(
        tooltip: '소리 1 키우기',
        onPressed: v < 100 ? () => app.setVolume(v + 1) : null,
        icon: Icon(Icons.volume_up_rounded, color: c.muted),
      ),
      GestureDetector(
        onTap: () async {
          final s = await askText(context, title: '소리 크기 (0~100)', initial: '$v', ok: '적용');
          final n = int.tryParse(s?.trim() ?? '');
          if (n != null) app.setVolume(n);
        },
        child: Container(
          width: 46,
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(color: c.bg2, borderRadius: BorderRadius.circular(10)),
          alignment: Alignment.center,
          child: Text('$v',
              style: disp(context, 16).copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
        ),
      ),
    ]);
  }
}

class ToolsRow extends StatelessWidget {
  final bool lyricsOn;
  final VoidCallback onLyrics;
  const ToolsRow({super.key, required this.lyricsOn, required this.onLyrics});
  @override
  Widget build(BuildContext context) {
    final t = app.current;
    String sleepLabel() {
      if (app.sleepAfterTrack) return '곡 끝';
      final at = app.sleepAt;
      if (at == null) return '타이머';
      return '${math.max(1, at.difference(DateTime.now()).inMinutes + 1)}분';
    }

    return Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
      _Tool(icon: Icons.lyrics_outlined, label: '가사', on: lyricsOn, onTap: onLyrics),
      _Tool(icon: Icons.equalizer_rounded, label: 'EQ', on: app.eqOn && app.eqPreset != '기본', onTap: () => showEqSheet(context)),
      _Tool(
          icon: Icons.bedtime_outlined,
          label: sleepLabel(),
          on: app.sleepAt != null || app.sleepAfterTrack,
          onTap: () => showSleepSheet(context)),
      _Tool(icon: Icons.speed_rounded, label: '${app.speed}배', on: app.speed != 1.0, onTap: () => showSpeedSheet(context)),
      _Tool(
          icon: Icons.compare_arrows_rounded,
          label: app.abA == null ? 'A-B' : (app.abB == null ? 'B 찍기' : 'A-B 끄기'),
          on: app.abA != null,
          onTap: app.tapAB),
      _Tool(
          icon: Icons.playlist_add_rounded,
          label: '담기',
          on: false,
          onTap: t == null ? () {} : () => pickPlaylist(context, [t.id])),
    ]);
  }
}

class _Tool extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool on;
  final VoidCallback onTap;
  const _Tool({required this.icon, required this.label, required this.on, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final c = RC.of(context);
    final col = on ? c.accent : c.muted;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: col, size: 24),
          const SizedBox(height: 2),
          Text(label, style: body(context, 11, color: col)),
        ]),
      ),
    );
  }
}

// ---------------- 시트들 ----------------
Future<void> showEqSheet(BuildContext context) => showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => ListenableBuilder(
        listenable: app,
        builder: (ctx, _) {
          final c = RC.of(ctx);
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text('이퀄라이저', style: disp(ctx, 20)),
                  const Spacer(),
                  if (app.eq != null) Switch(value: app.eqOn, onChanged: app.setEqOn),
                ]),
                if (app.eq == null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text('EQ는 안드로이드 폰에서 쓸 수 있어요.', style: body(ctx, 14, color: c.muted)),
                  )
                else ...[
                  const SizedBox(height: 8),
                  Wrap(spacing: 6, runSpacing: 6, children: [
                    for (final k in eqPresets.keys)
                      ChoiceChipR(label: k, on: app.eqPreset == k, onTap: () => app.setEqPreset(k)),
                  ]),
                  const SizedBox(height: 14),
                  Opacity(
                    opacity: app.eqOn ? 1 : .4,
                    child: SizedBox(
                      height: 210,
                      child: Row(children: [
                        for (var i = 0; i < 5; i++)
                          Expanded(
                            child: Column(children: [
                              Text('${app.eqGains[i] > 0 ? '+' : ''}${app.eqGains[i].round()}',
                                  style: disp(ctx, 13, color: c.accent)),
                              Expanded(
                                child: RotatedBox(
                                  quarterTurns: 3,
                                  child: Slider(
                                    value: app.eqGains[i],
                                    min: -12,
                                    max: 12,
                                    divisions: 24,
                                    onChanged: app.eqOn ? (v) => app.setEqBand(i, v) : null,
                                  ),
                                ),
                              ),
                              Text('${eqLabels[i]}Hz', style: body(ctx, 11, color: c.muted)),
                            ]),
                          ),
                      ]),
                    ),
                  ),
                ],
              ]),
            ),
          );
        },
      ),
    );

Future<void> showSleepSheet(BuildContext context) => showModalBottomSheet(
      context: context,
      builder: (ctx) => ListenableBuilder(
        listenable: app,
        builder: (ctx, _) {
          final c = RC.of(ctx);
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('잠자기 타이머', style: disp(ctx, 20)),
                const SizedBox(height: 4),
                StreamBuilder(
                  stream: Stream.periodic(const Duration(seconds: 1)),
                  builder: (ctx, _) {
                    final at = app.sleepAt;
                    final txt = app.sleepAfterTrack
                        ? '이 곡이 끝나면 멈춰요'
                        : at == null
                            ? '정한 시간이 지나면 음악이 멈춰요'
                            : '${fmtDur(at.difference(DateTime.now()))} 뒤에 멈춰요';
                    return Text(txt, style: body(ctx, 13, color: c.muted));
                  },
                ),
                const SizedBox(height: 14),
                Wrap(spacing: 6, runSpacing: 8, children: [
                  ChoiceChipR(label: '끄기', on: app.sleepAt == null && !app.sleepAfterTrack, onTap: () => app.setSleep(0)),
                  for (final m in const [10, 15, 30, 45, 60, 90, 120])
                    ChoiceChipR(label: m >= 60 ? '${m ~/ 60}시간${m % 60 > 0 ? ' ${m % 60}분' : ''}' : '$m분', on: false, onTap: () => app.setSleep(m)),
                  ChoiceChipR(label: '이 곡 끝나면', on: app.sleepAfterTrack, onTap: () => app.setSleep(-1)),
                ]),
              ]),
            ),
          );
        },
      ),
    );

Future<void> showSpeedSheet(BuildContext context) => showModalBottomSheet(
      context: context,
      builder: (ctx) => ListenableBuilder(
        listenable: app,
        builder: (ctx, _) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('재생 속도 ${app.speed.toStringAsFixed(2)}배', style: disp(ctx, 20)),
              Slider(
                value: app.speed,
                min: .5,
                max: 2,
                divisions: 30,
                label: '${app.speed.toStringAsFixed(2)}배',
                onChanged: (v) => app.setSpeed((v * 20).round() / 20),
              ),
              Wrap(spacing: 6, runSpacing: 6, children: [
                for (final s in const [.5, .75, 1.0, 1.25, 1.5, 2.0])
                  ChoiceChipR(label: '$s배', on: app.speed == s, onTap: () => app.setSpeed(s)),
              ]),
            ]),
          ),
        ),
      ),
    );

Future<void> showQueueSheet(BuildContext context) => showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SizedBox(
        height: MediaQuery.of(ctx).size.height * .75,
        child: ListenableBuilder(
          listenable: app,
          builder: (ctx, _) {
            final c = RC.of(ctx);
            return Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 12, 6),
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('재생 목록', style: disp(ctx, 20)),
                      Text('${app.queueName} · ${app.order.length}곡', style: body(ctx, 12, color: c.muted)),
                    ]),
                  ),
                  PillButton(
                      label: '전부 담기',
                      icon: Icons.playlist_add,
                      onTap: () => pickPlaylist(ctx, [for (final q in app.order) app.queue[q]])),
                ]),
              ),
              Expanded(
                child: ReorderableListView.builder(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 20),
                  itemCount: app.order.length,
                  onReorder: app.moveInQueue,
                  itemBuilder: (ctx, i) {
                    final t = app.byId(app.queue[app.order[i]]);
                    if (t == null) return SizedBox.shrink(key: ValueKey('x$i'));
                    return TrackTile(
                      key: ValueKey('q${app.order[i]}_$i'),
                      longPressMenu: false,
                      t: t,
                      onTap: () => app.playAt(i),
                      trailing: i == app.idx
                          ? Padding(
                              padding: const EdgeInsets.all(12), child: Icon(Icons.graphic_eq, color: c.accent))
                          : IconButton(
                              tooltip: '목록에서 빼기',
                              icon: Icon(Icons.close_rounded, color: c.muted),
                              onPressed: () => app.removeFromQueue(i)),
                    );
                  },
                ),
              ),
            ]);
          },
        ),
      ),
    );
