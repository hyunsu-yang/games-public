import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_strings.dart';
import '../../core/models/settings.dart';
import '../home/home_provider.dart';

class ParentalScreen extends ConsumerStatefulWidget {
  const ParentalScreen({super.key});

  @override
  ConsumerState<ParentalScreen> createState() => _ParentalScreenState();
}

class _ParentalScreenState extends ConsumerState<ParentalScreen> {
  bool _unlocked = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.parentalTitle)),
      body: _unlocked ? _SettingsBody() : _LockGate(onUnlock: () {
        setState(() => _unlocked = true);
      }),
    );
  }
}

// ── Lock gate ────────────────────────────────────────────────────────────────

class _LockGate extends StatefulWidget {
  const _LockGate({required this.onUnlock});
  final VoidCallback onUnlock;

  @override
  State<_LockGate> createState() => _LockGateState();
}

class _LockGateState extends State<_LockGate> {
  // Simple math challenge: 3×4 = ?
  final _answer = '12';
  final _controller = TextEditingController();
  bool _wrong = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_controller.text.trim() == _answer) {
      widget.onUnlock();
    } else {
      setState(() => _wrong = true);
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_rounded,
                size: 64, color: AppColors.primary),
            const SizedBox(height: AppSizes.lg),
            Text(
              AppStrings.parentalMathQuestion,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppSizes.md),
            const Text(
              '3 × 4 = ?',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSizes.lg),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              autofocus: true,
              maxLength: 3,
              decoration: InputDecoration(
                counterText: '',
                hintText: '답을 입력하세요',
                errorText: _wrong ? '틀렸어요. 다시 시도해 보세요.' : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: AppSizes.md),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                child: const Text(AppStrings.parentalUnlock),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Settings body ────────────────────────────────────────────────────────────

class _SettingsBody extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsNotifierProvider);
    final profileAsync = ref.watch(userProfileNotifierProvider);

    return settingsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (settings) => ListView(
        padding: const EdgeInsets.all(AppSizes.md),
        children: [
          // ── Statistics ──────────────────────────────────────────────────
          _SectionHeader(AppStrings.statistics),
          profileAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (profile) => Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.md),
                child: Column(
                  children: [
                    _StatRow(
                      label: AppStrings.todayPlayTime,
                      value: _formatDuration(
                          profile.playTimeTodaySeconds),
                    ),
                    const Divider(),
                    _StatRow(
                      label: AppStrings.todayPuzzles,
                      value: '${profile.totalPuzzlesCompleted}개',
                    ),
                    const Divider(),
                    _StatRow(
                      label: '레벨',
                      value:
                          'Lv.${profile.level} ${profile.levelName}',
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: AppSizes.lg),

          // ── Time limit ──────────────────────────────────────────────────
          _SectionHeader(AppStrings.timeLimit),
          Card(
            child: Column(
              children: [
                _TimeLimitTile(
                  label: AppStrings.timeLimitNone,
                  isSelected: settings.dailyLimitMinutes == null,
                  onTap: () => _updateSettings(
                      ref,
                      settings.copyWith(clearDailyLimit: true)),
                ),
                const Divider(height: 1),
                _TimeLimitTile(
                  label: AppStrings.timeLimitHalf,
                  isSelected: settings.dailyLimitMinutes == 30,
                  onTap: () => _updateSettings(
                      ref,
                      settings.copyWith(dailyLimitMinutes: 30)),
                ),
                const Divider(height: 1),
                _TimeLimitTile(
                  label: AppStrings.timeLimitOne,
                  isSelected: settings.dailyLimitMinutes == 60,
                  onTap: () => _updateSettings(
                      ref,
                      settings.copyWith(dailyLimitMinutes: 60)),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSizes.lg),

          // ── Camera / Gallery ─────────────────────────────────────────────
          _SectionHeader(AppStrings.cameraAccess),
          Card(
            child: SwitchListTile(
              title: const Text(AppStrings.cameraAccess),
              subtitle: const Text('카메라 사용을 허용합니다'),
              value: settings.cameraEnabled,
              activeColor: AppColors.primary,
              onChanged: (v) => _updateSettings(
                  ref, settings.copyWith(cameraEnabled: v)),
            ),
          ),

          const SizedBox(height: AppSizes.sm),
          Card(
            child: SwitchListTile(
              title: const Text(AppStrings.saveToGallery),
              subtitle: const Text('사진을 기기 갤러리에도 저장합니다'),
              value: settings.saveToGallery,
              activeColor: AppColors.primary,
              onChanged: (v) => _updateSettings(
                  ref, settings.copyWith(saveToGallery: v)),
            ),
          ),

          const SizedBox(height: AppSizes.lg),

          // ── Accessibility ────────────────────────────────────────────────
          _SectionHeader('접근성'),
          Card(
            child: SwitchListTile(
              title: const Text('고대비 모드'),
              subtitle: const Text('퍼즐 외곽선을 더 뚜렷하게 표시합니다'),
              value: settings.highContrastMode,
              activeColor: AppColors.primary,
              onChanged: (v) => _updateSettings(
                  ref, settings.copyWith(highContrastMode: v)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateSettings(WidgetRef ref, AppSettings settings) async {
    await ref.read(settingsNotifierProvider.notifier).updateSettings(settings);
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m}분 ${s}초';
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
          left: AppSizes.xs, bottom: AppSizes.xs),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.primary,
            ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyLarge),
          Text(value,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  )),
        ],
      ),
    );
  }
}

class _TimeLimitTile extends StatelessWidget {
  const _TimeLimitTile({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      trailing: isSelected
          ? const Icon(Icons.check_circle_rounded,
              color: AppColors.primary)
          : const Icon(Icons.radio_button_unchecked_rounded,
              color: AppColors.textHint),
      onTap: onTap,
    );
  }
}
