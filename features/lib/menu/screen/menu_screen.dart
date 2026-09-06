import 'package:core/core.dart';
import 'package:core_ui/core_ui.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  int _bestScore = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final GameStatsModel stats =
        await appLocator<StatsRepository>().getStats();
    if (mounted) setState(() => _bestScore = stats.bestScore);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            const Spacer(flex: 2),
            Text.rich(
              TextSpan(
                children: <InlineSpan>[
                  const TextSpan(text: 'Was'),
                  TextSpan(
                    text: 'Drop',
                    style: AppFonts.title.copyWith(color: AppColors.accent),
                  ),
                ],
              ),
              style: AppFonts.title,
            ),
            const SizedBox(height: 16),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.stroke, width: 2),
              ),
              child: Text('🏆 рекорд $_bestScore', style: AppFonts.best),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 60),
              child: SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  label: 'ИГРАТЬ',
                  height: 64,
                  onPressed: () => context.goNamed('game'),
                ),
              ),
            ),
            const Spacer(flex: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                IconCircleButton(
                  onPressed: () {
                    // TODO: звук вкл/выкл (SettingsRepository)
                  },
                  child: const Text('🔊', style: TextStyle(fontSize: 20)),
                ),
                const SizedBox(width: 16),
                IconCircleButton(
                  onPressed: () {
                    // TODO: экран настроек
                  },
                  child: const Text('⚙️', style: TextStyle(fontSize: 20)),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
