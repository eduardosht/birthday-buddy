import 'package:birthday/core/theme/app_colors.dart';
import 'package:birthday/core/theme/app_text_styles.dart';
import 'package:birthday/services/contacts_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

class ContactSearchSheet extends StatefulWidget {
  const ContactSearchSheet({super.key, required this.service});

  final ContactsService service;

  @override
  State<ContactSearchSheet> createState() => _ContactSearchSheetState();
}

class _ContactSearchSheetState extends State<ContactSearchSheet> {
  final _searchController = TextEditingController();
  List<Contact> _contacts = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadContacts('');
  }

  Future<void> _loadContacts(String query) async {
    setState(() => _loading = true);
    final results = await widget.service.searchContacts(query);
    if (mounted) {
      setState(() {
        _contacts = results;
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: AppColors.outline, width: 2)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textLight,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('Escolher Contato', style: AppTextStyles.titleMedium),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Buscar contatos...',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                    onChanged: _loadContacts,
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _contacts.isEmpty
                      ? Center(
                          child: Text(
                            'Nenhum contato encontrado',
                            style: AppTextStyles.bodyLarge,
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          itemCount: _contacts.length,
                          itemBuilder: (_, i) {
                            final contact = _contacts[i];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    AppColors.primary.withOpacity(0.2),
                                child: Text(
                                  (contact.displayName?.isNotEmpty ?? false)
                                      ? contact.displayName![0].toUpperCase()
                                      : '?',
                                  style: AppTextStyles.titleSmall,
                                ),
                              ),
                              title: Text(contact.displayName ?? '',
                                  style: AppTextStyles.bodyLarge),
                              subtitle: contact.phones.isNotEmpty
                                  ? Text(contact.phones.first.number,
                                      style: AppTextStyles.label)
                                  : null,
                              onTap: () async {
                                final draft = await widget.service
                                    .draftFromContact(contact);
                                if (context.mounted) {
                                  Navigator.pop(context, draft);
                                }
                              },
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

