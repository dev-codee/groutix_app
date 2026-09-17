import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class StatusPill extends StatelessWidget {
  final String status;
  final bool isSmall;

  const StatusPill({
    super.key,
    required this.status,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color text;
    Color border;

    final s = status.toLowerCase();

    if (s.contains('completed') || s.contains('won') || s.contains('payment received')) {
      bg = AppColors.successBg;
      text = const Color(0xFF065F46);
      border = AppColors.successBorder;
    } else if (s.contains('lost') || s.contains('cancelled') || s.contains('unpaid')) {
      bg = AppColors.dangerBg;
      text = const Color(0xFF991B1B);
      border = AppColors.dangerBorder;
    } else if (s.contains('route') || s.contains('way') || s.contains('progress') || s.contains('started')) {
      bg = AppColors.infoBg;
      text = const Color(0xFF0369A1);
      border = AppColors.infoBorder;
    } else if (s.contains('booked') || s.contains('scheduled') || s.contains('pending')) {
      bg = AppColors.warningBg;
      text = const Color(0xFF92400E);
      border = AppColors.warningBorder;
    } else if (s.contains('quote') || s.contains('invoice')) {
      bg = AppColors.purpleBg;
      text = const Color(0xFF5B21B6);
      border = const Color(0xFFDDD6FE);
    } else {
      bg = const Color(0xFFF1F5F9);
      text = const Color(0xFF475569);
      border = const Color(0xFFCBD5E1);
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 8 : 10,
        vertical: isSmall ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border, width: 1),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: text,
          fontSize: isSmall ? 10.5 : 11.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
