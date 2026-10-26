import 'dart:io';

import 'package:flutter/material.dart';

import 'models.dart';
import 'player_page.dart';
import 'state.dart';
import 'theme.dart';

// ---------------- 르냥이 얼굴 ----------------
class CatPainter extends CustomPainter {
  final Color ink, accent;
  CatPainter(this.ink, this.accent);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 120;
    canvas.save();
    canvas.scale(s);
    final stroke = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    final head = Path()
      ..moveTo(22, 50)
      ..lineTo(26, 16)
      ..lineTo(50, 34)
      ..quadraticBezierTo(60, 31, 70, 34)
      ..lineTo(94, 16)
      ..lineTo(98, 50)
      ..quadraticBezierTo(106, 66, 98, 82)
      ..quadraticBezierTo(86, 104, 60, 104)
      ..quadraticBezierTo(34, 104, 22, 82)
      ..quadraticBezierTo(14, 66, 22, 50)
      ..close();
    canvas.drawPath(head, Paint()..color = Colors.white);
    canvas.drawPath(head, stroke);
    final ear = Paint()..color = accent;
    canvas.drawPath(Path()..moveTo(30, 26)..lineTo(32, 40)..lineTo(42, 34)..close(), ear);
    canvas.drawPath(Path()..moveTo(90, 26)..lineTo(88, 40)..lineTo(78, 34)..close(), ear);
    final inkP = Paint()..color = ink;
    canvas.drawOval(Rect.fromCenter(center: const Offset(44, 64), width: 8.4, height: 11), inkP);
    canvas.drawOval(Rect.fromCenter(center: const Offset(76, 64), width: 8.4, height: 11), inkP);
    final w = Paint()..color = Colors.white;
    canvas.drawCircle(const Offset(45.5, 62), 1.5, w);
    canvas.drawCircle(const Offset(77.5, 62), 1.5, w);
    final mouth = Path()
      ..moveTo(54, 74)
      ..quadraticBezierTo(57, 78, 60, 74)
      ..quadraticBezierTo(63, 78, 66, 74);
    canvas.drawPath(
        mouth,
        Paint()
          ..color = ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round);
    final blush = Paint()..color = accent.withAlpha(140);
    canvas.drawOval(Rect.fromCenter(center: const Offset(34, 76), width: 14, height: 8), blush);
    canvas.drawOval(Rect.fromCenter(center: const Offset(86, 76), width: 14, height: 8), blush);
    final wh = Paint()
      ..color = ink
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(14, 66), const Offset(28, 68), wh);
    canvas.drawLine(const Offset(14, 76), const Offset(28, 74), wh);
    canvas.drawLine(const Offset(106, 66), const Offset(92, 68), wh);
    canvas.drawLine(const Offset(106, 76), const Offset(92, 74), wh);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CatPainter o) => o.ink != ink || o.accent != accent;
}

class CatFace extends StatelessWidget {
  final double size;
  const CatFace({super.key, required this.size});
  @override
  Widget build(BuildContext context) {
    final c = RC.of(context);
    return SizedBox(width: size, height: size, child: CustomPaint(painter: CatPainter(c.ink, c.accent)));
  }
}

class PawPainter extends CustomPainter {
  final Color fill, ink;
  PawPainter(this.fill, this.ink);
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 40;
    canvas.scale(s);
    final f = Paint()..color = fill;
    final st = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    void both(void Function(Paint) d) {
      d(f);
      d(st);
    }

    both((p) => canvas.drawOval(Rect.fromCenter(center: const Offset(20, 26), width: 18, height: 15), p));
    for (final o in const [Offset(9, 16), Offset(16, 10), Offset(24, 10), Offset(31, 16)]) {
      both((p) => canvas.drawCircle(o, 4, p));
    }
  }

  @override
  bool shouldRepaint(covariant PawPainter o) => o.fill != fill;
}

class Paw extends StatelessWidget {
  final double size;
  const Paw({super.key, this.size = 34});
  @override
  Widget build(BuildContext context) {
    final c = RC.of(context);
    return SizedBox(width: size, height: size, child: CustomPaint(painter: PawPainter(c.accent, c.ink)));
  }
}

// ---------------- 썸네일 · 곡 줄 ----------------
class CoverThumb extends StatelessWidget {
  final Track? t;
  final double size;
  final double radius;
  const CoverThumb({super.key, required this.t, this.size = 46, this.radius = 13});
  @override
  Widget build(BuildContext context) {
    final c = RC.of(context);
    final cp = t?.coverPath;
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: c.bg2,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: c.line, width: 2),
      ),
      child: cp != null
          ? Image.file(File(cp),
              fit: BoxFit.cover,
              gaplessPlayback: true,
              errorBuilder: (_, __, ___) => Center(child: CatFace(size: size * .74)))
          : Center(child: CatFace(size: size * .74)),
    );
  }
}

class Tag extends StatelessWidget {
  final String text;
  const Tag(this.text, {super.key});
  @override
  Widget build(BuildContext context) {
    final c = RC.of(context);
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
      decoration: BoxDecoration(color: c.butter, borderRadius: BorderRadius.circular(99)),
      child: Text(text, style: body(context, 10.5, color: const Color(0xFF4A3430))),
    );
  }
}

class TrackTile extends StatelessWidget {
  final Track t;
  final VoidCallback onTap;
  final Widget? trailing;
  final Widget? leading;
  final String? sub;
  final bool longPressMenu;
  const TrackTile(
      {super.key, required this.t, required this.onTap, this.trailing, this.leading, this.sub, this.longPressMenu = true});

  @override
  Widget build(BuildContext context) {
    final c = RC.of(context);
    final cur = app.current?.id == t.id;
    return InkWell(
      onTap: onTap,
      onLongPress: longPressMenu ? () => showTrackMenu(context, t) : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: BoxDecoration(color: cur ? c.bg2 : null, borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          if (leading != null) leading!,
          Stack(children: [
            CoverThumb(t: t),
            if (cur && app.player.playing)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(13)),
                  child: const Icon(Icons.graphic_eq, color: Colors.white, size: 22),
                ),
              ),
          ]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(
                  child: Text(t.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: disp(context, 16, color: cur ? c.accent : c.ink)),
                ),
                if (t.builtin) const Tag('오리지널'),
                if (app.favorites.contains(t.id))
                  Padding(padding: const EdgeInsets.only(left: 4), child: Icon(Icons.favorite, size: 13, color: c.accent)),
              ]),
              const SizedBox(height: 2),
              Text(
                sub ?? '${t.artist}${t.lrc.isNotEmpty ? ' · 가사' : ''}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: body(context, 12, color: c.muted),
              ),
            ]),
          ),
          trailing ??
              IconButton(
                icon: Icon(Icons.more_vert_rounded, color: c.muted),
                onPressed: () => showTrackMenu(context, t),
                tooltip: '더 보기',
              ),
        ]),
      ),
    );
  }
}

class PillButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool filled;
  const PillButton({super.key, required this.label, this.icon, this.onTap, this.filled = false});
  @override
  Widget build(BuildContext context) {
    final c = RC.of(context);
    final fg = filled ? c.accentInk : c.ink;
    return Material(
      color: filled ? c.accent : c.surface,
      shape: StadiumBorder(side: BorderSide(color: filled ? c.accent : c.line, width: 2)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (icon != null) ...[Icon(icon, size: 17, color: fg), const SizedBox(width: 4)],
            Text(label, style: disp(context, 14, color: fg)),
          ]),
        ),
      ),
    );
  }
}

class ChoiceChipR extends StatelessWidget {
  final String label;
  final bool on;
  final VoidCallback onTap;
  const ChoiceChipR({super.key, required this.label, required this.on, required this.onTap});
  @override
  Widget build(BuildContext context) => PillButton(label: label, filled: on, onTap: onTap);
}

class EmptyState extends StatelessWidget {
  final String title;
  final String text;
  final List<Widget> actions;
  const EmptyState({super.key, required this.title, required this.text, this.actions = const []});
  @override
  Widget build(BuildContext context) {
    final c = RC.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Opacity(opacity: .8, child: const CatFace(size: 84)),
          const SizedBox(height: 10),
          Text(title, style: disp(context, 18)),
          const SizedBox(height: 6),
          Text(text, textAlign: TextAlign.center, style: body(context, 13, color: c.muted)),
          const SizedBox(height: 14),
          Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: actions),
        ]),
      ),
    );
  }
}

class ListHeader extends StatelessWidget {
  final List<Track> list;
  final String name;
  final bool showSort;
  const ListHeader({super.key, required this.list, required this.name, this.showSort = false});
  @override
  Widget build(BuildContext context) {
    final c = RC.of(context);
    final ids = list.map((t) => t.id).toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 8, 6),
      child: Row(children: [
        Text('${list.length}곡', style: body(context, 13, color: c.muted)),
        if (showSort)
          PopupMenuButton<String>(
            tooltip: '정렬',
            initialValue: app.sortMode,
            onSelected: app.setSort,
            itemBuilder: (_) => [for (final e in sortNames.entries) PopupMenuItem(value: e.key, child: Text(e.value))],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.swap_vert_rounded, size: 17, color: c.muted),
                Text(sortNames[app.sortMode] ?? '', style: body(context, 13, color: c.muted)),
              ]),
            ),
          ),
        const Spacer(),
        PillButton(
            label: '셔플',
            icon: Icons.shuffle_rounded,
            onTap: list.isEmpty ? null : () => app.playShuffled(ids, name: name)),
        const SizedBox(width: 6),
        PillButton(
            label: '전체 재생',
            icon: Icons.play_arrow_rounded,
            filled: true,
            onTap: list.isEmpty
                ? null
                : () {
                    if (app.shuffle) app.toggleShuffle();
                    app.setQueue(ids, name: name);
                  }),
      ]),
    );
  }
}

// ---------------- 미니 플레이어 ----------------
class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});
  @override
  Widget build(BuildContext context) {
    final c = RC.of(context);
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final t = app.current;
        if (t == null) return const SizedBox.shrink();
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: Material(
              color: c.surface,
              elevation: 6,
              shadowColor: c.accent.withAlpha(70),
              borderRadius: BorderRadius.circular(22),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => openPlayer(context),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  StreamBuilder<Duration>(
                    stream: app.player.positionStream,
                    builder: (context, snap) {
                      final d = app.player.duration?.inMilliseconds ?? 0;
                      final p = snap.data?.inMilliseconds ?? 0;
                      return LinearProgressIndicator(
                        value: d > 0 ? (p / d).clamp(0.0, 1.0).toDouble() : 0,
                        minHeight: 3,
                        backgroundColor: c.line,
                        color: c.accent,
                      );
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
                    child: Row(children: [
                      Hero(tag: 'cover', child: CoverThumb(t: t, size: 44, radius: 22)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: disp(context, 15)),
                          Text(t.artist,
                              maxLines: 1, overflow: TextOverflow.ellipsis, style: body(context, 12, color: c.muted)),
                        ]),
                      ),
                      IconButton(
                        tooltip: app.player.playing ? '일시정지' : '재생',
                        onPressed: app.togglePlay,
                        icon: Icon(app.player.playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            size: 32, color: c.accent),
                      ),
                      IconButton(
                        tooltip: '다음 곡',
                        onPressed: app.next,
                        icon: Icon(Icons.skip_next_rounded, size: 28, color: c.ink),
                      ),
                    ]),
                  ),
                ]),
              ),
            ),
          ),
        );
      },
    );
  }
}

void openPlayer(BuildContext context) {
  Navigator.of(context).push(PageRouteBuilder(
    pageBuilder: (_, __, ___) => const PlayerPage(),
    transitionsBuilder: (_, a, __, child) => SlideTransition(
      position: Tween(begin: const Offset(0, 1), end: Offset.zero).animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
      child: child,
    ),
  ));
}

// ---------------- 대화상자 · 메뉴 ----------------
Future<String?> askText(BuildContext context,
    {required String title, String initial = '', String hint = '', bool multiline = false, String ok = '저장'}) {
  final ctl = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title, style: disp(ctx, 19)),
      content: SizedBox(
        width: 420,
        child: TextField(
          controller: ctl,
          autofocus: true,
          minLines: multiline ? 8 : 1,
          maxLines: multiline ? 14 : 1,
          decoration: InputDecoration(hintText: hint),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
        FilledButton(onPressed: () => Navigator.pop(ctx, ctl.text), child: Text(ok)),
      ],
    ),
  );
}

Future<bool> confirm(BuildContext context, String title, String text, {String ok = '지우기'}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title, style: disp(ctx, 19)),
      content: Text(text),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(ok)),
      ],
    ),
  );
  return r ?? false;
}

Future<void> editInfoDialog(BuildContext context, Track t) async {
  final a = TextEditingController(text: t.title);
  final b = TextEditingController(text: t.artist);
  final al = TextEditingController(text: t.album);
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('곡 정보 고치기', style: disp(ctx, 19)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: a, decoration: const InputDecoration(labelText: '곡명')),
        const SizedBox(height: 10),
        TextField(controller: b, decoration: const InputDecoration(labelText: '가수')),
        const SizedBox(height: 10),
        TextField(controller: al, decoration: const InputDecoration(labelText: '앨범')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('저장')),
      ],
    ),
  );
  if (ok == true) app.editInfo(t, a.text, b.text, al.text);
}

Future<void> pickPlaylist(BuildContext context, List<String> ids) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => ListenableBuilder(
      listenable: app,
      builder: (ctx, _) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * .7),
          child: ListView(shrinkWrap: true, padding: const EdgeInsets.fromLTRB(12, 0, 12, 16), children: [
            Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                child: Text('플레이리스트에 담기', style: disp(ctx, 19))),
            ListTile(
              leading: CircleAvatar(
                  backgroundColor: RC.of(ctx).accent, child: Icon(Icons.add, color: RC.of(ctx).accentInk)),
              title: Text('새 플레이리스트 만들기', style: disp(ctx, 16)),
              onTap: () async {
                final name = await askText(ctx, title: '새 플레이리스트', hint: '예: 비 오는 날 골골', ok: '만들기');
                if (name == null) return;
                final p = app.createPlaylist(name);
                app.addToPlaylist(p, ids);
                if (ctx.mounted) Navigator.pop(ctx);
              },
            ),
            for (final p in app.playlists)
              ListTile(
                leading: CoverThumb(t: app.playlistTracks(p).firstOrNull, size: 42),
                title: Text(p.name, style: disp(ctx, 16)),
                subtitle: Text('${p.trackIds.length}곡'),
                onTap: () {
                  app.addToPlaylist(p, ids);
                  Navigator.pop(ctx);
                },
              ),
          ]),
        ),
      ),
    ),
  );
}

Future<void> showTrackMenu(BuildContext context, Track t) async {
  final c = RC.of(context);
  Widget item(IconData i, String label, VoidCallback f, {Color? color}) => ListTile(
        leading: Icon(i, color: color ?? c.ink),
        title: Text(label, style: body(context, 15, color: color ?? c.ink)),
        onTap: () {
          Navigator.pop(context);
          f();
        },
      );
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: CoverThumb(t: t, size: 48),
            title: Text(t.title, style: disp(ctx, 17), maxLines: 2),
            subtitle: Text('${t.artist}${t.album.isNotEmpty ? ' · ${t.album}' : ''}'),
          ),
          const Divider(indent: 16, endIndent: 16),
          item(Icons.play_arrow_rounded, '바로 재생', () => app.setQueue([t.id], name: t.title)),
          item(Icons.queue_play_next_rounded, '다음 곡으로 재생', () => app.playNext(t)),
          item(Icons.add_to_queue_rounded, '재생 목록 끝에 넣기', () => app.addToQueue(t)),
          item(Icons.playlist_add_rounded, '플레이리스트에 담기', () => pickPlaylist(context, [t.id])),
          item(app.favorites.contains(t.id) ? Icons.favorite : Icons.favorite_border,
              app.favorites.contains(t.id) ? '즐겨찾기 빼기' : '즐겨찾기', () => app.toggleFavorite(t),
              color: c.accent),
          item(Icons.lyrics_outlined, '가사 파일(.lrc) 붙이기', () => app.pickLyricsFile(t)),
          item(Icons.edit_note_rounded, '가사 직접 쓰기', () async {
            final s = await askText(context,
                title: '가사', initial: t.lrc, hint: '[00:12.30] 가사 한 줄\n시간 없이 써도 돼요', multiline: true);
            if (s != null) app.setLyrics(t, s);
          }),
          if (!t.builtin) item(Icons.edit_rounded, '곡 정보 고치기', () => editInfoDialog(context, t)),
          if (!t.builtin)
            item(Icons.delete_outline_rounded, '보관함에서 빼기', () async {
              final ok = await confirm(context, '보관함에서 뺄까요?',
                  t.external ? '"${t.title}"를 목록에서만 빼요. 폰에 있는 파일은 그대로 남아요.' : '"${t.title}"를 르냥뮤직스에서 지워요.');
              if (ok) app.removeTrack(t);
            }, color: c.accent),
        ]),
      ),
    ),
  );
}
