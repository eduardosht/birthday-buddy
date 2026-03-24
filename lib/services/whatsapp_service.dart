import 'package:birthday/core/utils/whatsapp_utils.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class WhatsAppService {
  Future<bool> openWhatsApp({
    required String phoneNumber,
    required String message,
  }) async {
    final url = WhatsAppUtils.buildWhatsAppUrl(
      phoneNumber: phoneNumber,
      message: message,
    );
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return true;
    }
    return false;
  }

  Future<void> shareMessage(String message) async {
    await Share.share(message);
  }
}

