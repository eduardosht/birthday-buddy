import 'dart:io';
import 'package:birthday/core/constants/app_constants.dart';
import 'package:birthday/core/theme/app_colors.dart';
import 'package:birthday/core/theme/app_text_styles.dart';
import 'package:birthday/data/models/account_profile.dart';
import 'package:birthday/providers/account_provider.dart';
import 'package:birthday/providers/app_providers.dart';
import 'package:birthday/services/revenue_cat_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  final _nameController = TextEditingController();
  bool _editing = false;
  DateTime? _pendingBirthday;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accountAsync = ref.watch(accountProvider);
    final groupsAsync = ref.watch(groupsProvider);
    final allPeopleAsync = ref.watch(allPeopleSortedProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Conta', style: AppTextStyles.titleLarge),
        actions: [
          if (!_editing)
            TextButton(
              onPressed: () {
                final profile = accountAsync.valueOrNull;
                _nameController.text = profile?.name ?? '';
                _pendingBirthday = profile?.birthday;
                setState(() => _editing = true);
              },
              child: Text('Editar',
                  style: AppTextStyles.titleSmall
                      .copyWith(color: AppColors.primary)),
            )
          else
            TextButton(
              onPressed: () => _saveProfile(accountAsync.valueOrNull),
              child: Text('Salvar',
                  style: AppTextStyles.titleSmall
                      .copyWith(color: AppColors.primary)),
            ),
        ],
      ),
      body: accountAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (profile) {
          final groupCount = groupsAsync.valueOrNull?.length ?? 0;
          final peopleCount = allPeopleAsync.valueOrNull?.length ?? 0;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
            children: [
              _ProfileHeader(
                profile: profile,
                editing: _editing,
                nameController: _nameController,
                pendingBirthday: _pendingBirthday,
                onPickPhoto: () => _pickPhoto(profile),
                onPickBirthday: () => _pickBirthday(profile),
              ).animate().fadeIn(duration: 400.ms),

              const SizedBox(height: 24),

              _PlanCard(
                profile: profile,
                groupCount: groupCount,
                peopleCount: peopleCount,
              ).animate().fadeIn(delay: 100.ms, duration: 400.ms),

              const SizedBox(height: 16),

              // ── Upgrade or manage ──────────────────────────────────────
              if (profile.isFree)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showPaywall(context),
                    icon: const Icon(Icons.workspace_premium_rounded, size: 18),
                    label: const Text('Fazer Upgrade para Pro'),
                  ),
                ).animate().fadeIn(delay: 150.ms, duration: 400.ms)
              else ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showCustomerCenter(context),
                    icon: const Icon(Icons.manage_accounts_rounded, size: 18),
                    label: const Text('Gerenciar Assinatura Pro'),
                  ),
                ).animate().fadeIn(delay: 150.ms, duration: 400.ms),
              ],

              const SizedBox(height: 28),
              const Divider(height: 1),
              const SizedBox(height: 20),

              _UsageStats(
                groupCount: groupCount,
                peopleCount: peopleCount,
                isPro: profile.isPro,
              ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

              const SizedBox(height: 28),
              const Divider(height: 1),
              const SizedBox(height: 20),

              // ── Sign out ───────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _signOut(context),
                  icon: Icon(Icons.logout_rounded,
                      size: 18, color: AppColors.alertRed),
                  label: Text('Sair da conta',
                      style: AppTextStyles.titleSmall
                          .copyWith(color: AppColors.alertRed)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                        color: AppColors.alertRed.withValues(alpha: 0.4)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ).animate().fadeIn(delay: 250.ms, duration: 400.ms),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showPaywall(BuildContext context) async {
    await RevenueCatUI.presentPaywallIfNeeded(
      AppConstants.rcEntitlementId,
      displayCloseButton: true,
    );
    // After paywall is dismissed, refresh plan status
    if (mounted) {
      await ref.read(accountProvider.notifier).refreshPlan();
    }
  }

  Future<void> _showCustomerCenter(BuildContext context) async {
    await RevenueCatUI.presentPaywallIfNeeded(
      'default',
      displayCloseButton: true,
    );
    if (mounted) {
      await ref.read(accountProvider.notifier).refreshPlan();
    }
  }

  Future<void> _signOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sair da conta'),
        content: const Text('Tem certeza que deseja sair?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Sair',
                style: TextStyle(color: AppColors.alertRed)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await RevenueCatService.instance.logOut();
    await Supabase.instance.client.auth.signOut();
    // _SupabaseAuthNotifier fires the redirect — nothing else needed here
  }

  Future<void> _pickPhoto(AccountProfile? current) async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 85, maxWidth: 512);
    if (xfile == null) return;
    final updated =
        (current ?? const AccountProfile()).copyWith(photoPath: xfile.path);
    await ref.read(accountProvider.notifier).save(updated);
  }

  Future<void> _pickBirthday(AccountProfile? current) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: current?.birthday ?? DateTime(now.year - 25),
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Seu aniversário',
    );
    if (picked == null) return;
    if (_editing) {
      setState(() => _pendingBirthday = picked);
    } else {
      final updated =
          (current ?? const AccountProfile()).copyWith(birthday: picked);
      await ref.read(accountProvider.notifier).save(updated);
    }
  }

  Future<void> _saveProfile(AccountProfile? current) async {
    final updated = (current ?? const AccountProfile()).copyWith(
      name: _nameController.text.trim().isEmpty
          ? null
          : _nameController.text.trim(),
      birthday: _pendingBirthday,
    );
    await ref.read(accountProvider.notifier).save(updated);
    setState(() {
      _editing = false;
      _pendingBirthday = null;
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.profile,
    required this.editing,
    required this.nameController,
    required this.pendingBirthday,
    required this.onPickPhoto,
    required this.onPickBirthday,
  });

  final AccountProfile profile;
  final bool editing;
  final TextEditingController nameController;
  final DateTime? pendingBirthday;
  final VoidCallback onPickPhoto;
  final VoidCallback onPickBirthday;

  @override
  Widget build(BuildContext context) {
    final hasPhoto =
        profile.photoPath != null && File(profile.photoPath!).existsSync();
    final birthday = editing ? pendingBirthday : profile.birthday;

    return Column(
      children: [
        const SizedBox(height: 8),
        GestureDetector(
          onTap: editing ? onPickPhoto : null,
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryLight,
                  border: Border.all(color: AppColors.primary, width: 2),
                  image: hasPhoto
                      ? DecorationImage(
                          image: FileImage(File(profile.photoPath!)),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: !hasPhoto
                    ? Center(
                        child: Text(
                          profile.name?.isNotEmpty == true
                              ? profile.name![0].toUpperCase()
                              : '?',
                          style: AppTextStyles.displayLarge.copyWith(
                            color: AppColors.primary,
                            fontSize: 38,
                          ),
                        ),
                      )
                    : null,
              ),
              if (editing)
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.camera_alt_rounded,
                      size: 13, color: Colors.white),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        if (editing)
          SizedBox(
            width: 240,
            child: TextField(
              controller: nameController,
              textAlign: TextAlign.center,
              style: AppTextStyles.titleLarge,
              decoration: const InputDecoration(
                hintText: 'Seu nome',
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              textCapitalization: TextCapitalization.words,
            ),
          )
        else
          Text(
            profile.name?.isNotEmpty == true ? profile.name! : 'Seu Nome',
            style: AppTextStyles.titleLarge.copyWith(
              color: profile.name == null
                  ? AppColors.textLight
                  : AppColors.textDark,
            ),
          ),

        const SizedBox(height: 6),

        GestureDetector(
          onTap: onPickBirthday,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cake_rounded, size: 14, color: AppColors.textLight),
              const SizedBox(width: 5),
              Text(
                birthday != null
                    ? DateFormat("d 'de' MMMM 'de' yyyy", 'pt_BR')
                        .format(birthday)
                    : editing
                        ? 'Definir seu aniversário'
                        : 'Aniversário não definido',
                style: AppTextStyles.label.copyWith(
                  color: editing ? AppColors.primary : AppColors.textLight,
                  decoration: editing ? TextDecoration.underline : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.profile,
    required this.groupCount,
    required this.peopleCount,
  });

  final AccountProfile profile;
  final int groupCount;
  final int peopleCount;

  @override
  Widget build(BuildContext context) {
    final isPro = profile.isPro;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isPro ? const Color(0xFF1C1C1E) : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPro ? Colors.transparent : AppColors.outline,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isPro
                  ? const Color(0xFFF0B429).withValues(alpha: 0.15)
                  : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isPro
                  ? Icons.workspace_premium_rounded
                  : Icons.person_outline_rounded,
              color: isPro ? AppColors.accent : AppColors.textLight,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      isPro ? 'Plano Pro' : 'Plano Gratuito',
                      style: AppTextStyles.titleSmall.copyWith(
                        color: isPro ? Colors.white : AppColors.textDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _PlanBadge(isPro: isPro),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  isPro
                      ? 'Grupos e pessoas ilimitados'
                      : '${AccountProfile.freeMaxGroups} grupo · máx. ${AccountProfile.freeMaxPeople} pessoas',
                  style: AppTextStyles.label.copyWith(
                    color: isPro
                        ? Colors.white.withValues(alpha: 0.6)
                        : AppColors.textLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanBadge extends StatelessWidget {
  const _PlanBadge({required this.isPro});
  final bool isPro;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isPro ? AppColors.accent : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isPro ? 'PRO' : 'FREE',
        style: AppTextStyles.chip.copyWith(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: isPro ? const Color(0xFF1C1C1E) : AppColors.textMedium,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _UsageStats extends StatelessWidget {
  const _UsageStats({
    required this.groupCount,
    required this.peopleCount,
    required this.isPro,
  });

  final int groupCount;
  final int peopleCount;
  final bool isPro;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Uso', style: AppTextStyles.titleSmall),
        const SizedBox(height: 12),
        _UsageTile(
          icon: Icons.folder_outlined,
          label: 'Grupos',
          current: groupCount,
          max: isPro ? null : AccountProfile.freeMaxGroups,
        ),
        const SizedBox(height: 8),
        _UsageTile(
          icon: Icons.people_outline_rounded,
          label: 'Pessoas',
          current: peopleCount,
          max: isPro ? null : AccountProfile.freeMaxPeople,
        ),
      ],
    );
  }
}

class _UsageTile extends StatelessWidget {
  const _UsageTile({
    required this.icon,
    required this.label,
    required this.current,
    required this.max,
  });

  final IconData icon;
  final String label;
  final int current;
  final int? max;

  @override
  Widget build(BuildContext context) {
    final fraction = max != null ? (current / max!).clamp(0.0, 1.0) : 0.0;
    final isAtLimit = max != null && current >= max!;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAtLimit
              ? AppColors.alertRed.withValues(alpha: 0.4)
              : AppColors.outline,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textLight),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(label, style: AppTextStyles.bodyMedium),
                    Text(
                      max != null ? '$current / $max' : '$current',
                      style: AppTextStyles.label.copyWith(
                        color: isAtLimit
                            ? AppColors.alertRed
                            : AppColors.textMedium,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (max != null) ...[
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: fraction,
                      minHeight: 4,
                      backgroundColor: AppColors.surfaceVariant,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isAtLimit ? AppColors.alertRed : AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

