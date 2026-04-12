import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_theme.dart';
import 'features/home/home_screen.dart';

class SnapPuzzleApp extends ConsumerWidget {
  const SnapPuzzleApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'SnapPuzzle',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const HomeScreen(),
      // Lock to portrait-primary on phones; allow landscape on tablets
      // (handled at platform level via AndroidManifest / iOS Info.plist)
    );
  }
}
