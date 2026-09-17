import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_colors.dart';

class LauncherHelper {
  static Future<bool> makePhoneCall(String? phoneNumber) async {
    if (phoneNumber == null || phoneNumber.trim().isEmpty) return false;
    final clean = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri(scheme: 'tel', path: clean);
    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri);
      }
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  static Future<bool> sendSms(String? phoneNumber, {String? body}) async {
    if (phoneNumber == null || phoneNumber.trim().isEmpty) return false;
    final clean = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri(
      scheme: 'sms',
      path: clean,
      queryParameters: body != null ? {'body': body} : null,
    );
    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri);
      }
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  static Future<bool> openWhatsApp(String? phoneNumber, {String? message}) async {
    if (phoneNumber == null || phoneNumber.trim().isEmpty) return false;
    String digits = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    // Standardize Australian numbers (04xx -> 614xx)
    if (digits.startsWith('0')) {
      digits = '61${digits.substring(1)}';
    } else if (!digits.startsWith('61') && digits.length == 9) {
      digits = '61$digits';
    }

    final query = message != null ? '?text=${Uri.encodeComponent(message)}' : '';

    // 1. Try native WhatsApp scheme directly
    final nativeUri = Uri.parse('whatsapp://send?phone=$digits$query');
    try {
      if (await canLaunchUrl(nativeUri)) {
        return await launchUrl(nativeUri, mode: LaunchMode.externalNonBrowserApplication);
      }
    } catch (_) {}

    // 2. Try wa.me link
    final webUri = Uri.parse('https://wa.me/$digits$query');
    try {
      if (await canLaunchUrl(webUri)) {
        return await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
      return await launchUrl(webUri, mode: LaunchMode.externalApplication);
    } catch (_) {}

    // 3. Fallback to SMS if WhatsApp could not be launched
    return await sendSms(phoneNumber, body: message);
  }

  static Future<bool> openMapAddress(String? address) async {
    if (address == null || address.trim().isEmpty) return false;
    final encoded = Uri.encodeComponent(address.trim());
    final url = 'https://www.google.com/maps/search/?api=1&query=$encoded';
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  static void showMessageOptions(BuildContext context, String? phoneNumber, {String? name}) {
    if (phoneNumber == null || phoneNumber.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No phone number available for this client.')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        name != null ? 'Message $name' : 'Message Client',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      phoneNumber,
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const Divider(),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF25D366),
                  child: Icon(Icons.chat_rounded, color: Colors.white, size: 20),
                ),
                title: const Text('WhatsApp', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Chat with customer on WhatsApp'),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  final ok = await openWhatsApp(phoneNumber);
                  if (!ok && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Could not open WhatsApp for $phoneNumber')),
                    );
                  }
                },
              ),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: const Icon(Icons.sms_rounded, color: AppColors.primary, size: 20),
                ),
                title: const Text('SMS Message', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Open default messaging app'),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  final ok = await sendSms(phoneNumber);
                  if (!ok && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Could not open SMS for $phoneNumber')),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
