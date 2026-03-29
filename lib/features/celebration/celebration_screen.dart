import 'dart:io';
import 'package:birthday/core/theme/app_colors.dart';
import 'package:birthday/core/theme/app_text_styles.dart';
import 'package:birthday/core/utils/birthday_utils.dart';
import 'package:birthday/core/utils/whatsapp_utils.dart';
import 'package:birthday/providers/app_providers.dart';
import 'package:birthday/services/checked_today_service.dart';
import 'package:birthday/services/notification_service.dart';
import 'package:birthday/services/whatsapp_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

class CelebrationScreen extends ConsumerStatefulWidget {
  const CelebrationScreen({super.key, required this.personId});

  final String personId;

  @override
  ConsumerState<CelebrationScreen> createState() => _CelebrationScreenState();
}

class _CelebrationScreenState extends ConsumerState<CelebrationScreen> {
  late TextEditingController _messageController;
  bool _sending = false;
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
    _loadCheckedState();
  }

  Future<void> _loadCheckedState() async {
    final checked = await CheckedTodayService.isChecked(widget.personId);
    if (mounted) setState(() => _checked = checked);
  }

  Future<void> _markVerified(String personName) async {
    await CheckedTodayService.markChecked(widget.personId);
    await NotificationService.instance.cancelHourlyTodayNotifs(widget.personId);
    if (mounted) {
      setState(() => _checked = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Verificado! Notificações de $personName canceladas.')),
      );
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final personAsync = ref.watch(personByIdProvider(widget.personId));

    return personAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Error: $e')),
      ),
      data: (person) {
        if (person == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Person not found')),
          );
        }

        if (_messageController.text.isEmpty) {
          _messageController.text = WhatsAppUtils.buildDefaultWishMessage(
            name: person.name,
            birthday: person.birthday,
          );
        }

        final groupAsync = ref.watch(groupByIdProvider(person.groupId));
        final groupColor =
            groupAsync.whenOrNull(data: (g) => g?.color) ?? AppColors.primary;

        final age = BirthdayUtils.calculateTurningAge(person.birthday);
        final days = person.daysUntilNextBirthday;
        final isToday = days == 0;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Stack(
            children: [
              // Lottie confetti — subtle, only on birthdays today
              if (isToday)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Lottie.asset(
                      'assets/animations/confetti.json',
                      repeat: true,
                      fit: BoxFit.cover,
                      errorBuilder: (_, e, s) => const SizedBox.shrink(),
                    ),
                  ),
                ),

              // Back button
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 8,
                child: IconButton(
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/home');
                    }
                  },
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.outline, width: 1),
                    ),
                    child: const Icon(Icons.arrow_back_rounded,
                        color: AppColors.textDark, size: 20),
                  ),
                ),
              ),

              // Main content
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
                  child: Column(
                    children: [
                      const SizedBox(height: 24),

                      // Avatar
                      _buildAvatar(person, groupColor, isToday),
                      const SizedBox(height: 24),

                      // Badge
                      _BirthdayBadge(isToday: isToday, days: days),
                      const SizedBox(height: 16),

                      Text(
                        isToday ? 'Feliz Aniversário,' : 'Aniversário em breve,',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.textLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        person.name,
                        style: AppTextStyles.displayLarge,
                        textAlign: TextAlign.center,
                      ).animate().scale(
                            delay: 200.ms,
                            duration: 500.ms,
                            curve: Curves.easeOutBack,
                          ),

                      if (age != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          isToday
                              ? 'Fazendo $age anos hoje'
                              : 'Fará $age anos esse ano',
                          style: AppTextStyles.bodyMedium,
                        ),
                      ],

                      if (isToday) ...[
                        const SizedBox(height: 24),
                        _checked
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle_rounded,
                                      color: AppColors.successGreen, size: 18),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Verificado!',
                                    style: AppTextStyles.titleSmall.copyWith(
                                        color: AppColors.successGreen),
                                  ),
                                ],
                              )
                            : SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () =>
                                      _markVerified(person.name),
                                  icon: const Icon(
                                      Icons.check_circle_outline_rounded,
                                      size: 18),
                                  label: const Text('Verificado'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.successGreen,
                                    side: BorderSide(
                                        color: AppColors.successGreen),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 13),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                  ),
                                ),
                              ),
                      ],

                      const SizedBox(height: 32),

                      // Divider
                      const Divider(height: 1),
                      const SizedBox(height: 24),

                      // WhatsApp share section
                      if (person.phoneNumber != null &&
                          person.phoneNumber!.isNotEmpty) ...[
                        _MessageCard(
                          controller: _messageController,
                          personName: person.name,
                        ),
                        const SizedBox(height: 14),
                        _WhatsAppButton(
                          onTap: () => _sendWhatsApp(person.phoneNumber!),
                          loading: _sending,
                        ),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Nenhum número de telefone salvo',
                                style: AppTextStyles.titleSmall,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Edite esta pessoa para adicionar um número para compartilhar via WhatsApp.',
                                style: AppTextStyles.bodyMedium,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _shareMessage(),
                            icon: const Icon(Icons.share_rounded, size: 18),
                            label: const Text('Compartilhar Parabéns'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAvatar(dynamic person, Color groupColor, bool isToday) {
    final hasPhoto = person.photoPath != null &&
        File(person.photoPath as String).existsSync();

    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: groupColor.withOpacity(0.15),
        border: Border.all(
          color: isToday ? AppColors.primary : AppColors.outline,
          width: isToday ? 2.5 : 1.5,
        ),
        image: hasPhoto
            ? DecorationImage(
                image: FileImage(File(person.photoPath as String)),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: !hasPhoto
          ? Center(
              child: Text(
                (person.name as String).isNotEmpty
                    ? (person.name as String)[0].toUpperCase()
                    : '?',
                style: AppTextStyles.displayLarge.copyWith(
                  fontSize: 48,
                  color: groupColor,
                ),
              ),
            )
          : null,
    )
        .animate()
        .scale(duration: 600.ms, curve: Curves.easeOutBack)
        .then()
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .moveY(begin: 0, end: -6, duration: 2000.ms, curve: Curves.easeInOut);
  }

  Future<void> _sendWhatsApp(String phoneNumber) async {
    setState(() => _sending = true);
    final service = WhatsAppService();
    final success = await service.openWhatsApp(
      phoneNumber: phoneNumber,
      message: _messageController.text,
    );
    if (mounted && !success) {
      await service.shareMessage(_messageController.text);
    }
    if (mounted) setState(() => _sending = false);
  }

  Future<void> _shareMessage() async {
    final service = WhatsAppService();
    await service.shareMessage(_messageController.text.isEmpty
        ? 'Feliz Aniversário!'
        : _messageController.text);
  }
}

class _BirthdayBadge extends StatelessWidget {
  const _BirthdayBadge({required this.isToday, required this.days});

  final bool isToday;
  final int days;

  @override
  Widget build(BuildContext context) {
    final label = isToday
        ? 'Aniversário Hoje'
        : 'Aniversário em $days ${days == 1 ? 'dia' : 'dias'}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: isToday ? AppColors.primaryLight : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppTextStyles.label.copyWith(
          color: isToday ? AppColors.primary : AppColors.textMedium,
          fontWeight: FontWeight.w600,
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0);
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.controller,
    required this.personName,
  });

  final TextEditingController controller;
  final String personName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outline, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Mensagem de Aniversário', style: AppTextStyles.titleSmall),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Escreva uma mensagem de parabéns...',
            ),
            style: AppTextStyles.bodyMedium,
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms, duration: 500.ms).slideY(begin: 0.05, end: 0);
  }
}

class _WhatsAppButton extends StatelessWidget {
  const _WhatsAppButton({required this.onTap, required this.loading});

  final VoidCallback onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: loading ? null : onTap,
        icon: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.send_rounded, size: 18),
        label: const Text('Enviar pelo WhatsApp'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.whatsapp,
          foregroundColor: Colors.white,
          textStyle: AppTextStyles.titleSmall.copyWith(color: Colors.white),
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 500.ms, duration: 500.ms).slideY(begin: 0.05, end: 0);
  }
}
