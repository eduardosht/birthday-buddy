import 'dart:io';

import 'package:birthday/core/constants/app_constants.dart';
import 'package:birthday/core/theme/app_colors.dart';
import 'package:birthday/core/theme/app_text_styles.dart';
import 'package:birthday/data/models/person.dart';
import 'package:birthday/providers/app_providers.dart';
import 'package:birthday/features/add_person/widgets/contact_search_sheet.dart';
import 'package:birthday/services/contacts_service.dart';
import 'package:birthday/services/notification_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class AddPersonScreen extends ConsumerStatefulWidget {
  const AddPersonScreen({super.key, required this.groupId, this.personId});

  final String groupId;
  final String? personId;

  @override
  ConsumerState<AddPersonScreen> createState() => _AddPersonScreenState();
}

class _AddPersonScreenState extends ConsumerState<AddPersonScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();

  late int _day;
  late int _month;
  late int _year;
  bool _yearUnknown = false;
  String? _photoPath;
  bool _loading = false;
  Person? _editingPerson;

  final List<String> _months = [
    'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
    'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez',
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _day = now.day;
    _month = now.month;
    _year = now.year;
    _loadExistingPerson();
  }

  Future<void> _loadExistingPerson() async {
    if (widget.personId == null) return;
    final person = await ref.read(personByIdProvider(widget.personId!).future);
    if (person != null && mounted) {
      setState(() {
        _editingPerson = person;
        _nameController.text = person.name;
        _phoneController.text = person.phoneNumber ?? '';
        _notesController.text = person.notes ?? '';
        _day = person.birthday.day;
        _month = person.birthday.month;
        _year = person.birthday.year == AppConstants.unknownYear
            ? DateTime.now().year
            : person.birthday.year;
        _yearUnknown = person.birthday.year == AppConstants.unknownYear;
        _photoPath = person.photoPath;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.personId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Pessoa' : 'Adicionar Pessoa', style: AppTextStyles.titleLarge),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Avatar picker
            Center(
              child: GestureDetector(
                onTap: _showAvatarOptions,
                child: Stack(
                  children: [
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withValues(alpha: 0.2),
                        border: Border.all(color: AppColors.outline, width: 2.5),
                        image: _photoPath != null && File(_photoPath!).existsSync()
                            ? DecorationImage(
                                image: FileImage(File(_photoPath!)),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _photoPath == null
                          ? const Icon(Icons.person_rounded, size: 56, color: AppColors.textLight)
                          : null,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.outline, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt_rounded, size: 18, color: AppColors.textDark),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nome Completo',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              style: AppTextStyles.bodyLarge,
              textCapitalization: TextCapitalization.words,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Nome é obrigatório' : null,
            ),
            const SizedBox(height: 16),

            // Birthday date picker
            Text('Data de Aniversário', style: AppTextStyles.titleSmall),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.outline, width: 2),
                color: AppColors.surface,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Day picker
                      Expanded(child: _buildPickerColumn('Dia', 1, 31, _day, (v) => setState(() => _day = v))),
                      Container(width: 1, height: 120, color: AppColors.outline.withValues(alpha: 0.2)),
                      // Month picker
                      Expanded(child: _buildMonthPicker()),
                      Container(width: 1, height: 120, color: AppColors.outline.withValues(alpha: 0.2)),
                      // Year picker (disabled if unknown)
                      Expanded(child: _buildPickerColumn('Ano', 1924, DateTime.now().year, _year,
                        _yearUnknown ? null : (v) => setState(() => _year = v),
                        disabled: _yearUnknown,
                      )),
                    ],
                  ),
                  const Divider(height: 1),
                  CheckboxListTile(
                    title: Text('Ano desconhecido', style: AppTextStyles.bodyMedium),
                    value: _yearUnknown,
                    activeColor: AppColors.primary,
                    onChanged: (v) => setState(() => _yearUnknown = v ?? false),
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Phone number
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Telefone (opcional)',
                hintText: '+55 11 99999-0000',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              keyboardType: TextInputType.phone,
              style: AppTextStyles.bodyLarge,
            ),
            const SizedBox(height: 16),

            // Notes
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Observações (opcional)',
                prefixIcon: Icon(Icons.notes_rounded),
              ),
              maxLines: 2,
              style: AppTextStyles.bodyLarge,
            ),
            const SizedBox(height: 32),

            // Save button
            ElevatedButton(
              onPressed: _loading ? null : _onSave,
              child: _loading
                  ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(isEditing ? 'Salvar Alterações' : 'Adicionar Pessoa'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerColumn(String label, int min, int max, int value, void Function(int)? onChange, {bool disabled = false}) {
    final count = max - min + 1;
    final initialIndex = (value - min).clamp(0, count - 1);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(label, style: AppTextStyles.label),
        ),
        SizedBox(
          height: 100,
          child: Opacity(
            opacity: disabled ? 0.3 : 1.0,
            child: CupertinoPicker(
              scrollController: FixedExtentScrollController(initialItem: initialIndex),
              itemExtent: 36,
              onSelectedItemChanged: onChange == null ? (_) {} : (i) => onChange(min + i),
              children: List.generate(count, (i) => Center(
                child: Text('${min + i}', style: AppTextStyles.bodyMedium),
              )),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthPicker() {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 8),
          child: Text('Mês', style: TextStyle(
            fontFamily: 'Nunito', fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textLight,
          )),
        ),
        SizedBox(
          height: 100,
          child: CupertinoPicker(
            scrollController: FixedExtentScrollController(initialItem: _month - 1),
            itemExtent: 36,
            onSelectedItemChanged: (i) => setState(() => _month = i + 1),
            children: _months.map((m) => Center(
              child: Text(m, style: AppTextStyles.bodyMedium),
            )).toList(),
          ),
        ),
      ],
    );
  }

  void _showAvatarOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: AppColors.outline, width: 2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: const Text('Tirar Foto'),
              onTap: () async {
                Navigator.pop(context);
                await _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Escolher da Galeria'),
              onTap: () async {
                Navigator.pop(context);
                await _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.contacts_rounded),
              title: const Text('Importar dos Contatos'),
              onTap: () async {
                Navigator.pop(context);
                await _importFromContacts();
              },
            ),
            if (_photoPath != null)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: AppColors.alertRed),
                title: const Text('Remover Foto', style: TextStyle(color: AppColors.alertRed)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _photoPath = null);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 80, maxWidth: 500);
    if (picked == null) return;

    final appDir = await getApplicationDocumentsDirectory();
    final avatarsDir = Directory(p.join(appDir.path, AppConstants.avatarsDirectory));
    if (!await avatarsDir.exists()) await avatarsDir.create(recursive: true);

    final ext = p.extension(picked.path);
    final fileName = '${DateTime.now().millisecondsSinceEpoch}$ext';
    final savedPath = p.join(avatarsDir.path, fileName);
    await File(picked.path).copy(savedPath);

    if (mounted) setState(() => _photoPath = savedPath);
  }

  Future<void> _importFromContacts() async {
    final service = ContactsService();
    final granted = await service.requestPermission();
    if (!granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permissão de contatos negada')),
        );
      }
      return;
    }

    if (!mounted) return;
    final draft = await showModalBottomSheet<ContactDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ContactSearchSheet(service: service),
    );

    if (draft != null && mounted) {
      _nameController.text = draft.name;
      if (draft.phoneNumber != null) _phoneController.text = draft.phoneNumber!;

      if (draft.photoBytes != null) {
        final appDir = await getApplicationDocumentsDirectory();
        final avatarsDir = Directory(p.join(appDir.path, AppConstants.avatarsDirectory));
        if (!await avatarsDir.exists()) await avatarsDir.create(recursive: true);
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        final savedPath = p.join(avatarsDir.path, fileName);
        await File(savedPath).writeAsBytes(draft.photoBytes!);
        if (mounted) setState(() => _photoPath = savedPath);
      }
    }
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final birthdayYear = _yearUnknown ? AppConstants.unknownYear : _year;
      final birthday = DateTime(birthdayYear, _month, _day);
      final repo = ref.read(personRepositoryProvider);

      if (_editingPerson != null) {
        final updated = _editingPerson!.copyWith(
          name: _nameController.text.trim(),
          birthday: birthday,
          photoPath: _photoPath,
          phoneNumber: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        );
        await repo.update(updated);
      } else {
        final person = Person.create(
          groupId: widget.groupId,
          name: _nameController.text.trim(),
          birthday: birthday,
          photoPath: _photoPath,
          phoneNumber: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        );
        await repo.insert(person);
      }

      ref.invalidate(peopleByGroupProvider(widget.groupId));
      ref.invalidate(allPeopleSortedProvider);

      // Reschedule notifications
      final allPeople = await ref.read(personRepositoryProvider).getAll();
      await NotificationService.instance.rescheduleAll(allPeople);

      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

