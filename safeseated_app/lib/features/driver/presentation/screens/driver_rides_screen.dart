import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/utils/pakistan_time.dart';
import '../../../auth/domain/models/user.dart';
import '../../../passenger/domain/models/ride.dart';

class DriverRidesScreen extends ConsumerWidget {
  const DriverRidesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    if (user == null) return const SizedBox.shrink();
    final rides = ref.watch(driverRidesProvider(user.email));
    final bookings = ref.watch(driverBookingsProvider(user.email));
    return Scaffold(
      appBar: AppBar(
        title: const Text('My rides'),
        automaticallyImplyLeading: false,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.driverPostRide),
        icon: const Icon(Icons.add),
        label: const Text('Post ride'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(driverRidesProvider(user.email));
          await ref.read(driverRidesProvider(user.email).future);
        },
        child: rides.when(
          data: (items) {
            if (items.isEmpty) {
              return ListView(
                children: [
                  SizedBox(height: 100),
                  Center(child: Text('No rides posted yet.')),
                ],
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
              itemCount: items.length,
              itemBuilder: (context, index) => _RideCard(
                ride: items[index],
                user: user,
                bookingCount: bookings.valueOrNull
                    ?.where((booking) => booking.rideId == items[index].id)
                    .length,
                onChanged: () {
                  ref.invalidate(driverRidesProvider(user.email));
                  ref.invalidate(availableRidesProvider);
                  ref.invalidate(allAvailableRidesProvider);
                },
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) =>
              Center(child: Text('Could not load rides: $error')),
        ),
      ),
    );
  }
}

class _RideCard extends ConsumerWidget {
  final Ride ride;
  final User user;
  final int? bookingCount;
  final VoidCallback onChanged;

  const _RideCard({
    required this.ride,
    required this.user,
    required this.bookingCount,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${ride.from} → ${ride.to}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              _RideStateLabel(active: ride.isActive),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${_dateLabel(PakistanTime.toPakistan(ride.departureAt))} · ${ride.departureTime}',
          ),
          Text(
            'PKR ${ride.farePerSeat} / seat · ${ride.seatsAvailable} of ${ride.seatsTotal} available',
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: ride.seatsBooked / ride.seatsTotal,
            minHeight: 5,
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Requests',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
              Text(
                bookingCount?.toString() ?? '—',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          if (ride.notes.isNotEmpty) Text('Note: ${ride.notes}'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              if (ride.isActive)
                OutlinedButton.icon(
                  onPressed: () async {
                    final updated = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Edit ride'),
                        content: SingleChildScrollView(
                          child: DriverRideForm(
                            ride: ride,
                            user: user,
                            embedded: true,
                          ),
                        ),
                      ),
                    );
                    if (updated == true) onChanged();
                  },
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit'),
                ),
              if (ride.isActive)
                TextButton.icon(
                  onPressed: () => _cancel(context, ref),
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Cancel ride'),
                ),
            ],
          ),
        ],
      ),
    ),
  );

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel this ride?'),
        content: const Text(
          'Rides with confirmed passengers cannot be cancelled.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep ride'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancel ride'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ref
          .read(rideRepositoryProvider)
          .cancelDriverRide(ride.id, user.email);
      onChanged();
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceAll('Bad state: ', '')),
          ),
        );
      }
    }
  }
}

class DriverRideEditorScreen extends ConsumerWidget {
  const DriverRideEditorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    if (user == null) return const SizedBox.shrink();
    return Scaffold(
      appBar: AppBar(title: const Text('Post a ride')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: DriverRideForm(
          user: user,
          onSaved: () {
            ref.invalidate(driverRidesProvider(user.email));
            ref.invalidate(availableRidesProvider);
            ref.invalidate(allAvailableRidesProvider);
            if (context.mounted) context.go(AppRoutes.driverRides);
          },
        ),
      ),
    );
  }
}

class DriverRideForm extends ConsumerStatefulWidget {
  final User user;
  final Ride? ride;
  final bool embedded;
  final VoidCallback? onSaved;

  const DriverRideForm({
    super.key,
    required this.user,
    this.ride,
    this.embedded = false,
    this.onSaved,
  });

  @override
  ConsumerState<DriverRideForm> createState() => _DriverRideFormState();
}

class _DriverRideFormState extends ConsumerState<DriverRideForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _from;
  late final TextEditingController _to;
  late final TextEditingController _fare;
  late final TextEditingController _seats;
  late final TextEditingController _notes;
  late DateTime _date;
  late TimeOfDay _time;
  bool _saving = false;

  static TimeOfDay _parseTime(String? value) {
    if (value == null) return const TimeOfDay(hour: 8, minute: 0);
    final match = RegExp(
      r'^(\d{1,2}):(\d{2})\s*(AM|PM)$',
      caseSensitive: false,
    ).firstMatch(value.trim());
    if (match == null) return const TimeOfDay(hour: 8, minute: 0);
    var hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    if (match.group(3)!.toUpperCase() == 'PM' && hour != 12) hour += 12;
    if (match.group(3)!.toUpperCase() == 'AM' && hour == 12) hour = 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  @override
  void initState() {
    super.initState();
    _from = TextEditingController(text: widget.ride?.from ?? '');
    _to = TextEditingController(text: widget.ride?.to ?? '');
    _fare = TextEditingController(
      text: widget.ride?.farePerSeat.toString() ?? '',
    );
    _seats = TextEditingController(
      text: (widget.ride?.seatsTotal ?? widget.user.seatsTotal).toString(),
    );
    _notes = TextEditingController(text: widget.ride?.notes ?? '');
    final departure = PakistanTime.toPakistan(
      widget.ride?.departureAt ?? DateTime.now().toUtc(),
    );
    _date = DateTime(departure.year, departure.month, departure.day);
    _time = _parseTime(widget.ride?.departureTime);
  }

  @override
  void dispose() {
    _from.dispose();
    _to.dispose();
    _fare.dispose();
    _seats.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final departureTime = _time.format(context);
    final repository = ref.read(rideRepositoryProvider);
    try {
      if (widget.ride == null) {
        await repository.publishDriverRide(
          driverEmail: widget.user.email,
          driverName: widget.user.name,
          from: _from.text,
          to: _to.text,
          departureAt: _date,
          departureTime: departureTime,
          farePerSeat: int.parse(_fare.text),
          seatsTotal: int.parse(_seats.text),
          vehicleInfo:
              '${widget.user.vehicleMake ?? 'Vehicle'} · ${widget.user.vehicleColor ?? ''}',
          vehiclePlate:
              widget.user.vehiclePlate ?? widget.user.vehicleRegistration ?? '',
          notes: _notes.text,
        );
      } else {
        await repository.updateDriverRide(
          rideId: widget.ride!.id,
          driverEmail: widget.user.email,
          from: _from.text,
          to: _to.text,
          departureAt: _date,
          departureTime: departureTime,
          farePerSeat: int.parse(_fare.text),
          seatsTotal: int.parse(_seats.text),
          notes: _notes.text,
        );
      }
      if (!mounted) return;
      if (widget.embedded) {
        Navigator.pop(context, true);
      } else {
        widget.onSaved?.call();
      }
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

  @override
  Widget build(BuildContext context) {
    final fields = <Widget>[
      TextFormField(
        controller: _from,
        decoration: const InputDecoration(labelText: 'Pickup location'),
        validator: _required,
      ),
      TextFormField(
        controller: _to,
        decoration: const InputDecoration(labelText: 'Destination'),
        validator: (value) {
          final error = _required(value);
          if (error != null) return error;
          if (value!.trim().toLowerCase() == _from.text.trim().toLowerCase()) {
            return 'Pickup and destination must be different';
          }
          return null;
        },
      ),
      ListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Departure date'),
        subtitle: Text('${_date.day}/${_date.month}/${_date.year}'),
        trailing: const Icon(Icons.calendar_today_outlined),
        onTap: () async {
          final selected = await showDatePicker(
            context: context,
            initialDate: _date.isBefore(DateTime.now())
                ? DateTime.now()
                : _date,
            firstDate: DateTime(
              DateTime.now().year,
              DateTime.now().month,
              DateTime.now().day,
            ),
            lastDate: DateTime.now().add(const Duration(days: 365)),
          );
          if (selected != null) setState(() => _date = selected);
        },
      ),
      ListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Departure time'),
        subtitle: Text(_time.format(context)),
        trailing: const Icon(Icons.access_time),
        onTap: () async {
          final selected = await showTimePicker(
            context: context,
            initialTime: _time,
          );
          if (selected != null) setState(() => _time = selected);
        },
      ),
      TextFormField(
        controller: _fare,
        decoration: const InputDecoration(labelText: 'Fare per seat (PKR)'),
        keyboardType: TextInputType.number,
        validator: (value) {
          final amount = int.tryParse(value ?? '');
          return amount == null || amount < 1
              ? 'Enter a fare greater than zero'
              : null;
        },
      ),
      TextFormField(
        controller: _seats,
        decoration: const InputDecoration(labelText: 'Passenger seats (1–4)'),
        keyboardType: TextInputType.number,
        validator: (value) {
          final count = int.tryParse(value ?? '');
          if (count == null || count < 1 || count > 4) {
            return 'Enter 1 to 4 seats';
          }
          if (count > widget.user.seatsTotal) {
            return 'Your registered vehicle capacity is ${widget.user.seatsTotal} seats';
          }
          if (widget.ride != null && count < widget.ride!.seatsBooked) {
            return 'Cannot be fewer than ${widget.ride!.seatsBooked} already booked seats';
          }
          return null;
        },
      ),
      TextFormField(
        controller: _notes,
        decoration: const InputDecoration(labelText: 'Notes (optional)'),
        maxLines: 2,
      ),
    ];
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...fields,
          const SizedBox(height: 16),
          if (widget.embedded)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: Text(_saving ? 'Saving…' : 'Save changes'),
                ),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Publishing…' : 'Publish ride'),
              ),
            ),
          const SizedBox(height: 12),
          const Text(
            'Posting is local to this prototype. No messaging, matching, or payment is sent.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'This field is required' : null;
}

class _RideStateLabel extends StatelessWidget {
  final bool active;
  const _RideStateLabel({required this.active});
  @override
  Widget build(BuildContext context) => Chip(
    label: Text(active ? 'Published' : 'Cancelled'),
    visualDensity: VisualDensity.compact,
  );
}

String _dateLabel(DateTime date) => '${date.day}/${date.month}/${date.year}';
