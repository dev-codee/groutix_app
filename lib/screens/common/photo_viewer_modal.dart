import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../../models/lead_model.dart';

class PhotoViewerModal extends StatelessWidget {
  final LeadPhoto photo;
  final VoidCallback? onDelete;

  const PhotoViewerModal({
    super.key,
    required this.photo,
    this.onDelete,
  });

  static void show(BuildContext context, LeadPhoto photo, {VoidCallback? onDelete}) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (ctx) => PhotoViewerModal(photo: photo, onDelete: onDelete),
    );
  }

  @override
  Widget build(BuildContext context) {
    final url = photo.displayUrl;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Zoomable Image
          Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
              maxWidth: MediaQuery.of(context).size.width * 0.95,
            ),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(16),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: InteractiveViewer(
                    panEnabled: true,
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Center(
                      child: url.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: url,
                              fit: BoxFit.contain,
                              placeholder: (ctx, _) => const Center(
                                child: CircularProgressIndicator(color: Colors.white),
                              ),
                              errorWidget: (ctx, err, stack) => const Center(
                                child: Icon(Icons.broken_image_rounded, color: Colors.white, size: 48),
                              ),
                            )
                          : const Center(
                              child: Icon(Icons.image_not_supported_rounded, color: Colors.white, size: 48),
                            ),
                    ),
                  ),
                ),
                // Footer details: uploaded by / date
                Container(
                  color: Colors.black87,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              photo.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (photo.uploadedBy != null)
                              Text(
                                'Uploaded by ${photo.uploadedBy}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (onDelete != null)
                        IconButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            onDelete!();
                          },
                          icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
                          tooltip: 'Delete Photo',
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Close button
          Positioned(
            top: -12,
            right: -12,
            child: Material(
              color: Colors.white,
              shape: const CircleBorder(),
              elevation: 4,
              child: InkWell(
                onTap: () => Navigator.of(context).pop(),
                customBorder: const CircleBorder(),
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.close_rounded, size: 20, color: AppColors.textPrimary),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
