import 'package:birthday/core/theme/app_colors.dart';
import 'package:birthday/core/theme/app_text_styles.dart';
import 'package:birthday/data/models/person.dart';
import 'package:birthday/features/home/widgets/birthday_card.dart';
import 'package:birthday/providers/app_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class TodayCelebrationSection extends ConsumerWidget {
  const TodayCelebrationSection({super.key, required this.people});

  final List<Person> people;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (people.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Text('Aniversários de Hoje', style: AppTextStyles.titleMedium),
          ],
        ),
        const SizedBox(height: 12),
        ...people.map((p) => _CelebrationCard(person: p, ref: ref)),
      ],
    );
  }
}

class _CelebrationCard extends StatelessWidget {
  const _CelebrationCard({required this.person, required this.ref});

  final Person person;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final groupAsync = ref.watch(groupByIdProvider(person.groupId));
    final groupColor = groupAsync.whenOrNull(data: (g) => g?.color) ?? AppColors.primary;

    return GestureDetector(
      onTap: () => context.push('/celebration/${person.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 1),
        ),
        child: Row(
          children: [
            PersonAvatar(person: person, color: groupColor, size: 56),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Feliz Aniversário!',
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    person.name,
                    style: AppTextStyles.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Toque para enviar parabéns',
                    style: AppTextStyles.label,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.cake_rounded, color: AppColors.primary, size: 28),
          ],
        ),
      )
          .animate()
          .fadeIn(duration: 500.ms)
          .slideY(begin: -0.05, end: 0, duration: 400.ms, curve: Curves.easeOut),
    );
  }
}
