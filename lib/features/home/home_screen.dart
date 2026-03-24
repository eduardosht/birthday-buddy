import 'package:birthday/core/theme/app_colors.dart';
import 'package:birthday/core/theme/app_text_styles.dart';
import 'package:birthday/providers/account_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountAsync = ref.watch(accountProvider);
    final isPro = accountAsync.valueOrNull?.isPro ?? false;
    final isFree = !isPro;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.outline, width: 1)),
          color: AppColors.surface,
        ),
        child: NavigationBar(
          backgroundColor: AppColors.surface,
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: _onTap,
          indicatorColor: AppColors.primaryLight,
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Início',
            ),
            const NavigationDestination(
              icon: Icon(Icons.people_outline_rounded),
              selectedIcon: Icon(Icons.people_rounded),
              label: 'Grupos',
            ),
            NavigationDestination(
              icon: _AccountIcon(isPro: isPro, showBadge: isFree),
              selectedIcon: _AccountIcon(isPro: isPro, showBadge: isFree, selected: true),
              label: 'Conta',
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountIcon extends StatelessWidget {
  const _AccountIcon({
    required this.isPro,
    required this.showBadge,
    this.selected = false,
  });

  final bool isPro;
  final bool showBadge;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(
          selected ? Icons.person_rounded : Icons.person_outline_rounded,
        ),
        if (showBadge)
          Positioned(
            top: -4,
            right: -6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'FREE',
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 7,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1C1C1E),
                  letterSpacing: 0.5,
                ),
              ),
            ),
          )
        else if (isPro)
          Positioned(
            top: -4,
            right: -6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.workspace_premium_rounded,
                  size: 8, color: Color(0xFFF0B429)),
            ),
          ),
      ],
    );
  }
}

// AppBar helper used across screens
PreferredSizeWidget buildAppBar(
  String title, {
  List<Widget>? actions,
  bool showBack = true,
  Color? backgroundColor,
}) {
  return AppBar(
    title: Text(title, style: AppTextStyles.titleLarge),
    backgroundColor: backgroundColor ?? AppColors.background,
    actions: actions,
    automaticallyImplyLeading: showBack,
  );
}
