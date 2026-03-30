import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../turf/create/create_turf_controller.dart';
import 'section_container.dart';
import 'styled_text_field.dart';

class ImagesSection extends StatelessWidget {
  const ImagesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = CreateTurfController.instance;

    return SectionContainer(
      title: 'Images',
      icon: Icons.image,
      children: [
        Obx(() {
          return Column(
            children: [
              if (controller.imageUrls.isNotEmpty) ...[
                _buildImagePreviewGrid(controller),
                const SizedBox(height: 16),
              ],
              _buildImageAddButtons(controller),
              if (controller.imageUrls.isEmpty) _buildImageRequiredWarning(),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildImagePreviewGrid(CreateTurfController controller) {
    return Container(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: controller.imageUrls.length,
        itemBuilder: (context, index) {
          return Container(
            width: 100,
            margin: const EdgeInsets.only(right: 8),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    controller.imageUrls[index],
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 100,
                        height: 100,
                        color: Colors.grey[300],
                        child: const Icon(Icons.error),
                      );
                    },
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () =>
                        controller.removeImageUrl(controller.imageUrls[index]),
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

  Widget _buildImageAddButtons(CreateTurfController controller) {
    return Column(
      children: [
        // Primary Add Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: controller.showImagePickerOptions,
            icon: const Icon(Icons.add_photo_alternate),
            label: const Text('Add Images'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Quick Access Buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: controller.pickImageFromCamera,
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
                onPressed: controller.pickImageFromGallery,
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

  Widget _buildImageUrlInputLegacy(CreateTurfController controller) {
    final textController = TextEditingController();

    return Row(
      children: [
        Expanded(
          child: TurfFormField(
            controller: textController,
            labelText: 'Image URL',
            hintText: 'Paste image URL and press Enter',
            suffixIcon: Icons.add_photo_alternate,
            onFieldSubmitted: (value) {
              debugPrint('Submitted image URL: $value');
              if (value.trim().isNotEmpty) {
                controller.addImageUrl(value.trim());
                // Clear the input field after adding
                textController.clear();
              }
            },
          ),
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
