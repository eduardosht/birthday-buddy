import 'package:birthday/core/theme/app_colors.dart';
import 'package:birthday/core/theme/app_text_styles.dart';
import 'package:birthday/data/models/person.dart';
import 'package:birthday/features/home/widgets/alert_banner.dart';
import 'package:birthday/features/home/widgets/birthday_calendar.dart';
import 'package:birthday/features/home/widgets/birthday_card.dart';
import 'package:birthday/features/home/widgets/celebration_card.dart';
import 'package:birthday/providers/app_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

class DashboardTab extends ConsumerWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayAsync = ref.watch(todayBirthdaysProvider);
    final alertAsync = ref.watch(alertBirthdaysProvider);
    final upcomingAsync = ref.watch(upcomingBirthdaysProvider);
    final allAsync = ref.watch(allPeopleSortedProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Aniversários', style: AppTextStyles.titleLarge),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            onPressed: () {
              ref.invalidate(allPeopleSortedProvider);
              ref.invalidate(todayBirthdaysProvider);
              ref.invalidate(alertBirthdaysProvider);
              ref.invalidate(upcomingBirthdaysProvider);
            },
          ),
        ],
      ),
      body: allAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (allPeople) {
          if (allPeople.isEmpty) {
            return const _EmptyState();
          }

          final today = todayAsync.valueOrNull ?? [];
          final alerts = alertAsync.valueOrNull ?? [];
          final upcoming = upcomingAsync.valueOrNull ?? [];

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(allPeopleSortedProvider);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                // ── Today's celebrations ───────────────────────────
                if (today.isNotEmpty) ...[
                  TodayCelebrationSection(people: today),
                  const SizedBox(height: 20),
                ],

                // ── Alert banners (≤2 days) ────────────────────────
                if (alerts.isNotEmpty) ...[
                  AlertBanner(people: alerts),
                  const SizedBox(height: 20),
                ],

                // ── Coming up soon – horizontal cards ─────────────
                if (upcoming.isNotEmpty) ...[
                  const _SectionHeader(title: 'Em Breve'),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 190,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: upcoming.length,
                      itemBuilder: (_, i) => BirthdayCard(person: upcoming[i]),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // ── All upcoming – calendar ────────────────────────
                const _SectionHeader(title: 'Todos os Próximos'),
                const SizedBox(height: 12),
                _CalendarCard(people: allPeople),
                const SizedBox(height: 16),

              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Calendar wrapped in a card ─────────────────────────────────────────────

class _CalendarCard extends StatelessWidget {
  const _CalendarCard({required this.people});
  final List<Person> people;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline, width: 1),
      ),
      child: BirthdayCalendar(people: people),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(title, style: AppTextStyles.titleMedium),
      ],
    ).animate().fadeIn(duration: 400.ms);
  }
}


class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              'assets/animations/empty_state.json',
              width: 200,
              height: 200,
              repeat: true,
              errorBuilder: (ctx, e, s) => const Icon(
                  Icons.cake_outlined,
                  size: 80,
                  color: AppColors.textLight),
            ),
            const SizedBox(height: 24),
            Text('Nenhum aniversário ainda!',
                style: AppTextStyles.displayMedium,
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              'Vá para Grupos para adicionar pessoas\ne começar a acompanhar aniversários.',
              style: AppTextStyles.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.go('/groups'),
              icon: const Icon(Icons.add),
              label: const Text('Criar Primeiro Grupo'),
            ),
          ],
        ),
      ),
    );
  }
}
