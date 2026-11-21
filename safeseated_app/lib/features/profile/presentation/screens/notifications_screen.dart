import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/widgets/app_card.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markNotificationsRead();
    });
  }

  Future<void> _markNotificationsRead() async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;
    try {
      await ref.read(authRepositoryProvider).markNotificationsRead(user.email);
      ref.invalidate(notificationsProvider(user.email));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update notifications: $error')),
        );
      }
    }
  }

  void _showPreferences() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Consumer(
          builder: (context, ref, _) {
            final preferences = ref.watch(
              passengerNotificationPreferencesProvider,
            );
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Notification preferences',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                  const Text(
                    'Demo settings apply only during this app session.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Booking updates'),
                    value: preferences.bookingUpdates,
                    onChanged: (value) =>
                        ref
                            .read(
                              passengerNotificationPreferencesProvider.notifier,
                            )
                            .state = preferences.copyWith(
                          bookingUpdates: value,
                        ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Trip reminders'),
                    value: preferences.tripReminders,
                    onChanged: (value) =>
                        ref
                            .read(
                              passengerNotificationPreferencesProvider.notifier,
                            )
                            .state = preferences.copyWith(
                          tripReminders: value,
                        ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Safety alerts'),
                    value: preferences.safetyAlerts,
                    onChanged: (value) =>
                        ref
                            .read(
                              passengerNotificationPreferencesProvider.notifier,
                            )
                            .state = preferences.copyWith(
                          safetyAlerts: value,
                        ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    final notificationsAsync = ref.watch(
      notificationsProvider(user?.email ?? ''),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            tooltip: 'Notification preferences',
            icon: const Icon(Icons.settings_outlined),
            onPressed: _showPreferences,
          ),
        ],
      ),
      body: SafeArea(
        child: notificationsAsync.when(
          data: (list) {
            if (list.isEmpty) {
              return const Center(
                child: Text(
                  'No notifications yet',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              itemBuilder: (context, index) {
                final item = list[index];
                return AppCard(
                  margin: const EdgeInsets.only(bottom: 10),
                  color: item.isRead ? Colors.white : AppColors.surfaceSubtle,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.accentLavender,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.notifications_active,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  item.title,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  item.time,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.body,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error: $err')),
        ),
      ),
    );
  }
}
