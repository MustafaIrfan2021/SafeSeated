import 'dart:math';

import 'package:geolocator/geolocator.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/widgets/app_button.dart';
import '../../domain/models/sos_incident.dart';

class SosDialog extends ConsumerStatefulWidget {
  final int? rideId;

  const SosDialog({super.key, this.rideId});

  @override
  ConsumerState<SosDialog> createState() => _SosDialogState();
}

class _SosDialogState extends ConsumerState<SosDialog> {
  late final String _clientRequestId = _newRequestId();
  SosIncident? _incident;
  String? _locationError;
  bool _isSending = false;

  Future<void> _confirmSos() async {
    if (_isSending) return;
    setState(() {
      _isSending = true;
      _locationError = null;
    });

    Position? position;
    try {
      position = await _currentPosition();
    } on Exception catch (error) {
      _locationError = error.toString().replaceFirst('Bad state: ', '');
    }

    try {
      final incident = await ref
          .read(safetyRepositoryProvider)
          .triggerSos(
            clientRequestId: _clientRequestId,
            latitude: position?.latitude,
            longitude: position?.longitude,
            rideId: widget.rideId,
          );
      if (mounted) setState(() => _incident = incident);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not send SOS alert: $error'),
            backgroundColor: AppColors.statusDangerText,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<Position> _currentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw StateError('Location services are turned off.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw StateError('Location permission was not granted.');
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );
  }

  Future<void> _callEmergencyContact(String phone) async {
    try {
      final launched = await launchUrl(
        Uri(scheme: 'tel', path: phone),
        mode: LaunchMode.externalApplication,
      );
      if (!launched) throw StateError('No phone app could place this call.');
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not start the call: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    final contactName = user?.emergencyContactName;
    final contactPhone = user?.emergencyContactPhone;
    final contactIsConfigured =
        contactName != null &&
        contactName.trim().isNotEmpty &&
        contactPhone != null &&
        contactPhone.trim().isNotEmpty;
    final incident = _incident;

    if (incident != null) {
      return PopScope<void>(
        canPop: !_isSending,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: AppColors.statusSuccessText,
                size: 48,
              ),
              const SizedBox(height: 12),
              const Text(
                'SOS alert sent',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              Text(
                incident.latitude != null && incident.longitude != null
                    ? 'The alert was saved for SafeSeated Admin review with its current location.'
                    : _locationError == null
                    ? 'The alert was saved for SafeSeated Admin review without location coordinates.'
                    : 'The alert was saved for SafeSeated Admin review, but location was not attached: $_locationError',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: AppColors.textSecondary,
                ),
              ),
              if (contactIsConfigured) ...[
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () => _callEmergencyContact(contactPhone),
                  icon: const Icon(Icons.call_outlined),
                  label: Text('Call $contactName'),
                ),
              ],
              const SizedBox(height: 12),
              const Text(
                'This alert does not contact emergency services automatically.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
              const SizedBox(height: 16),
              AppButton(
                text: 'Close',
                variant: AppButtonVariant.primary,
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      );
    }

    return PopScope<void>(
      canPop: !_isSending,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: AppColors.sosRed,
              size: 28,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Confirm SOS Alert',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This sends an alert and your current GPS location to SafeSeated Admin for review.',
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
              child: Text(
                contactIsConfigured
                    ? 'Emergency contact: $contactName ($contactPhone)'
                    : 'No emergency contact is configured. You can add one from your profile.',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.statusDangerText,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'If GPS is unavailable, the alert can still be sent without coordinates. This app does not contact emergency services automatically.',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _isSending ? null : () => Navigator.pop(context),
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
                    'Send SOS',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
          ),
        ],
      ),
    );
  }
}

String _newRequestId() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes
      .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
      .join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}
