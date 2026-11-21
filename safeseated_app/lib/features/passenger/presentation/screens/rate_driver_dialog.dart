import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/app_providers.dart';
import '../../domain/models/booking.dart';
import '../../../../core/widgets/app_button.dart';

class RateDriverDialog extends ConsumerStatefulWidget {
  final Booking booking;

  const RateDriverDialog({super.key, required this.booking});

  @override
  ConsumerState<RateDriverDialog> createState() => _RateDriverDialogState();
}

class _RateDriverDialogState extends ConsumerState<RateDriverDialog> {
  int _rating = 5;
  final _reviewController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (_rating < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select 1 to 5 stars.'),
          backgroundColor: AppColors.statusDangerText,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final repo = ref.read(bookingRepositoryProvider);
      await repo.rateDriver(
        bookingId: widget.booking.id,
        rating: _rating,
        reviewText: _reviewController.text.trim().isNotEmpty
            ? _reviewController.text.trim()
            : 'Punctual, safe and courteous driver.',
      );

      final user = ref.read(authStateProvider).value;
      if (user != null) {
        ref.invalidate(passengerBookingsProvider(user.email));
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Thank you! Your rating and review have been submitted.',
            ),
            backgroundColor: AppColors.statusSuccessText,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.statusDangerText,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Rate your driver',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.close,
                  size: 20,
                  color: AppColors.textMuted,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Your feedback helps maintain high safety standards across SafeSeated.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),

          // Star row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final starNum = index + 1;
              return IconButton(
                icon: Icon(
                  starNum <= _rating
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  color: AppColors.starGold,
                  size: 38,
                ),
                onPressed: () => setState(() => _rating = starNum),
              );
            }),
          ),
          const SizedBox(height: 16),

          // Review textarea
          TextField(
            controller: _reviewController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText:
                  'Share your experience (punctuality, car condition, route safety)...',
            ),
          ),
          const SizedBox(height: 20),

          AppButton(
            text: 'Submit review',
            isLoading: _isSubmitting,
            onPressed: _submitReview,
          ),
        ],
      ),
    );
  }
}
