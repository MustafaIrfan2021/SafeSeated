import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/app_providers.dart';
import '../../domain/models/driver_fee_calculator.dart';
import '../../domain/models/driver_fee_payment.dart';
import '../../../passenger/domain/models/booking.dart';

class DriverWalletScreen extends ConsumerWidget {
  const DriverWalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    if (user == null) return const SizedBox.shrink();
    final bookings = ref.watch(driverBookingsProvider(user.email));
    final payments = ref.watch(driverFeePaymentsProvider(user.email));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wallet'),
        automaticallyImplyLeading: false,
      ),
      body: bookings.when(
        data: (items) {
          final completed = items
              .where((booking) => booking.status == BookingStatus.completed)
              .toList();
          final earned = completed.fold<int>(
            0,
            (total, booking) => total + booking.totalFare,
          );
          final feeTotal = calculatePlatformFee(earned);
          final submitted = payments.fold<int>(
            0,
            (total, payment) => total + payment.amount,
          );
          final due = calculateFeeDue(
            completedFareTotal: earned,
            submittedTotal: submitted,
          );
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                color: AppColors.primary,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total earnings',
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'PKR $earned',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      Text(
                        '${completed.length} completed trips',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _BalanceCard(label: 'SafeSeated fee (20%)', amount: feeTotal),
              _BalanceCard(
                label: 'Fee due now',
                amount: due,
                highlight: due > 0,
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: due == 0
                    ? null
                    : () => _submitFee(context, ref, user.email, due),
                child: const Text('Pay service fee'),
              ),
              const SizedBox(height: 4),
              const Text(
                'Demo only: submissions are local records, not payments. No money or receipt is sent.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 18),
              Text(
                'Fee submissions',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              if (payments.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'No fee submissions yet.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              else
                ...payments.map(
                  (payment) => _PaymentCard(
                    payment: payment,
                    onApprove: () =>
                        _simulateApproval(context, ref, user.email, payment),
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            Center(child: Text('Could not load wallet: $error')),
      ),
    );
  }

  Future<void> _submitFee(
    BuildContext context,
    WidgetRef ref,
    String email,
    int amountDue,
  ) async {
    final payment = await showDialog<DriverFeePayment>(
      context: context,
      builder: (_) => _FeeSubmissionDialog(amountDue: amountDue),
    );
    if (payment == null) return;
    final payments = ref.read(driverFeePaymentsProvider(email));
    ref.read(driverFeePaymentsProvider(email).notifier).state = [
      payment,
      ...payments,
    ];
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Demo submission saved locally; no payment was processed.',
          ),
        ),
      );
    }
  }

  void _simulateApproval(
    BuildContext context,
    WidgetRef ref,
    String email,
    DriverFeePayment payment,
  ) {
    final payments = ref.read(driverFeePaymentsProvider(email));
    ref.read(driverFeePaymentsProvider(email).notifier).state = [
      for (final item in payments)
        if (item.reference == payment.reference)
          item.copyWith(status: DriverFeePaymentStatus.approved)
        else
          item,
    ];
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Demo approval recorded locally.')),
    );
  }
}

class _FeeSubmissionDialog extends StatefulWidget {
  final int amountDue;

  const _FeeSubmissionDialog({required this.amountDue});

  @override
  State<_FeeSubmissionDialog> createState() => _FeeSubmissionDialogState();
}

class _FeeSubmissionDialogState extends State<_FeeSubmissionDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _amount = TextEditingController(text: widget.amountDue.toString());
  final _transactionId = TextEditingController();
  String _method = 'Easypaisa';
  bool _receiptSelected = false;

  @override
  void dispose() {
    _amount.dispose();
    _transactionId.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (!_receiptSelected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select the demo receipt placeholder to continue.'),
        ),
      );
      return;
    }
    Navigator.of(context).pop(
      DriverFeePayment(
        submittedAt: DateTime.now(),
        amount: int.parse(_amount.text),
        reference: _transactionId.text.trim(),
        method: _method,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Pay service fee'),
    content: Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _BalanceCard(label: 'Fee due', amount: widget.amountDue),
              const SizedBox(height: 4),
              const Text(
                'This form only records a local demo entry. Do not send money or real receipts.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              TextFormField(
                controller: _amount,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Amount (PKR)'),
                validator: (value) {
                  final amount = int.tryParse(value ?? '');
                  return amount == null || amount < 1
                      ? 'Enter a positive amount'
                      : null;
                },
              ),
              DropdownButtonFormField<String>(
                initialValue: _method,
                decoration: const InputDecoration(labelText: 'Payment method'),
                items: const [
                  DropdownMenuItem(
                    value: 'Easypaisa',
                    child: Text('Easypaisa'),
                  ),
                  DropdownMenuItem(value: 'JazzCash', child: Text('JazzCash')),
                  DropdownMenuItem(
                    value: 'Bank transfer',
                    child: Text('Bank transfer'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _method = value);
                },
              ),
              TextFormField(
                controller: _transactionId,
                decoration: const InputDecoration(labelText: 'Transaction ID'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter a transaction ID'
                    : null,
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _receiptSelected,
                title: const Text('Payment receipt (demo placeholder)'),
                subtitle: const Text('No file is uploaded or stored.'),
                onChanged: (value) =>
                    setState(() => _receiptSelected = value ?? false),
              ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: _submit,
        child: const Text('Submit payment details'),
      ),
    ],
  );
}

class _PaymentCard extends StatelessWidget {
  final DriverFeePayment payment;
  final VoidCallback onApprove;

  const _PaymentCard({required this.payment, required this.onApprove});

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'PKR ${payment.amount} · ${payment.method}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Chip(
                label: Text(payment.status.label),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          Text(
            'Txn ${payment.reference} · ${_dateLabel(payment.submittedAt)}',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          if (payment.status == DriverFeePaymentStatus.pending)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: onApprove,
                child: const Text('Demo: simulate payment approval'),
              ),
            ),
        ],
      ),
    ),
  );
}

class _BalanceCard extends StatelessWidget {
  final String label;
  final int amount;
  final bool highlight;

  const _BalanceCard({
    required this.label,
    required this.amount,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) => Card(
    color: highlight ? AppColors.accentLavender : null,
    child: ListTile(
      title: Text(label),
      trailing: Text(
        'PKR $amount',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: highlight ? AppColors.primary : AppColors.textPrimary,
        ),
      ),
    ),
  );
}

String _dateLabel(DateTime date) => '${date.day}/${date.month}/${date.year}';
