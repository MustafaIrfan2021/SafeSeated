import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../auth/domain/models/user.dart';
import '../../../profile/presentation/screens/verification_status_screen.dart';

enum DriverProfileSection {
  personalInformation,
  vehicleDetails,
  ratingsAndReviews,
  verificationStatus,
}

class DriverProfileDetailScreen extends ConsumerWidget {
  final DriverProfileSection section;
  final Future<void> Function(BuildContext context, User user) onEditProfile;

  const DriverProfileDetailScreen({
    super.key,
    required this.section,
    required this.onEditProfile,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    if (user == null) return const SizedBox.shrink();

    final title = switch (section) {
      DriverProfileSection.personalInformation => 'Personal information',
      DriverProfileSection.vehicleDetails => 'Vehicle details',
      DriverProfileSection.ratingsAndReviews => 'Ratings & reviews',
      DriverProfileSection.verificationStatus => 'Verification status',
    };

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          switch (section) {
            DriverProfileSection.personalInformation => _personalInformation(
              context,
              user,
            ),
            DriverProfileSection.vehicleDetails => _vehicleDetails(
              context,
              user,
            ),
            DriverProfileSection.ratingsAndReviews => _ratingsAndReviews(
              ref,
              user,
            ),
            DriverProfileSection.verificationStatus => _verificationStatus(
              context,
              user,
            ),
          },
        ],
      ),
    );
  }

  Widget _personalInformation(BuildContext context, User user) => Card(
    child: Column(
      children: [
        ListTile(title: const Text('Name'), subtitle: Text(user.name)),
        ListTile(title: const Text('Email'), subtitle: Text(user.email)),
        ListTile(title: const Text('Phone'), subtitle: Text(user.phone)),
        ListTile(
          title: const Text('City'),
          subtitle: Text(user.city ?? 'Not set'),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => onEditProfile(context, user),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Edit profile'),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _vehicleDetails(BuildContext context, User user) => Card(
    child: Column(
      children: [
        ListTile(
          title: const Text('Make & model'),
          subtitle: Text(user.vehicleMake ?? 'Not set'),
        ),
        ListTile(
          title: const Text('Colour'),
          subtitle: Text(user.vehicleColor ?? 'Not set'),
        ),
        ListTile(
          title: const Text('Plate number'),
          subtitle: Text(user.vehiclePlate ?? 'Not set'),
        ),
        ListTile(
          title: const Text('Registration number'),
          subtitle: Text(user.vehicleRegistration ?? 'Not set'),
        ),
        ListTile(
          title: const Text('Model year · passenger seats'),
          subtitle: Text(
            '${user.vehicleYear ?? 'Not set'} · ${user.seatsTotal}',
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => onEditProfile(context, user),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Edit vehicle details'),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _ratingsAndReviews(WidgetRef ref, User user) {
    final bookings = ref.watch(driverBookingsProvider(user.email));
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.star, color: Colors.amber),
            title: Text('${user.rating.toStringAsFixed(1)} average rating'),
            subtitle: Text('${user.reviewsCount} reviews'),
          ),
          const Divider(height: 1),
          bookings.when(
            data: (items) {
              final reviewed = items.where(
                (booking) =>
                    booking.rating != null || booking.reviewText != null,
              );
              if (reviewed.isEmpty) {
                return const ListTile(title: Text('No reviews yet.'));
              }
              return Column(
                children: reviewed
                    .map(
                      (booking) => ListTile(
                        leading: const Icon(Icons.star, color: Colors.amber),
                        title: Text(
                          '${booking.rating ?? '—'} / 5 · ${booking.passengerName}',
                        ),
                        subtitle: Text(booking.reviewText ?? ''),
                      ),
                    )
                    .toList(),
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
            error: (error, stack) =>
                ListTile(title: Text('Could not load reviews: $error')),
          ),
        ],
      ),
    );
  }

  Widget _verificationStatus(BuildContext context, User user) => Card(
    child: Column(
      children: [
        ListTile(
          leading: Icon(user.isApproved ? Icons.verified : Icons.hourglass_top),
          title: const Text('Verification status'),
          subtitle: Text(user.status.label),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const VerificationStatusScreen(),
                ),
              ),
              icon: const Icon(Icons.folder_open_outlined),
              label: const Text('Manage documents'),
            ),
          ),
        ),
      ],
    ),
  );
}
