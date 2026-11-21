import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../constants/app_colors.dart';
import 'app_card.dart';

class PickedDocumentImage {
  final Uint8List bytes;
  final String name;

  const PickedDocumentImage({required this.bytes, required this.name});
}

Future<PickedDocumentImage?> pickDocumentImage(BuildContext context) async {
  try {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 2048,
    );
    if (image == null) return null;

    return PickedDocumentImage(
      bytes: await image.readAsBytes(),
      name: image.name,
    );
  } on PlatformException catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not select image: ${error.message ?? error.code}',
          ),
          backgroundColor: AppColors.statusDangerText,
        ),
      );
    }
    return null;
  }
}

class DocumentImagePickerTile extends StatelessWidget {
  final String label;
  final PickedDocumentImage? image;
  final VoidCallback onSelect;
  final VoidCallback onRemove;

  const DocumentImagePickerTile({
    super.key,
    required this.label,
    required this.image,
    required this.onSelect,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      color: image == null ? Colors.white : AppColors.statusSuccessBg,
      border: Border.all(
        color: image == null ? AppColors.border : AppColors.statusSuccessBorder,
      ),
      child: Row(
        children: [
          if (image == null)
            const Icon(
              Icons.upload_file_outlined,
              color: AppColors.textMuted,
              size: 22,
            )
          else
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(
                image!.bytes,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
              ),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  image?.name ?? 'Choose an image from your device',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: image == null
                        ? AppColors.textMuted
                        : AppColors.statusSuccessText,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: image == null ? onSelect : onRemove,
            child: Text(
              image == null ? 'Upload' : 'Remove',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: image == null
                    ? AppColors.primary
                    : AppColors.statusDangerText,
              ),
            ),
          ),
          if (image != null)
            IconButton(
              tooltip: 'Choose a different image',
              onPressed: onSelect,
              icon: const Icon(Icons.refresh, size: 20),
              color: AppColors.primary,
            ),
        ],
      ),
    );
  }
}
