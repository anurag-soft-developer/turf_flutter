import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/create_turf_controller.dart';
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
              _buildImageUrlInput(controller),
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

  Widget _buildImageUrlInput(CreateTurfController controller) {
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
