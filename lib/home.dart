import 'package:flutter/material.dart';

import 'models.dart';
import 'state.dart';
import 'theme.dart';
import 'widgets.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  static const tabs = ['노래', '플레이리스트', '앨범', '가수', '폴더', '즐겨찾기', '최근 재생', '많이 들은 곡'];
  late final TabController tc = TabController(length: tabs.length, vsync: this);

  @override
  void dispose() {
    tc.dispose();
    super.dispose();
  }

  void _addMenu() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        final c = RC.of(ctx);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('노래 넣기', style: disp(ctx, 20)),
              const SizedBox(height: 8),
              ListTile(
                leading: Icon(Icons.travel_explore_rounded, color: c.accent),
                title: Text('폰에 있는 음악 자동으로 찾기', style: disp(ctx, 16)),
                subtitle: const Text('Music, Download 등 폴더의 MP3를 한 번에 넣어요'),
                onTap: () {
                  Navigator.pop(ctx);
                  app.scanDevice();
                },
              ),
              ListTile(
                leading: Icon(Icons.library_music_rounded, color: c.accent),
                title: Text('파일 골라서 넣기', style: disp(ctx, 16)),
                subtitle: const Text('MP3와 같은 이름의 .lrc 가사도 같이 고르면 자동으로 붙어요'),
                onTap: () {
                  Navigator.pop(ctx);
                  app.importFiles();
                },
              ),
              ListTile(
                leading: Icon(Icons.playlist_add_rounded, color: c.accent),
                title: Text('새 플레이리스트 만들기', style: disp(ctx, 16)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final n = await askText(context, title: '새 플레이리스트', hint: '예: 비 오는 날 골골', ok: '만들기');
                  if (n != null) app.createPlaylist(n);
                },
              ),
            ]),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = RC.of(context);
    return Scaffold(
      body: Container(
        decoration: pageGradient(context),
        child: SafeArea(
          bottom: false,
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 10, 4),
              child: Row(children: [
                const Paw(size: 34),
                const SizedBox(width: 8),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('르냥뮤직스', style: disp(context, 24)),
                  Text('RENYANG MUSICS', style: body(context, 10, color: c.muted).copyWith(letterSpacing: 1.5)),
                ]),
                const Spacer(),
                IconButton(
                  tooltip: '찾기',
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SearchPage())),
                  icon: const Icon(Icons.search_rounded, size: 27),
                ),
                Material(
                  color: c.accent,
                  shape: const StadiumBorder(),
                  elevation: 3,
                  shadowColor: c.accent.withAlpha(90),
                  child: InkWell(
                    customBorder: const StadiumBorder(),
                    onTap: _addMenu,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      child: Text('+ 노래 넣기', style: disp(context, 15, color: c.accentInk)),
                    ),
                  ),
                ),
              ]),
            ),
            ListenableBuilder(
              listenable: app,
              builder: (context, _) => app.scanning
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Row(children: [
                        SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2.5, color: c.accent)),
                        const SizedBox(width: 10),
                        Text('폰에서 음악을 찾고 있어요…', style: body(context, 13, color: c.muted)),
                      ]),
                    )
                  : const SizedBox.shrink(),
            ),
            TabBar(
              controller: tc,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              dividerColor: Colors.transparent,
              labelColor: c.accentInk,
              unselectedLabelColor: c.muted,
              labelStyle: disp(context, 15),
              unselectedLabelStyle: disp(context, 15),
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(color: c.accent, borderRadius: BorderRadius.circular(99)),
              labelPadding: const EdgeInsets.symmetric(horizontal: 14),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              splashBorderRadius: BorderRadius.circular(99),
              tabs: [for (final t in tabs) Tab(height: 36, text: t)],
            ),
            Expanded(
              child: ListenableBuilder(
                listenable: app,
                builder: (context, _) => TabBarView(controller: tc, children: [
                  const SongsTab(),
                  const PlaylistsTab(),
                  GroupTab(
                    groups: app.groupBy((t) => t.albumName),
                    icon: Icons.album_rounded,
                    sub: (l) => '${l.first.artist} · ${l.length}곡',
                    grid: true,
                  ),
                  GroupTab(groups: app.groupBy((t) => t.artist), icon: Icons.mic_rounded, sub: (l) => '${l.length}곡'),
                  GroupTab(groups: app.groupBy((t) => t.builtin ? '르냥뮤직스' : (t.external ? t.folder : '직접 넣은 노래')), icon: Icons.folder_rounded, sub: (l) => '${l.length}곡'),
                  SimpleList(
                    list: app.favoriteTracks,
                    name: '즐겨찾기',
                    emptyTitle: '즐겨찾기가 비어 있어요',
                    emptyText: '노래 옆 ⋮ 메뉴나 재생 화면의 하트를 눌러 담아보세요',
                  ),
                  SimpleList(
                    list: app.recentTracks,
                    name: '최근 재생',
                    emptyTitle: '최근에 들은 노래가 없어요',
                    emptyText: '노래를 들으면 여기에 차곡차곡 쌓여요',
                  ),
                  SimpleList(
                    list: app.topTracks,
                    name: '많이 들은 곡',
                    emptyTitle: '아직 기록이 없어요',
                    emptyText: '많이 들은 노래 순위가 여기에 나와요',
                    ranked: true,
                  ),
                ]),
              ),
            ),
          ]),
        ),
      ),
      bottomNavigationBar: const MiniPlayer(),
    );
  }
}

// ---------------- 노래 탭 ----------------
class SongsTab extends StatelessWidget {
  const SongsTab({super.key});
  @override
  Widget build(BuildContext context) {
    final list = app.sorted(app.tracks);
    if (list.length <= 1) {
      return Column(children: [
        ListHeader(list: list, name: '전체 노래', showSort: true),
        for (final t in list)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: TrackTile(t: t, onTap: () => app.setQueue(list.map((e) => e.id).toList(), startId: t.id, name: '전체 노래')),
          ),
        Expanded(
          child: EmptyState(
            title: '내 노래를 넣어볼까냥?',
            text: '폰에 있는 MP3를 자동으로 찾거나\n파일을 골라서 넣을 수 있어요',
            actions: [
              PillButton(label: '자동으로 찾기', icon: Icons.travel_explore_rounded, filled: true, onTap: app.scanDevice),
              PillButton(label: '파일 고르기', icon: Icons.library_music_rounded, onTap: app.importFiles),
            ],
          ),
        ),
      ]);
    }
    final ids = list.map((e) => e.id).toList();
    return Column(children: [
      ListHeader(list: list, name: '전체 노래', showSort: true),
      Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
          itemCount: list.length,
          itemBuilder: (_, i) => TrackTile(
            t: list[i],
            onTap: () => app.setQueue(ids, startId: list[i].id, name: '전체 노래'),
          ),
        ),
      ),
    ]);
  }
}

class SimpleList extends StatelessWidget {
  final List<Track> list;
  final String name, emptyTitle, emptyText;
  final bool ranked;
  const SimpleList(
      {super.key,
      required this.list,
      required this.name,
      required this.emptyTitle,
      required this.emptyText,
      this.ranked = false});
  @override
  Widget build(BuildContext context) {
    final c = RC.of(context);
    if (list.isEmpty) return EmptyState(title: emptyTitle, text: emptyText);
    final ids = list.map((e) => e.id).toList();
    return Column(children: [
      ListHeader(list: list, name: name),
      Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
          itemCount: list.length,
          itemBuilder: (_, i) => TrackTile(
            t: list[i],
            leading: ranked
                ? SizedBox(
                    width: 30,
                    child: Text('${i + 1}', textAlign: TextAlign.center, style: disp(context, 17, color: i < 3 ? c.accent : c.muted)))
                : null,
            sub: ranked ? '${list[i].artist} · ${app.playCounts[list[i].id] ?? 0}번 들음' : null,
            onTap: () => app.setQueue(ids, startId: list[i].id, name: name),
          ),
        ),
      ),
    ]);
  }
}

// ---------------- 앨범 · 가수 · 폴더 ----------------
class GroupTab extends StatelessWidget {
  final Map<String, List<Track>> groups;
  final IconData icon;
  final String Function(List<Track>) sub;
  final bool grid;
  const GroupTab({super.key, required this.groups, required this.icon, required this.sub, this.grid = false});

  void _open(BuildContext context, String name) => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => TrackListPage(title: name, ids: groups[name]!.map((t) => t.id).toList())));

  @override
  Widget build(BuildContext context) {
    final c = RC.of(context);
    final keys = groups.keys.toList();
    if (grid) {
      return GridView.builder(
        padding: const EdgeInsets.fromLTRB(14, 6, 14, 16),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 190, mainAxisSpacing: 14, crossAxisSpacing: 14, childAspectRatio: .78),
        itemCount: keys.length,
        itemBuilder: (context, i) {
          final l = groups[keys[i]]!;
          final withCover = l.firstWhere((t) => t.coverPath != null, orElse: () => l.first);
          return InkWell(
            onTap: () => _open(context, keys[i]),
            borderRadius: BorderRadius.circular(18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              AspectRatio(aspectRatio: 1, child: LayoutBuilder(builder: (_, b) => CoverThumb(t: withCover, size: b.maxWidth, radius: 18))),
              const SizedBox(height: 6),
              Text(keys[i], maxLines: 1, overflow: TextOverflow.ellipsis, style: disp(context, 15)),
              Text(sub(l), maxLines: 1, overflow: TextOverflow.ellipsis, style: body(context, 12, color: c.muted)),
            ]),
          );
        },
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 16),
      itemCount: keys.length,
      itemBuilder: (context, i) {
        final l = groups[keys[i]]!;
        return ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          leading: CircleAvatar(backgroundColor: c.bg2, child: Icon(icon, color: c.accent)),
          title: Text(keys[i], maxLines: 1, overflow: TextOverflow.ellipsis, style: disp(context, 16)),
          subtitle: Text(sub(l), style: body(context, 12, color: c.muted)),
          trailing: Icon(Icons.chevron_right_rounded, color: c.muted),
          onTap: () => _open(context, keys[i]),
        );
      },
    );
  }
}

class TrackListPage extends StatelessWidget {
  final String title;
  final List<String> ids;
  const TrackListPage({super.key, required this.title, required this.ids});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListenableBuilder(
        listenable: app,
        builder: (context, _) {
          final list = app.sorted(ids.map(app.byId).whereType<Track>());
          final lids = list.map((e) => e.id).toList();
          return Column(children: [
            ListHeader(list: list, name: title),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                itemCount: list.length,
                itemBuilder: (_, i) => TrackTile(t: list[i], onTap: () => app.setQueue(lids, startId: list[i].id, name: title)),
              ),
            ),
          ]);
        },
      ),
      bottomNavigationBar: const MiniPlayer(),
    );
  }
}

// ---------------- 플레이리스트 ----------------
class PlaylistsTab extends StatelessWidget {
  const PlaylistsTab({super.key});
  @override
  Widget build(BuildContext context) {
    final c = RC.of(context);
    return ListView(padding: const EdgeInsets.fromLTRB(8, 6, 8, 16), children: [
      ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(color: c.accent, borderRadius: BorderRadius.circular(14)),
          child: Icon(Icons.add_rounded, color: c.accentInk, size: 30),
        ),
        title: Text('새 플레이리스트', style: disp(context, 17)),
        subtitle: Text('좋아하는 노래끼리 모아두세요', style: body(context, 12, color: c.muted)),
        onTap: () async {
          final n = await askText(context, title: '새 플레이리스트', hint: '예: 비 오는 날 골골', ok: '만들기');
          if (n == null) return;
          final p = app.createPlaylist(n);
          if (context.mounted) {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => PlaylistPage(p: p)));
          }
        },
      ),
      for (final p in app.playlists)
        ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          leading: _Mosaic(tracks: app.playlistTracks(p)),
          title: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: disp(context, 17)),
          subtitle: Text('${p.trackIds.length}곡', style: body(context, 12, color: c.muted)),
          trailing: IconButton(
            tooltip: '재생',
            icon: Icon(Icons.play_circle_fill_rounded, color: c.accent, size: 34),
            onPressed: p.trackIds.isEmpty ? null : () => app.setQueue(List.of(p.trackIds), name: p.name),
          ),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PlaylistPage(p: p))),
        ),
    ]);
  }
}

class _Mosaic extends StatelessWidget {
  final List<Track> tracks;
  const _Mosaic({required this.tracks});
  @override
  Widget build(BuildContext context) {
    final covers = tracks.where((t) => t.coverPath != null).take(4).toList();
    if (covers.length < 4) return CoverThumb(t: tracks.isEmpty ? null : (covers.isNotEmpty ? covers.first : tracks.first), size: 52, radius: 14);
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: 52,
        height: 52,
        child: GridView.count(
          crossAxisCount: 2,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          children: [for (final t in covers) CoverThumb(t: t, size: 26, radius: 0)],
        ),
      ),
    );
  }
}

class PlaylistPage extends StatelessWidget {
  final Playlist p;
  const PlaylistPage({super.key, required this.p});

  @override
  Widget build(BuildContext context) {
    final c = RC.of(context);
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final list = app.playlistTracks(p);
        return Scaffold(
          appBar: AppBar(
            title: Text(p.name),
            actions: [
              PopupMenuButton<String>(
                onSelected: (v) async {
                  if (v == 'rename') {
                    final n = await askText(context, title: '이름 바꾸기', initial: p.name);
                    if (n != null) app.renamePlaylist(p, n);
                  } else if (v == 'delete') {
                    final ok = await confirm(context, '플레이리스트를 지울까요?', '"${p.name}"만 지워지고 노래는 보관함에 그대로 남아요.');
                    if (ok) {
                      app.deletePlaylist(p);
                      if (context.mounted) Navigator.pop(context);
                    }
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'rename', child: Text('이름 바꾸기')),
                  PopupMenuItem(value: 'delete', child: Text('플레이리스트 지우기')),
                ],
              ),
            ],
          ),
          body: Column(children: [
            ListHeader(list: list, name: p.name),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(children: [
                PillButton(
                  label: '노래 추가',
                  icon: Icons.add_rounded,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddSongsPage(p: p))),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text('꾹 눌러서 순서를 바꿀 수 있어요', style: body(context, 12, color: c.muted))),
              ]),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: list.isEmpty
                  ? const EmptyState(title: '아직 빈 플레이리스트예요', text: '노래 추가를 눌러 담아보세요')
                  : ReorderableListView.builder(
                      padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                      itemCount: list.length,
                      onReorder: (a, b) => app.reorderPlaylist(p, a, b),
                      itemBuilder: (_, i) => TrackTile(
                        key: ValueKey('${p.id}_${list[i].id}_$i'),
                        t: list[i],
                        longPressMenu: false,
                        onTap: () => app.setQueue(List.of(p.trackIds), startId: list[i].id, name: p.name),
                        trailing: IconButton(
                          tooltip: '플레이리스트에서 빼기',
                          icon: Icon(Icons.remove_circle_outline_rounded, color: c.muted),
                          onPressed: () => app.removeFromPlaylist(p, p.trackIds.indexOf(list[i].id)),
                        ),
                      ),
                    ),
            ),
          ]),
          bottomNavigationBar: const MiniPlayer(),
        );
      },
    );
  }
}

class AddSongsPage extends StatefulWidget {
  final Playlist p;
  const AddSongsPage({super.key, required this.p});
  @override
  State<AddSongsPage> createState() => _AddSongsPageState();
}

class _AddSongsPageState extends State<AddSongsPage> {
  final picked = <String>{};
  String q = '';
  @override
  Widget build(BuildContext context) {
    final c = RC.of(context);
    final list = app
        .sorted(app.tracks)
        .where((t) => !widget.p.trackIds.contains(t.id))
        .where((t) => q.isEmpty || '${t.title} ${t.artist} ${t.album}'.toLowerCase().contains(q))
        .toList();
    return Scaffold(
      appBar: AppBar(title: Text('"${widget.p.name}"에 담기')),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: TextField(
            decoration: const InputDecoration(hintText: '곡명, 가수로 찾기', prefixIcon: Icon(Icons.search_rounded)),
            onChanged: (v) => setState(() => q = v.trim().toLowerCase()),
          ),
        ),
        Expanded(
          child: list.isEmpty
              ? const EmptyState(title: '담을 노래가 없어요', text: '보관함의 노래가 이미 다 들어 있어요')
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                  itemCount: list.length,
                  itemBuilder: (_, i) {
                    final t = list[i];
                    final on = picked.contains(t.id);
                    return TrackTile(
                      t: t,
                      longPressMenu: false,
                      onTap: () => setState(() => on ? picked.remove(t.id) : picked.add(t.id)),
                      trailing: Checkbox(
                        value: on,
                        activeColor: c.accent,
                        onChanged: (_) => setState(() => on ? picked.remove(t.id) : picked.add(t.id)),
                      ),
                    );
                  },
                ),
        ),
      ]),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
          child: FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52), shape: const StadiumBorder()),
            onPressed: picked.isEmpty
                ? null
                : () {
                    app.addToPlaylist(widget.p, picked.toList());
                    Navigator.pop(context);
                  },
            child: Text(picked.isEmpty ? '노래를 골라주세요' : '${picked.length}곡 담기', style: disp(context, 17, color: c.accentInk)),
          ),
        ),
      ),
    );
  }
}

// ---------------- 찾기 ----------------
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});
  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  String q = '';
  @override
  Widget build(BuildContext context) {
    final res = q.isEmpty
        ? <Track>[]
        : app.tracks
            .where((t) => '${t.title} ${t.artist} ${t.album} ${t.lrc}'.toLowerCase().contains(q))
            .toList();
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 16),
          child: TextField(
            autofocus: true,
            decoration: const InputDecoration(hintText: '곡명, 가수, 앨범, 가사로 찾기'),
            onChanged: (v) => setState(() => q = v.trim().toLowerCase()),
          ),
        ),
      ),
      body: ListenableBuilder(
        listenable: app,
        builder: (context, _) => q.isEmpty
            ? const EmptyState(title: '무슨 노래 찾아요?', text: '가사 한 줄로도 찾을 수 있어요')
            : res.isEmpty
                ? const EmptyState(title: '찾는 노래가 없어요', text: '다른 말로 찾아보세요')
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
                    itemCount: res.length,
                    itemBuilder: (_, i) => TrackTile(
                      t: res[i],
                      onTap: () => app.setQueue(res.map((e) => e.id).toList(), startId: res[i].id, name: '찾은 노래'),
                    ),
                  ),
      ),
      bottomNavigationBar: const MiniPlayer(),
    );
  }
}
