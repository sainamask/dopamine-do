import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../state/tasks_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_text.dart';
import '../action_chamber/action_chamber_screen.dart';
import '../glory_gallery/glory_gallery_screen.dart';
import '../hype_desk/hype_desk_screen.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ShellTab tab = ref.watch(shellTabProvider);
    return Scaffold(
      body: IndexedStack(
        index: tab.index,
        children: const <Widget>[
          HypeDeskScreen(),
          ActionChamberScreen(),
          GloryGalleryScreen(),
        ],
      ),
      bottomNavigationBar: const _BrutalNavBar(),
    );
  }
}

class _BrutalNavBar extends ConsumerWidget {
  const _BrutalNavBar();

  static const List<_TabSpec> _tabs = <_TabSpec>[
    _TabSpec(
      ShellTab.hype,
      'HYPE',
      PhosphorIconsBold.fire,
      AppColors.limeShock,
    ),
    _TabSpec(
      ShellTab.action,
      'ACTION',
      PhosphorIconsBold.lightning,
      AppColors.electricPink,
    ),
    _TabSpec(
      ShellTab.glory,
      'GLORY',
      PhosphorIconsBold.trophy,
      AppColors.toxicLime,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ShellTab current = ref.watch(shellTabProvider);
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.paper,
        border: Border(
          top: BorderSide(color: AppColors.ink, width: AppShadows.borderThick),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: <Widget>[
              for (final _TabSpec t in _tabs)
                Expanded(
                  child: _NavTab(
                    spec: t,
                    selected: current == t.tab,
                    onTap: () {
                      if (current == t.tab) return;
                      HapticFeedback.selectionClick();
                      ref.read(shellTabProvider.notifier).set(t.tab);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabSpec {
  const _TabSpec(this.tab, this.label, this.icon, this.color);
  final ShellTab tab;
  final String label;
  final IconData icon;
  final Color color;
}

class _NavTab extends StatelessWidget {
  const _NavTab({
    required this.spec,
    required this.selected,
    required this.onTap,
  });

  final _TabSpec spec;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? spec.color : AppColors.white,
            border: AppShadows.solid(width: AppShadows.borderRegular),
            boxShadow: selected ? <BoxShadow>[] : AppShadows.hard(offset: 3),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(spec.icon, size: 18, color: AppColors.ink),
              const SizedBox(height: 2),
              Text(spec.label, style: AppText.micro),
            ],
          ),
        ),
      ),
    );
  }
}
