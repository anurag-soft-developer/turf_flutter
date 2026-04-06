import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../create_turf/section_container.dart';

class ImageInput extends StatelessWidget {
  final String title;
  final IconData icon;
  final RxList<String> imageUrls;
  final VoidCallback onShowOptions;
  final VoidCallback onPickCamera;
  final VoidCallback onPickGallery;
  final void Function(String) onRemove;
  final bool requireAtLeastOne;
  final int? maxImages;

  const ImageInput({
    super.key,
    this.title = 'Images',
    this.icon = Icons.image,
    required this.imageUrls,
    required this.onShowOptions,
    required this.onPickCamera,
    required this.onPickGallery,
    required this.onRemove,
    this.requireAtLeastOne = false,
    this.maxImages,
  });

  @override
  Widget build(BuildContext context) {
    return SectionContainer(
      title: title,
      icon: icon,
      children: [
        Obx(() {
          final bool canAddMore =
              maxImages == null || imageUrls.length < maxImages!;
          return Column(
            children: [
              if (imageUrls.isNotEmpty) ...[
                _buildImagePreviewGrid(),
                const SizedBox(height: 16),
              ],
              if (canAddMore) _buildImageAddButtons(),
              if (requireAtLeastOne && imageUrls.isEmpty)
                _buildImageRequiredWarning(),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildImagePreviewGrid() {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: imageUrls.length,
        itemBuilder: (context, index) {
          final url = imageUrls[index];
          return Container(
            width: 100,
            margin: const EdgeInsets.only(right: 8),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    url,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 100,
                        height: 100,
                        color: Colors.grey[300],
                        child: const Icon(Icons.broken_image),
                      );
                    },
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () => onRemove(url),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildImageAddButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onShowOptions,
            icon: const Icon(Icons.add_photo_alternate),
            label: Text(
              maxImages == 1 ? 'Set Image' : 'Add Images',
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onPickCamera,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Camera'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onPickGallery,
                icon: const Icon(Icons.photo_library),
                label: const Text('Gallery'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildImageRequiredWarning() {
    return const Padding(
      padding: EdgeInsets.only(top: 8),
      child: Text(
        'Please add at least one image',
        style: TextStyle(color: Colors.red, fontSize: 12),
      ),
    );
  }
}
