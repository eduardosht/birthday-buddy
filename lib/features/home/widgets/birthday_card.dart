import 'dart:io';
import 'package:birthday/core/theme/app_colors.dart';
import 'package:birthday/core/theme/app_text_styles.dart';
import 'package:birthday/core/utils/birthday_utils.dart';
import 'package:birthday/core/utils/date_formatter.dart';
import 'package:birthday/data/models/person.dart';
import 'package:birthday/providers/app_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class BirthdayCard extends ConsumerWidget {
  const BirthdayCard({
    super.key,
    required this.person,
    this.compact = false,
  });

  final Person person;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupAsync = ref.watch(groupByIdProvider(person.groupId));
    final groupColor = groupAsync.whenOrNull(data: (g) => g?.color) ?? AppColors.primary;

    final days = person.daysUntilNextBirthday;
    Color chipBg;
    Color chipFg;
    if (days == 0) {
      chipBg = AppColors.primaryLight;
      chipFg = AppColors.primary;
    } else if (days <= 2) {
      chipBg = const Color(0xFFFDE8D8);
      chipFg = AppColors.alertOrange;
    } else if (days <= 7) {
      chipBg = AppColors.accentLight;
      chipFg = const Color(0xFFA07000);
    } else {
      chipBg = AppColors.surfaceVariant;
      chipFg = AppColors.textMedium;
    }

    return GestureDetector(
      onTap: () => context.push('/celebration/${person.id}'),
      child: Container(
        width: compact ? 140 : 160,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.outline, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _AvatarWidget(person: person, color: groupColor, size: 56),
            const SizedBox(height: 10),
            Text(
              person.name,
              style: AppTextStyles.titleSmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 3),
            Text(
              DateFormatter.formatBirthdayShort(person.birthday),
              style: AppTextStyles.label,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            _CountdownChip(days: days, bg: chipBg, fg: chipFg),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.06, end: 0, curve: Curves.easeOut);
  }
}

class _CountdownChip extends StatelessWidget {
  const _CountdownChip({required this.days, required this.bg, required this.fg});

  final int days;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        BirthdayUtils.countdownText(days),
        style: AppTextStyles.chip.copyWith(color: fg, fontSize: 11),
      ),
    );
  }
}

class _AvatarWidget extends StatelessWidget {
  const _AvatarWidget({
    required this.person,
    required this.color,
    required this.size,
  });

  final Person person;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (person.photoPath != null && File(person.photoPath!).existsSync()) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.outline, width: 1.5),
          image: DecorationImage(
            image: FileImage(File(person.photoPath!)),
            fit: BoxFit.cover,
          ),
        ),
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.15),
      ),
      child: Center(
        child: Text(
          person.name.isNotEmpty ? person.name[0].toUpperCase() : '?',
          style: AppTextStyles.titleLarge.copyWith(
            color: color,
            fontSize: size * 0.38,
          ),
        ),
      ),
    );
  }
}

// Reusable avatar widget exposed for other screens
class PersonAvatar extends StatelessWidget {
  const PersonAvatar({
    super.key,
    required this.person,
    required this.color,
    required this.size,
    this.borderWidth = 1.5,
  });

  final Person person;
  final Color color;
  final double size;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    return _AvatarWidget(person: person, color: color, size: size);
  }
}
