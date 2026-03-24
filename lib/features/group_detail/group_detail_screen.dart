import 'package:birthday/core/theme/app_colors.dart';
import 'package:birthday/core/theme/app_text_styles.dart';
import 'package:birthday/core/utils/date_formatter.dart';
import 'package:birthday/data/models/account_profile.dart';
import 'package:birthday/data/models/person.dart';
import 'package:birthday/features/groups/groups_list_screen.dart';
import 'package:birthday/features/home/widgets/birthday_card.dart';
import 'package:birthday/providers/account_provider.dart';
import 'package:birthday/providers/app_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class GroupDetailScreen extends ConsumerWidget {
  const GroupDetailScreen({super.key, required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupAsync = ref.watch(groupByIdProvider(groupId));
    final peopleAsync = ref.watch(peopleByGroupProvider(groupId));
    final account = ref.watch(accountProvider).valueOrNull ?? const AccountProfile();
    final allPeopleCount = ref.watch(allPeopleSortedProvider).valueOrNull?.length ?? 0;

    return groupAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (group) {
        if (group == null) {
          return const Scaffold(body: Center(child: Text('Group not found')));
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(group.name, style: AppTextStyles.titleLarge),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Excluir Grupo?'),
                      content: Text('Isso também excluirá todas as pessoas em "${group.name}".'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Excluir', style: TextStyle(color: AppColors.alertRed)),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await ref.read(groupRepositoryProvider).delete(groupId);
                    ref.invalidate(groupsProvider);
                    ref.invalidate(allPeopleSortedProvider);
                    if (context.mounted) context.pop();
                  }
                },
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              if (account.isFree &&
                  allPeopleCount >= AccountProfile.freeMaxPeople) {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  builder: (_) => PlanLimitSheet(
                    message:
                        'O plano Gratuito permite até ${AccountProfile.freeMaxPeople} pessoas no total.',
                  ),
                );
                return;
              }
              context.push('/groups/$groupId/add-person');
            },
            icon: const Icon(Icons.person_add_rounded),
            label: const Text('Adicionar Pessoa'),
          ),
          body: peopleAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (people) {
              if (people.isEmpty) {
                return _EmptyPeopleState(
                  onAdd: () => context.push('/groups/$groupId/add-person'),
                  groupColor: group.color,
                );
              }

              final sorted = [...people]..sort((a, b) =>
                  a.daysUntilNextBirthday.compareTo(b.daysUntilNextBirthday));

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                itemCount: sorted.length,
                separatorBuilder: (ctx, i) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _PersonTile(
                  person: sorted[i],
                  groupColor: group.color,
                  ref: ref,
                  groupId: groupId,
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _PersonTile extends StatelessWidget {
  const _PersonTile({
    required this.person,
    required this.groupColor,
    required this.ref,
    required this.groupId,
  });

  final Person person;
  final Color groupColor;
  final WidgetRef ref;
  final String groupId;

  @override
  Widget build(BuildContext context) {
    final days = person.daysUntilNextBirthday;

    Color chipBg;
    Color chipFg;
    String chipText;
    if (days == 0) {
      chipBg = AppColors.primaryLight;
      chipFg = AppColors.primary;
      chipText = 'Hoje';
    } else if (days == 1) {
      chipBg = const Color(0xFFFDE8E8);
      chipFg = AppColors.alertRed;
      chipText = 'Amanhã';
    } else if (days <= 2) {
      chipBg = const Color(0xFFFDE8D8);
      chipFg = AppColors.alertOrange;
      chipText = '$days dias';
    } else if (days <= 7) {
      chipBg = AppColors.accentLight;
      chipFg = const Color(0xFFA07000);
      chipText = 'Em $days dias';
    } else {
      chipBg = AppColors.surfaceVariant;
      chipFg = AppColors.textMedium;
      chipText = 'Em $days dias';
    }

    return GestureDetector(
      onLongPress: () => _showOptions(context),
      onTap: () => context.push('/celebration/${person.id}'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.outline, width: 1.5),
        ),
        child: Row(
          children: [
            PersonAvatar(person: person, color: groupColor, size: 52),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(person.name, style: AppTextStyles.titleSmall),
                  Text(
                    DateFormatter.formatBirthday(person.birthday),
                    style: AppTextStyles.label,
                  ),
                  if (person.phoneNumber != null)
                    Text(
                      person.phoneNumber!,
                      style: AppTextStyles.label.copyWith(fontSize: 11),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: chipBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(chipText, style: AppTextStyles.chip.copyWith(fontSize: 11, color: chipFg)),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.05, end: 0),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(top: BorderSide(color: AppColors.outline, width: 1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(person.name, style: AppTextStyles.titleMedium),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.celebration_rounded),
              title: const Text('Celebrar!'),
              onTap: () {
                Navigator.pop(context);
                context.push('/celebration/${person.id}');
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_rounded),
              title: const Text('Editar Pessoa'),
              onTap: () {
                Navigator.pop(context);
                context.push('/groups/$groupId/edit-person/${person.id}');
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_rounded, color: AppColors.alertRed),
              title: const Text('Excluir', style: TextStyle(color: AppColors.alertRed)),
              onTap: () async {
                Navigator.pop(context);
                await ref.read(personRepositoryProvider).delete(person.id);
                ref.invalidate(peopleByGroupProvider(groupId));
                ref.invalidate(allPeopleSortedProvider);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyPeopleState extends StatelessWidget {
  const _EmptyPeopleState({required this.onAdd, required this.groupColor});

  final VoidCallback onAdd;
  final Color groupColor;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person_outline_rounded, size: 64, color: AppColors.textLight),
            const SizedBox(height: 16),
            Text('Ninguém aqui ainda!', style: AppTextStyles.displayMedium, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              'Adicione pessoas a este grupo para acompanhar seus aniversários.',
              style: AppTextStyles.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.person_add_rounded),
              label: const Text('Adicionar Primeira Pessoa'),
            ),
          ],
        ),
      ),
    );
  }
}

