import 'package:birthday/core/theme/app_colors.dart';
import 'package:birthday/core/theme/app_text_styles.dart';
import 'package:birthday/core/utils/birthday_utils.dart';
import 'package:birthday/data/models/person.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

class AlertBanner extends StatelessWidget {
  const AlertBanner({super.key, required this.people});

  final List<Person> people;

  @override
  Widget build(BuildContext context) {
    if (people.isEmpty) return const SizedBox.shrink();

    return Column(
      children: people.map((p) => _SingleAlertBanner(person: p)).toList(),
    );
  }
}

class _SingleAlertBanner extends StatelessWidget {
  const _SingleAlertBanner({required this.person});

  final Person person;

  @override
  Widget build(BuildContext context) {
    final days = person.daysUntilNextBirthday;
    final isUrgent = days <= 1;
    final color = isUrgent ? AppColors.alertRed : AppColors.alertOrange;
    final bgColor = isUrgent
        ? const Color(0xFFFDE8E8)
        : const Color(0xFFFDE8D8);

    return GestureDetector(
      onTap: () => context.push('/celebration/${person.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.25), width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isUrgent ? Icons.notifications_active_rounded : Icons.access_time_rounded,
                color: color,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Aniversário de ${person.name} é ${BirthdayUtils.countdownText(days)}',
                    style: AppTextStyles.titleSmall.copyWith(color: AppColors.textDark),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    'Toque para enviar parabéns',
                    style: AppTextStyles.label,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppColors.textLight, size: 20),
          ],
        ),
      ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.05, end: 0),
    );
  }
}
