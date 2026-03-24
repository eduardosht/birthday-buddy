import 'package:birthday/core/theme/app_colors.dart';
import 'package:birthday/core/theme/app_text_styles.dart';
import 'package:birthday/data/models/person.dart';
import 'package:birthday/providers/app_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class BirthdayCalendar extends ConsumerStatefulWidget {
  const BirthdayCalendar({super.key, required this.people});

  final List<Person> people;

  @override
  ConsumerState<BirthdayCalendar> createState() => _BirthdayCalendarState();
}

class _BirthdayCalendarState extends ConsumerState<BirthdayCalendar> {
  late DateTime _focusedMonth;
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _focusedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  }

  void _prevMonth() => setState(() {
        _focusedMonth =
            DateTime(_focusedMonth.year, _focusedMonth.month - 1);
        _selectedDay = null;
      });

  void _nextMonth() => setState(() {
        _focusedMonth =
            DateTime(_focusedMonth.year, _focusedMonth.month + 1);
        _selectedDay = null;
      });

  /// Returns a map of day-of-month → list of group colors for that month.
  Map<int, List<Color>> _buildDotMap(Map<String, Color> groupColorMap) {
    final map = <int, List<Color>>{};
    for (final p in widget.people) {
      if (p.birthday.month == _focusedMonth.month) {
        final day = p.birthday.day;
        final color = groupColorMap[p.groupId] ?? AppColors.primary;
        map.putIfAbsent(day, () => []).add(color);
      }
    }
    return map;
  }

  /// People with birthday on a given day (any year).
  List<Person> _peopleOnDay(int day) => widget.people
      .where((p) =>
          p.birthday.month == _focusedMonth.month && p.birthday.day == day)
      .toList();

  @override
  Widget build(BuildContext context) {
    // Gather all group colors in one shot
    final groupIds = widget.people.map((p) => p.groupId).toSet();
    final groupColorMap = <String, Color>{};
    for (final id in groupIds) {
      final g = ref.watch(groupByIdProvider(id)).valueOrNull;
      if (g != null) groupColorMap[id] = g.color;
    }

    final dotMap = _buildDotMap(groupColorMap);
    final today = DateTime.now();

    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    // Monday-based: 0=Mon … 6=Sun; firstDay.weekday: 1=Mon … 7=Sun
    final startOffset = (firstDay.weekday - 1) % 7;
    final daysInMonth =
        DateUtils.getDaysInMonth(_focusedMonth.year, _focusedMonth.month);

    final selectedPeople =
        _selectedDay != null ? _peopleOnDay(_selectedDay!.day) : <Person>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header row ──────────────────────────────────────────────
        Row(
          children: [
            IconButton(
              onPressed: _prevMonth,
              icon: const Icon(Icons.chevron_left_rounded),
              iconSize: 20,
              visualDensity: VisualDensity.compact,
              color: AppColors.textMedium,
            ),
            Expanded(
              child: Text(
                _monthLabel(_focusedMonth),
                style: AppTextStyles.titleSmall,
                textAlign: TextAlign.center,
              ),
            ),
            IconButton(
              onPressed: _nextMonth,
              icon: const Icon(Icons.chevron_right_rounded),
              iconSize: 20,
              visualDensity: VisualDensity.compact,
              color: AppColors.textMedium,
            ),
          ],
        ),
        const SizedBox(height: 4),

        // ── Weekday labels ───────────────────────────────────────────
        Row(
          children: const ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom']
              .map((d) => Expanded(
                    child: Center(
                      child: Text(
                        d,
                        style: AppTextStyles.label
                            .copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 6),

        // ── Grid ─────────────────────────────────────────────────────
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            childAspectRatio: 0.85,
          ),
          itemCount: startOffset + daysInMonth,
          itemBuilder: (_, index) {
            if (index < startOffset) return const SizedBox.shrink();
            final day = index - startOffset + 1;
            final date =
                DateTime(_focusedMonth.year, _focusedMonth.month, day);
            final isToday = today.year == date.year &&
                today.month == date.month &&
                today.day == date.day;
            final isSelected = _selectedDay?.day == day;
            final dots = dotMap[day] ?? [];
            final hasBirthday = dots.isNotEmpty;

            return GestureDetector(
              onTap: hasBirthday
                  ? () => setState(() =>
                      _selectedDay = isSelected ? null : date)
                  : null,
              child: AnimatedContainer(
                duration: 180.ms,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryLight
                      : isToday
                          ? AppColors.surfaceVariant
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: isSelected
                      ? Border.all(color: AppColors.primary, width: 1.5)
                      : isToday
                          ? Border.all(
                              color: AppColors.primary.withValues(alpha: 0.4),
                              width: 1)
                          : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$day',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: isToday || hasBirthday
                            ? FontWeight.w700
                            : FontWeight.w400,
                        color: isSelected
                            ? AppColors.primary
                            : isToday
                                ? AppColors.primary
                                : hasBirthday
                                    ? AppColors.textDark
                                    : AppColors.textMedium,
                      ),
                    ),
                    if (hasBirthday) ...[
                      const SizedBox(height: 3),
                      _DotsRow(colors: dots),
                    ],
                  ],
                ),
              ),
            );
          },
        ),

        // ── Selected day birthdays ────────────────────────────────────
        if (selectedPeople.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          ...selectedPeople.map((p) => _SelectedPersonTile(
                person: p,
                groupColor: groupColorMap[p.groupId] ?? AppColors.primary,
              )),
        ],
      ],
    ).animate().fadeIn(duration: 400.ms);
  }

  String _monthLabel(DateTime d) {
    const months = [
      'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
      'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
    ];
    return '${months[d.month - 1]} de ${d.year}';
  }
}

/// Row of up to 5 colored dots (de-duped by color to avoid visual clutter).
class _DotsRow extends StatelessWidget {
  const _DotsRow({required this.colors});
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    // Keep max 4 dots; unique colors first
    final seen = <Color>{};
    final deduped = <Color>[];
    for (final c in colors) {
      if (seen.add(c)) deduped.add(c);
      if (deduped.length == 4) break;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: deduped
          .map((c) => Container(
                width: 5,
                height: 5,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(color: c, shape: BoxShape.circle),
              ))
          .toList(),
    );
  }
}

class _SelectedPersonTile extends StatelessWidget {
  const _SelectedPersonTile({required this.person, required this.groupColor});
  final Person person;
  final Color groupColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/celebration/${person.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: groupColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: groupColor.withValues(alpha: 0.25), width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration:
                  BoxDecoration(color: groupColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(person.name, style: AppTextStyles.titleSmall),
                  Text(
                    'Dia ${person.birthday.day} de ${_monthShort(person.birthday.month)}',
                    style: AppTextStyles.label,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 18, color: AppColors.textLight),
          ],
        ),
      ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.05, end: 0),
    );
  }

  String _monthShort(int month) {
    const m = ['Jan','Fev','Mar','Abr','Mai','Jun','Jul','Ago','Set','Out','Nov','Dez'];
    return m[month - 1];
  }
}
