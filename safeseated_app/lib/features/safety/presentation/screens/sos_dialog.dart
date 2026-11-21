import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/widgets/app_button.dart';

class SosDialog extends ConsumerStatefulWidget {
  const SosDialog({super.key});

  @override
  ConsumerState<SosDialog> createState() => _SosDialogState();
}

class _SosDialogState extends ConsumerState<SosDialog> {
  bool _isSent = false;
  bool _isSending = false;

  Future<void> _confirmSos() async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    setState(() => _isSending = true);

    try {
      final repo = ref.read(safetyRepositoryProvider);
      await repo.triggerSos(
        reporterEmail: user.email,
        reporterName: user.name,
        emergencyContactName: user.emergencyContactName ?? 'Emergency Contact',
        emergencyContactPhone: user.emergencyContactPhone ?? '0300-1234567',
      );

      setState(() {
        _isSent = true;
        _isSending = false;
      });
    } catch (e) {
      setState(() => _isSending = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.statusDangerText,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    final ecName = user?.emergencyContactName ?? 'Fatima Khan (Mother)';
    final ecPhone = user?.emergencyContactPhone ?? '0300-1234567';

    if (_isSent) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🚨', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            const Text(
              'Demo SOS recorded locally',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'No one was contacted and no location was shared. If you need immediate help, call $ecName at $ecPhone or use a local emergency number.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                height: 1.4,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            AppButton(
              text: "I'm safe — close",
              variant: AppButtonVariant.primary,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    }

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: AppColors.sosRed, size: 28),
          SizedBox(width: 8),
          Text(
            'Confirm SOS Alert',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'This preview only records a mock incident on this device. It does not contact your emergency contact or emergency services, and it does not share your location.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.statusDangerBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.statusDangerBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Emergency contact on file: $ecName ($ecPhone)',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.statusDangerText,
                  ),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'For urgent help, call your local emergency service directly.',
            style: TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Cancel',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.sosRed,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: _isSending ? null : _confirmSos,
          child: _isSending
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text(
                  'Record demo incident',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
        ),
      ],
    );
  }
}
