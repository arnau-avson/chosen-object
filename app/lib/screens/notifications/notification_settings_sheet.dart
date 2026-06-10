import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_colors.dart';
import '../../core/settings_service.dart';

class NotificationSettingsSheet extends StatelessWidget {
  const NotificationSettingsSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const NotificationSettingsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SettingsService.instance,
      builder: (context, _) {
        final s = SettingsService.instance;
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Handle ──
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.hairline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Title ──
              Row(
                children: [
                  Text(
                    'Notification preferences',
                    style: GoogleFonts.fraunces(
                      fontSize: 20,
                      fontWeight: FontWeight.w400,
                      color: AppColors.inkStrong,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Container(height: 1, color: AppColors.hairline),
              const SizedBox(height: 8),

              // ── Toggles ──
              _ToggleRow(
                label: 'New pieces from followed studios',
                value: s.newPieces,
                onChanged: s.setNewPieces,
              ),
              _ToggleRow(
                label: 'Piece updates from followed studios',
                value: s.pieceUpdates,
                onChanged: s.setPieceUpdates,
              ),
              _ToggleRow(
                label: 'New followers',
                value: s.newFollowers,
                onChanged: s.setNewFollowers,
              ),
              _ToggleRow(
                label: 'Messages',
                value: s.messages,
                onChanged: s.setMessages,
              ),
              _ToggleRow(
                label: 'Order updates',
                value: s.orderUpdates,
                onChanged: s.setOrderUpdates,
              ),
              _ToggleRow(
                label: 'Rental requests',
                value: s.rentalRequests,
                onChanged: s.setRentalRequests,
              ),
              _ToggleRow(
                label: 'Rental status changes',
                value: s.rentalStatusChanges,
                onChanged: s.setRentalStatusChanges,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13.5,
                fontWeight: FontWeight.w400,
                color: AppColors.inkSoft,
              ),
            ),
          ),
          SizedBox(
            height: 28,
            child: Switch.adaptive(
              value: value,
              onChanged: onChanged,
              activeTrackColor: AppColors.accent,
            ),
          ),
        ],
      ),
    );
  }
}
