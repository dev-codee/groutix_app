import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/leads_provider.dart';
import '../common/empty_state.dart';
import '../common/photo_viewer_modal.dart';

class InspectionPhotosScreen extends StatefulWidget {
  final String leadId;

  const InspectionPhotosScreen({super.key, required this.leadId});

  @override
  State<InspectionPhotosScreen> createState() => _InspectionPhotosScreenState();
}

class _InspectionPhotosScreenState extends State<InspectionPhotosScreen> {
  final _picker = ImagePicker();
  bool _isUploading = false;

  Future<void> _captureCamera() async {
    final photo = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (photo == null) return;
    _upload([photo]);
  }

  Future<void> _pickGallery() async {
    final photos = await _picker.pickMultiImage(imageQuality: 85);
    if (photos.isEmpty) return;
    _upload(photos);
  }

  Future<void> _upload(List<XFile> files) async {
    setState(() => _isUploading = true);
    final leadsProv = context.read<LeadsProvider>();
    final success = await leadsProv.uploadPhotos(widget.leadId, files);
    setState(() => _isUploading = false);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Uploaded ${files.length} photo(s)' : 'Upload failed.'),
        backgroundColor: success ? AppColors.success : AppColors.danger,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final leadsProv = context.watch<LeadsProvider>();
    final lead = leadsProv.getLeadById(widget.leadId);
    final photos = lead?.photos ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text('Site Photos (${photos.length})'),
        actions: [
          if (_isUploading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Action Buttons Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isUploading ? null : _captureCamera,
                    icon: const Icon(Icons.camera_alt_rounded, size: 16),
                    label: const Text('Take Photo'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isUploading ? null : _pickGallery,
                    icon: const Icon(Icons.photo_library_rounded, size: 16),
                    label: const Text('From Gallery'),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          // Photo Grid
          Expanded(
            child: photos.isEmpty
                ? const EmptyState(
                    icon: Icons.add_photo_alternate_outlined,
                    title: 'No Photos Taken',
                    message: 'Capture or select photos of the bathroom, grout, and tile areas.',
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: photos.length,
                    itemBuilder: (ctx, i) {
                      final p = photos[i];
                      return InkWell(
                        onTap: () => PhotoViewerModal.show(
                          context,
                          p,
                          onDelete: () {
                            if (p.publicId != null) {
                              leadsProv.deletePhoto(widget.leadId, p.publicId!);
                            }
                          },
                        ),
                        borderRadius: BorderRadius.circular(12),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            p.displayUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: AppColors.cardAlt,
                              child: const Icon(Icons.broken_image_rounded, color: AppColors.textMuted),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
