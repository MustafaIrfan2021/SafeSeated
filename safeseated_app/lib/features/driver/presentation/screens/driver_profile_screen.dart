import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/widgets/avatar_widget.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../auth/domain/models/user.dart';
import '../../../profile/presentation/screens/password_security_screen.dart';
import 'driver_profile_detail_screen.dart';

class DriverProfileScreen extends ConsumerWidget {
  const DriverProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    if (user == null) return const SizedBox.shrink();
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF7464DF), Color(0xFF40338F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.all(Radius.circular(20)),
            ),
            child: Column(
              children: [
                AvatarWidget(
                  name: user.name,
                  size: 70,
                  backgroundColor: Colors.white,
                  textColor: AppColors.primary,
                ),
                const SizedBox(height: 10),
                Text(
                  user.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Driver · ⭐ ${user.rating.toStringAsFixed(1)}',
                  style: const TextStyle(
                    color: Color(0xFFE9E5FF),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                StatusPill(
                  text: user.isApproved ? '✓ Verified' : 'Pending review',
                  variant: user.isApproved
                      ? PillVariant.success
                      : PillVariant.pending,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Personal information'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _openSection(
                context,
                DriverProfileSection.personalInformation,
                (context, user) => _editProfile(context, user),
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.directions_car_outlined),
              title: const Text('Vehicle details'),
              subtitle: Text(
                '${user.vehicleMake ?? 'Vehicle not set'} · '
                '${user.vehiclePlate ?? user.vehicleRegistration ?? 'Registration not set'}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _openSection(
                context,
                DriverProfileSection.vehicleDetails,
                (context, user) => _editProfile(context, user),
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.star_outline),
              title: const Text('Ratings & reviews'),
              subtitle: Text(
                '${user.rating.toStringAsFixed(1)} · ${user.reviewsCount} reviews',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _openSection(
                context,
                DriverProfileSection.ratingsAndReviews,
                (context, user) => _editProfile(context, user),
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.verified_user_outlined),
              title: const Text('Verification status'),
              subtitle: Text(user.status.label),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _openSection(
                context,
                DriverProfileSection.verificationStatus,
                (context, user) => _editProfile(context, user),
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.lock_outline),
              title: const Text('Password & security'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PasswordSecurityScreen(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () async {
              await ref.read(authStateProvider.notifier).logout();
              if (context.mounted) context.go(AppRoutes.welcome);
            },
            icon: const Icon(Icons.logout),
            label: const Text('Log out'),
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: () async {
              await ref.read(authStateProvider.notifier).resetDemoData();
              if (context.mounted) context.go(AppRoutes.welcome);
            },
            child: const Text('Reset demo data'),
          ),
        ],
      ),
    );
  }

  Future<void> _editProfile(BuildContext context, User user) async {
    await showDialog<bool>(
      context: context,
      builder: (_) => _DriverProfileEditor(user: user),
    );
  }

  void _openSection(
    BuildContext context,
    DriverProfileSection section,
    Future<void> Function(BuildContext context, User user) onEditProfile,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => DriverProfileDetailScreen(
          section: section,
          onEditProfile: onEditProfile,
        ),
      ),
    );
  }
}

class _DriverProfileEditor extends ConsumerStatefulWidget {
  final User user;
  const _DriverProfileEditor({required this.user});

  @override
  ConsumerState<_DriverProfileEditor> createState() =>
      _DriverProfileEditorState();
}

class _DriverProfileEditorState extends ConsumerState<_DriverProfileEditor> {
  late final _controllers = <String, TextEditingController>{
    'name': TextEditingController(text: widget.user.name),
    'phone': TextEditingController(text: widget.user.phone),
    'city': TextEditingController(text: widget.user.city ?? ''),
    'licence': TextEditingController(text: widget.user.licenseNumber ?? ''),
    'registration': TextEditingController(
      text: widget.user.vehicleRegistration ?? widget.user.vehiclePlate ?? '',
    ),
    'make': TextEditingController(text: widget.user.vehicleMake ?? ''),
    'color': TextEditingController(text: widget.user.vehicleColor ?? ''),
    'plate': TextEditingController(text: widget.user.vehiclePlate ?? ''),
    'year': TextEditingController(text: widget.user.vehicleYear ?? ''),
    'seats': TextEditingController(text: widget.user.seatsTotal.toString()),
  };
  bool _saving = false;

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Edit driver profile'),
    content: SizedBox(
      width: 420,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _controllers.entries
              .map(
                (entry) => TextField(
                  controller: entry.value,
                  keyboardType: entry.key == 'seats'
                      ? TextInputType.number
                      : TextInputType.text,
                  decoration: InputDecoration(labelText: _label(entry.key)),
                ),
              )
              .toList(),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context, false),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: _saving ? null : _save,
        child: Text(_saving ? 'Saving…' : 'Save'),
      ),
    ],
  );

  String _label(String key) => switch (key) {
    'licence' => 'Driving licence',
    'registration' => 'Vehicle registration',
    'make' => 'Vehicle make/model',
    'plate' => 'Vehicle plate',
    'seats' => 'Passenger seats (1–4)',
    _ => key[0].toUpperCase() + key.substring(1),
  };

  Future<void> _save() async {
    final seats = int.tryParse(_controllers['seats']!.text);
    if (seats == null ||
        seats < 1 ||
        seats > 4 ||
        _controllers.values.any(
          (controller) => controller.text.trim().isEmpty,
        )) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Complete every field and enter 1 to 4 seats.'),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(authStateProvider.notifier)
          .updateDriverProfile(
            name: _controllers['name']!.text,
            phone: _controllers['phone']!.text,
            city: _controllers['city']!.text,
            licenseNumber: _controllers['licence']!.text,
            vehicleRegistration: _controllers['registration']!.text,
            vehicleMake: _controllers['make']!.text,
            vehicleColor: _controllers['color']!.text,
            vehiclePlate: _controllers['plate']!.text,
            vehicleYear: _controllers['year']!.text,
            seatsTotal: seats,
          );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceAll('Bad state: ', '')),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
