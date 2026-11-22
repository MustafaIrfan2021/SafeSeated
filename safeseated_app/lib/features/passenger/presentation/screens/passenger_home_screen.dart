import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/pakistan_time.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/providers/app_providers.dart';
import '../../domain/models/ride.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/avatar_widget.dart';
import '../../../../core/widgets/status_pill.dart';
import 'ride_details_screen.dart';
import 'create_ride_request_dialog.dart';

class PassengerHomeScreen extends ConsumerStatefulWidget {
  const PassengerHomeScreen({super.key});

  @override
  ConsumerState<PassengerHomeScreen> createState() =>
      _PassengerHomeScreenState();
}

class _PassengerHomeScreenState extends ConsumerState<PassengerHomeScreen> {
  final _pickupController = TextEditingController();
  final _destinationController = TextEditingController();
  DateTime? _departureDate;
  int _seatsNeeded = 1;

  final List<String> _popularAreas = [
    'Gulshan-e-Iqbal',
    'Clifton',
    'DHA Phase 5',
    'North Nazimabad',
    'Gulistan-e-Jauhar',
  ];

  @override
  void dispose() {
    _pickupController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  void _applySearch() {
    ref.read(searchFilterProvider.notifier).state = SearchFilter(
      pickup: _pickupController.text,
      destination: _destinationController.text,
      departureDate: _departureDate,
      seatsNeeded: _seatsNeeded,
    );
  }

  Future<void> _selectDepartureDate() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _departureDate ?? today,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
    );
    if (selectedDate != null) {
      setState(() => _departureDate = selectedDate);
      _applySearch();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    final ridesAsync = ref.watch(availableRidesProvider);
    final requestsAsync = ref.watch(
      passengerRideRequestsProvider(user?.email ?? ''),
    );
    final notificationsAsync = ref.watch(
      notificationsProvider(user?.email ?? ''),
    );

    final unreadCount =
        notificationsAsync.value?.where((n) => !n.isRead).length ?? 0;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(availableRidesProvider);
            ref.invalidate(passengerRideRequestsProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Purple Hero Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF7464DF), Color(0xFF40338F)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Assalam o Alaikum 👋',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFFE9E5FF),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.name.split(' ').first ?? 'Passenger',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      Stack(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.notifications_outlined,
                              color: Colors.white,
                              size: 26,
                            ),
                            onPressed: () =>
                                context.push(AppRoutes.notifications),
                          ),
                          if (unreadCount > 0)
                            Positioned(
                              right: 8,
                              top: 8,
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: AppColors.statusDangerText,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Search Box Overlapping Card
                Transform.translate(
                  offset: const Offset(0, -20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Where to?',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _pickupController,
                            decoration: InputDecoration(
                              hintText: 'Pickup area in Karachi',
                              prefixIcon: const Icon(
                                Icons.my_location,
                                size: 18,
                                color: AppColors.primary,
                              ),
                              suffixIcon: _pickupController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 16),
                                      onPressed: () {
                                        _pickupController.clear();
                                        _applySearch();
                                      },
                                    )
                                  : null,
                            ),
                            onChanged: (_) => _applySearch(),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _destinationController,
                            decoration: InputDecoration(
                              hintText: 'Destination (e.g. SMIU / NED / KU)',
                              prefixIcon: const Icon(
                                Icons.location_on,
                                size: 18,
                                color: AppColors.primary,
                              ),
                              suffixIcon: _destinationController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 16),
                                      onPressed: () {
                                        _destinationController.clear();
                                        _applySearch();
                                      },
                                    )
                                  : null,
                            ),
                            onChanged: (_) => _applySearch(),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: const Icon(
                                    Icons.calendar_today_outlined,
                                    size: 16,
                                  ),
                                  label: Text(
                                    _departureDate == null
                                        ? 'Any date'
                                        : DateFormat(
                                            'EEE, d MMM',
                                          ).format(_departureDate!),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  onPressed: _selectDepartureDate,
                                ),
                              ),
                              const SizedBox(width: 8),
                              DropdownButton<int>(
                                value: _seatsNeeded,
                                underline: const SizedBox.shrink(),
                                borderRadius: BorderRadius.circular(12),
                                items: List.generate(
                                  4,
                                  (index) => DropdownMenuItem(
                                    value: index + 1,
                                    child: Text(
                                      '${index + 1} seat${index == 0 ? '' : 's'}',
                                    ),
                                  ),
                                ),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() => _seatsNeeded = value);
                                    _applySearch();
                                  }
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Area chips
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: _popularAreas.map((area) {
                              return GestureDetector(
                                onTap: () {
                                  _pickupController.text = area;
                                  _applySearch();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.accentLavender,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    area,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 14),
                          AppButton(
                            text: 'Search rides',
                            icon: Icons.search,
                            onPressed: _applySearch,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Ride Request Prompt Button
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: AppButton(
                    text: "✋ Can’t find a ride? Request one",
                    variant: AppButtonVariant.secondary,
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(24),
                          ),
                        ),
                        builder: (ctx) => CreateRideRequestDialog(
                          initialPickup: _pickupController.text,
                        ),
                      );
                    },
                  ),
                ),

                // My Ride Requests Section (if any)
                requestsAsync.when(
                  data: (requests) {
                    if (requests.isEmpty) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'My ride requests',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...requests.map((req) {
                            return AppCard(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${req.pickup} ➔ ${req.destination}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ),
                                      StatusPill.fromStatus(req.status.label),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${req.time} · ${req.seats} seat(s) requested',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  if (req.isOpen) ...[
                                    const SizedBox(height: 10),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton.icon(
                                        icon: const Icon(
                                          Icons.cancel_outlined,
                                          size: 16,
                                          color: AppColors.statusDangerText,
                                        ),
                                        label: const Text(
                                          'Cancel request',
                                          style: TextStyle(
                                            color: AppColors.statusDangerText,
                                            fontSize: 12,
                                          ),
                                        ),
                                        onPressed: () async {
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (dialogContext) => AlertDialog(
                                              title: const Text(
                                                'Cancel ride request?',
                                              ),
                                              content: const Text(
                                                'Your request will be marked cancelled and will remain in your request history.',
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                        dialogContext,
                                                        false,
                                                      ),
                                                  child: const Text(
                                                    'Keep request',
                                                  ),
                                                ),
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                        dialogContext,
                                                        true,
                                                      ),
                                                  child: const Text(
                                                    'Cancel request',
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                          if (confirm != true) return;
                                          try {
                                            await ref
                                                .read(rideRepositoryProvider)
                                                .cancelPassengerRideRequest(
                                                  req.id,
                                                );
                                            ref.invalidate(
                                              passengerRideRequestsProvider(
                                                user?.email ?? '',
                                              ),
                                            );
                                          } catch (error) {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'Could not cancel request: $error',
                                                  ),
                                                ),
                                              );
                                            }
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (error, _) => const SizedBox.shrink(),
                ),

                // Available Rides Section
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Available rides',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      ridesAsync.when(
                        data: (rides) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accentLavender,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${rides.length} rides',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        loading: () => const SizedBox.shrink(),
                        error: (error, _) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),

                // Ride Cards List
                ridesAsync.when(
                  data: (rides) {
                    if (rides.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Column(
                            children: [
                              const Icon(
                                Icons.search_off,
                                size: 48,
                                color: AppColors.textMuted,
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'No matching rides found',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Try clearing your search query or post a ride request for drivers.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                ),
                              ),
                              const SizedBox(height: 14),
                              AppButton(
                                text: 'Clear filters',
                                variant: AppButtonVariant.outline,
                                isFullWidth: false,
                                onPressed: () {
                                  _pickupController.clear();
                                  _destinationController.clear();
                                  setState(() {
                                    _departureDate = null;
                                    _seatsNeeded = 1;
                                  });
                                  _applySearch();
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      itemCount: rides.length,
                      itemBuilder: (context, index) {
                        final ride = rides[index];
                        return _buildRideCard(context, ride);
                      },
                    );
                  },
                  loading: () => const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (error, _) => Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Text('Error loading rides: $error'),
                        TextButton.icon(
                          onPressed: () =>
                              ref.invalidate(availableRidesProvider),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRideCard(BuildContext context, Ride ride) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (ctx) => RideDetailsScreen(ride: ride)),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AvatarWidget(name: ride.driverName, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ride.driverName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          size: 12,
                          color: AppColors.starGold,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${ride.driverRating} · ${ride.driverReviewCount} reviews',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const StatusPill(
                text: '✓ Verified',
                variant: PillVariant.success,
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            children: [
              const Icon(
                Icons.directions_car,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${ride.from} ➔ ${ride.to}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${DateFormat('EEE, d MMM').format(PakistanTime.toPakistan(ride.departureAt))} · ${ride.departureTime} · ${ride.vehicleInfo}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Rs ${ride.farePerSeat} / seat',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Seat progress indicator
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ride.seatsTotal > 0
                  ? (ride.seatsBooked / ride.seatsTotal)
                  : 0,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(
                ride.isFull ? AppColors.statusDangerText : AppColors.primary,
              ),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${ride.seatsAvailable} of ${ride.seatsTotal} seats left',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: ride.isFull
                      ? AppColors.statusDangerText
                      : AppColors.primary,
                ),
              ),
              const Text(
                'Tap for details →',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
