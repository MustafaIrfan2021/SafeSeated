import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import 'sos_dialog.dart';

class SafetyScreen extends ConsumerStatefulWidget {
  const SafetyScreen({super.key});

  @override
  ConsumerState<SafetyScreen> createState() => _SafetyScreenState();
}

class _SafetyScreenState extends ConsumerState<SafetyScreen> {
  final _complaintController = TextEditingController();
  int? _selectedRideId = 1;
  bool _isSubmittingComplaint = false;

  @override
  void dispose() {
    _complaintController.dispose();
    super.dispose();
  }

  Future<void> _submitComplaint() async {
    final text = _complaintController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please describe the issue in detail.'),
          backgroundColor: AppColors.statusDangerText,
        ),
      );
      return;
    }

    final user = ref.read(authStateProvider).value;
    if (user == null) return;
    final rideId = _selectedRideId;
    if (rideId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select a related ride before submitting.'),
        ),
      );
      return;
    }

    setState(() => _isSubmittingComplaint = true);

    try {
      final repo = ref.read(safetyRepositoryProvider);
      final ride = await ref.read(rideRepositoryProvider).getRideById(rideId);
      if (ride == null) {
        throw StateError('The selected ride could not be found.');
      }
      await repo.submitComplaint(
        reporterEmail: user.email,
        reporterName: user.name,
        rideId: ride.id,
        rideRoute: '${ride.from} → ${ride.to}',
        driverEmail: ride.driverEmail,
        description: text,
      );

      _complaintController.clear();
      ref.invalidate(passengerComplaintsProvider(user.email));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Complaint submitted successfully.'),
            backgroundColor: AppColors.statusSuccessText,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not submit complaint: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmittingComplaint = false);
    }
  }

  Future<void> _callPhone(String phone) async {
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
    final ecName = user?.emergencyContactName;
    final ecPhone = user?.emergencyContactPhone;
    final hasEmergencyContact =
        ecName != null &&
        ecName.trim().isNotEmpty &&
        ecPhone != null &&
        ecPhone.trim().isNotEmpty;
    final ridesAsync = ref.watch(allAvailableRidesProvider);
    final complaintsAsync = ref.watch(
      passengerComplaintsProvider(user?.email ?? ''),
    );
    final rides = ridesAsync.value ?? const [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Safety & Help'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // High Priority SOS Banner Button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (ctx) => const SosDialog(),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE53935), Color(0xFFC62828)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x33E53935),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Row(
                      children: [
                        Text('🚨', style: TextStyle(fontSize: 34)),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Emergency SOS',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Send your location to SafeSeated Admin',
                                style: TextStyle(
                                  color: Color(0xFFFFEBEE),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Quick Actions Card
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quick actions',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.share_outlined, size: 16),
                            label: const Text(
                              'Share live trip',
                              style: TextStyle(fontSize: 12),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Live trip sharing is not connected in this demo.',
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.phone_outlined, size: 16),
                            label: Text(
                              hasEmergencyContact
                                  ? 'Call $ecName'
                                  : 'Set emergency contact',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            onPressed: hasEmergencyContact
                                ? () => _callPhone(ecPhone)
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Emergency Numbers
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Emergency numbers (Karachi)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildHelplineRow('Police Helpline', '15'),
                    const Divider(height: 16),
                    _buildHelplineRow('Edhi Ambulance Service', '115'),
                    const Divider(height: 16),
                    _buildHelplineRow('Sindh Rescue', '1122'),
                    const Divider(height: 16),
                    _buildHelplineRow(
                      'National Women Helpline',
                      '1099',
                      isHighlight: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Report a problem form
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Report a problem / complaint',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Related ride',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<int>(
                      initialValue:
                          rides.any((ride) => ride.id == _selectedRideId)
                          ? _selectedRideId
                          : null,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                      ),
                      hint: const Text('Select a ride'),
                      items: rides
                          .map(
                            (ride) => DropdownMenuItem(
                              value: ride.id,
                              child: Text(
                                '${ride.from} → ${ride.to} · ${ride.driverName}',
                                style: const TextStyle(fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _selectedRideId = v),
                    ),
                    if (ridesAsync.hasError)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          'Could not load rides: ${ridesAsync.error}',
                          style: const TextStyle(
                            color: AppColors.statusDangerText,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    const Text(
                      'Describe the issue',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _complaintController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText:
                            'Provide details of route deviation, delay or driver conduct...',
                      ),
                    ),
                    const SizedBox(height: 14),
                    AppButton(
                      text: 'Submit complaint',
                      isLoading: _isSubmittingComplaint,
                      onPressed: _submitComplaint,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'My support history',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    complaintsAsync.when(
                      data: (complaints) => complaints.isEmpty
                          ? const Text(
                              'No complaints submitted yet.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            )
                          : Column(
                              children: complaints
                                  .map(
                                    (complaint) => ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(
                                        complaint.rideRoute,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      subtitle: Text(
                                        '${complaint.status} · ${complaint.description}',
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      trailing: Text(
                                        '${complaint.createdAt.day}/${complaint.createdAt.month}',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (error, _) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Could not load support history: $error',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.statusDangerText,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => ref.invalidate(
                              passengerComplaintsProvider(user?.email ?? ''),
                            ),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Help Centre Accordion
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Help centre & FAQs',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      title: const Text(
                        'How are drivers verified?',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      children: const [
                        Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: Text(
                            'Document review is part of the planned verification flow. This demo uses sample records and does not upload documents or perform staff review.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                    ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      title: const Text(
                        'How does payment work?',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      children: const [
                        Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: Text(
                            'The sample rides show mock fares. Real fare collection and reconciliation are not connected in this demo.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                    ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      title: const Text(
                        'Who can use SafeSeated?',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      children: const [
                        Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: Text(
                            'SafeSeated is designed around safer commuting for women. Final eligibility rules must be confirmed in the published service policy.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHelplineRow(
    String service,
    String number, {
    bool isHighlight = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          service,
          style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
        ),
        TextButton.icon(
          onPressed: () => _callPhone(number),
          icon: const Icon(Icons.call_outlined, size: 16),
          label: Text(number),
          style: TextButton.styleFrom(
            foregroundColor: isHighlight
                ? AppColors.primary
                : AppColors.textPrimary,
            backgroundColor: isHighlight
                ? AppColors.accentLavender
                : AppColors.surfaceSubtle,
            side: BorderSide(
              color: isHighlight ? AppColors.primary : AppColors.border,
            ),
          ),
        ),
      ],
    );
  }
}
