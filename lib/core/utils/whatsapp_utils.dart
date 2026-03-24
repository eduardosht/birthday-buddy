import 'package:birthday/core/constants/app_constants.dart';

class WhatsAppUtils {
  WhatsAppUtils._();

  static String buildWhatsAppUrl({
    required String phoneNumber,
    required String message,
  }) {
    final cleaned = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final encoded = Uri.encodeComponent(message);
    return 'https://wa.me/$cleaned?text=$encoded';
  }

  static String buildDefaultWishMessage({
    required String name,
    DateTime? birthday,
  }) {
    String ageText = '';
    if (birthday != null && birthday.year != AppConstants.unknownYear) {
      final turningAge = DateTime.now().year - birthday.year;
      ageText = 'Você está fazendo $turningAge anos! ';
    }
    return 'Feliz Aniversário, $name! 🎂🎉 ${ageText}Desejando a você um dia incrível cheio de alegria e amor! 🥳';
  }
}

