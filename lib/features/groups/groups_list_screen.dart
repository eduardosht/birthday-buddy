import 'package:birthday/core/theme/app_colors.dart';
import 'package:birthday/core/theme/app_text_styles.dart';
import 'package:birthday/data/models/account_profile.dart';
import 'package:birthday/data/models/group.dart';
import 'package:birthday/core/constants/app_constants.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import 'package:birthday/providers/account_provider.dart';
import 'package:birthday/providers/app_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class GroupsListScreen extends ConsumerWidget {
  const GroupsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(groupsProvider);
    final account = ref.watch(accountProvider).valueOrNull ?? const AccountProfile();

    return Scaffold(
      appBar: AppBar(
        title: Text('Meus Grupos', style: AppTextStyles.titleLarge),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddGroupSheet(context, ref, account),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Novo Grupo'),
      ),
      body: groupsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (groups) {
          if (groups.isEmpty) {
            return _EmptyGroupsState(onAdd: () => _showAddGroupSheet(context, ref, account));
          }
          return Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.1,
              ),
              itemCount: groups.length,
              itemBuilder: (_, i) => _GroupCard(group: groups[i], ref: ref),
            ),
          );
        },
      ),
    );
  }

  void _showAddGroupSheet(BuildContext context, WidgetRef ref, AccountProfile account) {
    final groups = ref.read(groupsProvider).valueOrNull ?? [];
    if (account.isFree && groups.length >= AccountProfile.freeMaxGroups) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (_) => PlanLimitSheet(
          message: 'O plano Gratuito permite apenas ${AccountProfile.freeMaxGroups} grupo.',
        ),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddGroupBottomSheet(
        onSave: (name, colorValue, emoji) async {
          final repo = ref.read(groupRepositoryProvider);
          final group = Group.create(
            name: name,
            colorValue: colorValue,
            emoji: emoji,
          );
          await repo.insert(group);
          ref.invalidate(groupsProvider);
        },
      ),
    );
  }
}

class _GroupCard extends ConsumerWidget {
  const _GroupCard({required this.group, required this.ref});

  final Group group;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context, WidgetRef widgetRef) {
    final countAsync = widgetRef.watch(groupPersonCountProvider(group.id));
    final count = countAsync.valueOrNull ?? 0;

    return GestureDetector(
      onTap: () => context.push('/groups/${group.id}'),
      onLongPress: () => _showOptions(context, widgetRef),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.outline, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: group.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(group.emoji, style: const TextStyle(fontSize: 20)),
              ),
            ),
            const Spacer(),
            Text(
              group.name,
              style: AppTextStyles.titleMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '$count ${count == 1 ? 'pessoa' : 'pessoas'}',
              style: AppTextStyles.label,
            ),
          ],
        ),
      ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1)),
    );
  }

  void _showOptions(BuildContext context, WidgetRef ref) {
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
            Text(group.name, style: AppTextStyles.titleMedium),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.edit_rounded),
              title: const Text('Editar Grupo'),
              onTap: () {
                Navigator.pop(context);
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => AddGroupBottomSheet(
                    initialName: group.name,
                    initialColorValue: group.colorValue,
                    initialEmoji: group.emoji,
                    onSave: (name, colorValue, emoji) async {
                      final updated = group.copyWith(
                        name: name,
                        colorValue: colorValue,
                        emoji: emoji,
                      );
                      await ref.read(groupRepositoryProvider).update(updated);
                      ref.invalidate(groupsProvider);
                    },
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_rounded, color: AppColors.alertRed),
              title: const Text('Excluir Grupo', style: TextStyle(color: AppColors.alertRed)),
              onTap: () async {
                Navigator.pop(context);
                await ref.read(groupRepositoryProvider).delete(group.id);
                ref.invalidate(groupsProvider);
                ref.invalidate(allPeopleSortedProvider);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyGroupsState extends StatelessWidget {
  const _EmptyGroupsState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline_rounded, size: 64, color: AppColors.textLight),
            const SizedBox(height: 16),
            Text('Nenhum grupo ainda!', style: AppTextStyles.displayMedium, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              'Crie um grupo para começar a adicionar\nlembretes de aniversário.',
              style: AppTextStyles.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Criar Primeiro Grupo'),
            ),
          ],
        ),
      ),
    );
  }
}

// Bottom sheet for adding/editing a group
class AddGroupBottomSheet extends StatefulWidget {
  const AddGroupBottomSheet({
    super.key,
    required this.onSave,
    this.initialName,
    this.initialColorValue,
    this.initialEmoji,
  });

  final Future<void> Function(String name, int colorValue, String emoji) onSave;
  final String? initialName;
  final int? initialColorValue;
  final String? initialEmoji;

  @override
  State<AddGroupBottomSheet> createState() => _AddGroupBottomSheetState();
}

class _AddGroupBottomSheetState extends State<AddGroupBottomSheet> {
  final _nameController = TextEditingController();
  late int _selectedColorValue;
  late String _selectedEmoji;
  bool _loading = false;

  final List<String> _emojis = [
    '🎉', '🎂', '❤️', '⭐', '🌟', '🏠', '💼', '🎓', '🏖️', '🎮', '🌺', '🐾',
  ];

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.initialName ?? '';
    _selectedColorValue = widget.initialColorValue ?? AppColors.groupColors[0].value;
    _selectedEmoji = widget.initialEmoji ?? '🎉';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: AppColors.outline, width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.initialName != null ? 'Editar Grupo' : 'Novo Grupo',
            style: AppTextStyles.titleLarge,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Nome do Grupo'),
            style: AppTextStyles.bodyLarge,
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 16),
          Text('Escolha uma Cor', style: AppTextStyles.titleSmall),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: AppColors.groupColors.map((color) {
              final selected = color.value == _selectedColorValue;
              return GestureDetector(
                onTap: () => setState(() => _selectedColorValue = color.value),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? AppColors.outline : Colors.transparent,
                      width: selected ? 3 : 0,
                    ),
                    boxShadow: selected
                        ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 8)]
                        : null,
                  ),
                  child: selected
                      ? const Icon(Icons.check, color: Colors.white, size: 18)
                      : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Text('Escolha um Emoji', style: AppTextStyles.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _emojis.map((emoji) {
              final selected = emoji == _selectedEmoji;
              return GestureDetector(
                onTap: () => setState(() => _selectedEmoji = emoji),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected ? AppColors.outline : AppColors.textLight.withOpacity(0.3),
                      width: selected ? 2 : 1,
                    ),
                    color: selected ? AppColors.primaryLight : Colors.transparent,
                  ),
                  child: Center(child: Text(emoji, style: const TextStyle(fontSize: 22))),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _onSave,
              child: _loading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Salvar Grupo'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onSave() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, insira um nome para o grupo')),
      );
      return;
    }
    setState(() => _loading = true);
    await widget.onSave(name, _selectedColorValue, _selectedEmoji);
    if (mounted) Navigator.pop(context);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared plan-limit bottom sheet (used by groups & group detail)
// ─────────────────────────────────────────────────────────────────────────────

class PlanLimitSheet extends StatelessWidget {
  const PlanLimitSheet({super.key, required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: AppColors.outline, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 20),
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: AppColors.accentLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.lock_outline_rounded,
                color: AppColors.accent, size: 26),
          ),
          const SizedBox(height: 14),
          Text('Limite do Plano Atingido', style: AppTextStyles.titleMedium),
          const SizedBox(height: 6),
          Text(
            '$message\nFaça upgrade para o Pro e tenha acesso ilimitado.',
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                await RevenueCatUI.presentPaywallIfNeeded(
                  AppConstants.rcEntitlementId,
                  displayCloseButton: true,
                );
              },
              icon: const Icon(Icons.workspace_premium_rounded, size: 16),
              label: const Text('Fazer Upgrade para Pro'),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Agora não',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textLight)),
          ),
        ],
      ),
    );
  }
}
