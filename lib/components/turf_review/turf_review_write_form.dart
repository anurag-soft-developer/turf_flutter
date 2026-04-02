import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/config/constants.dart';
import '../../turf/model/turf_review_model.dart';
import '../../turf/reviews/turf_review_service.dart';
import '../../turf/reviews/turf_reviews_list_controller.dart';

class TurfReviewWriteForm extends StatefulWidget {
  const TurfReviewWriteForm({super.key, required this.turfId});

  final String turfId;

  @override
  State<TurfReviewWriteForm> createState() => _TurfReviewWriteFormState();
}

class _TurfReviewWriteFormState extends State<TurfReviewWriteForm> {
  final TurfReviewService _service = TurfReviewService();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();

  int _rating = 0;
  bool _submitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating < 1) {
      Get.snackbar('Rating required', 'Please select a star rating');
      return;
    }
    setState(() => _submitting = true);
    var closedWithSuccess = false;
    try {
      final title = _titleController.text.trim();
      final comment = _commentController.text.trim();
      final req = CreateTurfReviewRequest(
        turf: widget.turfId,
        rating: _rating,
        title: title.isEmpty ? null : title,
        comment: comment.isEmpty ? null : comment,
      );
      final created = await _service.createReview(req);
      if (!mounted) return;
      if (created != null) {
        reloadTurfReviewListsIfRegistered(widget.turfId);
        Get.snackbar('Thank you', 'Your review was posted');
        closedWithSuccess = true;
        Navigator.of(context).pop();
        return;
      }
      Get.snackbar('Error', 'Could not post review');
    } catch (e) {
      if (mounted) Get.snackbar('Error', e.toString());
    } finally {
      if (!closedWithSuccess && mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Material(
      color: const Color(AppColors.surfaceColor),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(AppColors.dividerColor),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text(
              'Write a review',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(AppColors.textColor),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Rating',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(AppColors.textSecondaryColor),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final star = i + 1;
                final selected = _rating >= star;
                return IconButton(
                  onPressed: _submitting
                      ? null
                      : () => setState(() => _rating = star),
                  icon: Icon(
                    selected ? Icons.star : Icons.star_border,
                    size: 36,
                    color: selected
                        ? const Color(0xFFFBBF24)
                        : const Color(0xFFD1D5DB),
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Title (optional)',
                hintText: 'Short summary',
                fillColor: Color(AppColors.surfaceColor),
              ),
              style: const TextStyle(color: Color(AppColors.textColor)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _commentController,
              minLines: 3,
              maxLines: 6,
              textCapitalization: TextCapitalization.sentences,
              style: const TextStyle(color: Color(AppColors.textColor)),
              decoration: const InputDecoration(
                alignLabelWithHint: true,
                labelText: 'Your experience',
                hintText: 'What did you like?',
                fillColor: Color(AppColors.surfaceColor),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Submit review'),
            ),
          ],
        ),
      ),
    );
  }
}
