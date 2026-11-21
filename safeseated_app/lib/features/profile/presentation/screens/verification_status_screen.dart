import 'package:file_picker/file_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/widgets/app_card.dart';
import '../../data/document_service.dart';

class VerificationStatusScreen extends ConsumerStatefulWidget {
  const VerificationStatusScreen({super.key});

  @override
  ConsumerState<VerificationStatusScreen> createState() =>
      _VerificationStatusScreenState();
}

class _VerificationStatusScreenState
    extends ConsumerState<VerificationStatusScreen> {
  bool _uploading = false;

  List<_RequiredDocument> get _requiredDocuments {
    final user = ref.read(authStateProvider).value;
    if (user?.isDriver ?? false) {
      return const [
        _RequiredDocument('CnicFront', 'CNIC front'),
        _RequiredDocument('CnicBack', 'CNIC back'),
        _RequiredDocument('DrivingLicence', 'Driving licence'),
        _RequiredDocument('VehicleRegistration', 'Vehicle registration'),
        _RequiredDocument('VehiclePhoto', 'Vehicle photo'),
      ];
    }
    return const [
      _RequiredDocument('CnicFront', 'CNIC front'),
      _RequiredDocument('CnicBack', 'CNIC back'),
      _RequiredDocument('StudentCard', 'Student card'),
    ];
  }

  Future<void> _upload(_RequiredDocument requirement) async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'pdf'],
    );
    if (!mounted || file == null) {
      return;
    }

    setState(() => _uploading = true);
    try {
      final bytes = await file.readAsBytes();
      await ref
          .read(documentServiceProvider)
          .upload(
            documentType: requirement.apiValue,
            fileName: file.name,
            bytes: bytes,
          );
      ref.invalidate(myDocumentsProvider);
      await ref.read(authStateProvider.notifier).refreshProfile();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document uploaded successfully.'),
            backgroundColor: AppColors.statusSuccessText,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString()),
            backgroundColor: AppColors.statusDangerText,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _delete(VerificationDocument document) async {
    if (!document.isPending) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete document?'),
        content: Text('Delete the pending ${document.documentType} document?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.statusDangerText),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await ref.read(documentServiceProvider).delete(document.id);
      ref.invalidate(myDocumentsProvider);
      await ref.read(authStateProvider.notifier).refreshProfile();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Document deleted.')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString()),
            backgroundColor: AppColors.statusDangerText,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    final documentsAsync = ref.watch(myDocumentsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Verification status')),
      body: SafeArea(
        child: documentsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Could not load documents: $error'),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () => ref.invalidate(myDocumentsProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
          data: (documents) {
            final latestByType = <String, VerificationDocument>{};
            for (final document in documents) {
              latestByType.putIfAbsent(document.documentType, () => document);
            }

            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(myDocumentsProvider);
                await ref.read(myDocumentsProvider.future);
              },
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: (user?.isApproved ?? false)
                          ? AppColors.statusSuccessBg
                          : AppColors.statusPendingBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: (user?.isApproved ?? false)
                            ? AppColors.statusSuccessBorder
                            : AppColors.statusPendingBorder,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          (user?.isApproved ?? false)
                              ? Icons.verified
                              : Icons.hourglass_top,
                          size: 32,
                          color: (user?.isApproved ?? false)
                              ? AppColors.statusSuccessText
                              : AppColors.statusPendingText,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.status.label ?? 'Pending',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: (user?.isApproved ?? false)
                                      ? AppColors.statusSuccessText
                                      : AppColors.statusPendingText,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Upload each required document for Admin review.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Required documents',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: _requiredDocuments.map((requirement) {
                        final document = latestByType[requirement.apiValue];
                        return ListTile(
                          leading: Icon(
                            document == null
                                ? Icons.upload_file_outlined
                                : document.status.toLowerCase() == 'approved'
                                ? Icons.check_circle
                                : document.status.toLowerCase() == 'rejected'
                                ? Icons.cancel
                                : Icons.pending,
                            color: document == null
                                ? AppColors.textMuted
                                : document.status.toLowerCase() == 'approved'
                                ? AppColors.statusSuccessText
                                : document.status.toLowerCase() == 'rejected'
                                ? AppColors.statusDangerText
                                : AppColors.statusPendingText,
                          ),
                          title: Text(
                            requirement.label,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            document == null
                                ? 'Not uploaded'
                                : '${document.status}${document.rejectionReason == null ? '' : ' · ${document.rejectionReason}'}',
                            style: const TextStyle(fontSize: 11),
                          ),
                          trailing: document == null
                              ? TextButton(
                                  onPressed: _uploading
                                      ? null
                                      : () => _upload(requirement),
                                  child: const Text('Upload'),
                                )
                              : document.isPending
                              ? TextButton(
                                  onPressed: _uploading
                                      ? null
                                      : () => _delete(document),
                                  child: const Text(
                                    'Delete',
                                    style: TextStyle(
                                      color: AppColors.statusDangerText,
                                    ),
                                  ),
                                )
                              : null,
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Row(
                    children: [
                      Icon(
                        Icons.lock_outline,
                        size: 14,
                        color: AppColors.textMuted,
                      ),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'JPG, JPEG, PNG, or PDF. Maximum size 5 MB.',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _RequiredDocument {
  final String apiValue;
  final String label;

  const _RequiredDocument(this.apiValue, this.label);
}
