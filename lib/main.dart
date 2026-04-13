import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'shared/utils/sound_utils.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Allow both portrait and landscape (tablet-first design)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Immersive UI — hide status/navigation bars during gameplay
  await SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
  );

  await SoundUtils.init();

  runApp(
    const ProviderScope(
      child: SnapPuzzleApp(),
    ),
  );
}
