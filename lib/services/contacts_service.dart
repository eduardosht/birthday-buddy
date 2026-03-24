import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';

class ContactDraft {
  final String name;
  final String? phoneNumber;
  final List<int>? photoBytes;
  final String? contactId;

  ContactDraft({
    required this.name,
    this.phoneNumber,
    this.photoBytes,
    this.contactId,
  });
}

class ContactsService {
  Future<bool> requestPermission() async {
    final status = await Permission.contacts.request();
    return status.isGranted;
  }

  Future<List<Contact>> searchContacts(String query) async {
    if (!await requestPermission()) return [];

    try {
      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: false,
      );
      if (query.isEmpty) return contacts;
      return contacts
          .where((c) =>
              c.displayName.toLowerCase().contains(query.toLowerCase()))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<ContactDraft> draftFromContact(Contact contact) async {
    Contact? full;
    try {
      full = await FlutterContacts.getContact(contact.id, withPhoto: true);
    } catch (_) {}

    final phone =
        contact.phones.isNotEmpty ? contact.phones.first.number : null;

    return ContactDraft(
      name: contact.displayName,
      phoneNumber: phone,
      photoBytes: full?.photo?.toList(),
      contactId: contact.id,
    );
  }
}

