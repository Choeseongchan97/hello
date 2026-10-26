import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';

import 'home.dart';
import 'state.dart';
import 'theme.dart';
import 'widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.renang.renyang_musics.audio',
    androidNotificationChannelName: '르냥뮤직스 재생',
    androidNotificationOngoing: true,
    androidStopForegroundOnPause: true,
  );
  app = AppState();
  runApp(const RenyangApp());
}

class RenyangApp extends StatelessWidget {
  const RenyangApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '르냥뮤직스',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: messengerKey,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: ThemeMode.system,
      home: const Boot(),
    );
  }
}

class Boot extends StatefulWidget {
  const Boot({super.key});
  @override
  State<Boot> createState() => _BootState();
}

class _BootState extends State<Boot> {
  late final Future<void> ready = app.init();
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: ready,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.done) {
          if (snap.hasError) {
            return Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('시작하다가 문제가 생겼어요\n${snap.error}', textAlign: TextAlign.center),
                ),
              ),
            );
          }
          return const HomePage();
        }
        final c = RC.of(context);
        return Scaffold(
          body: Container(
            decoration: pageGradient(context),
            child: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const CatFace(size: 120),
                const SizedBox(height: 14),
                Text('르냥뮤직스', style: disp(context, 28)),
                const SizedBox(height: 4),
                Text('골골송 준비 중…', style: body(context, 13, color: c.muted)),
              ]),
            ),
          ),
        );
      },
    );
  }
}
