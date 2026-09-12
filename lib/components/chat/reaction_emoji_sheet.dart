import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/config/constants.dart';

Future<String?> showReactionEmojiSheet(BuildContext context) {
  const surface = Color(AppColors.surfaceColor);
  const primary = Color(AppColors.primaryColor);

  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: EmojiPicker(
          onEmojiSelected: (_, emoji) => Navigator.pop(ctx, emoji.emoji),
          config: Config(
            height: 320,
            checkPlatformCompatibility: true,
            emojiViewConfig: EmojiViewConfig(
              backgroundColor: surface,
              emojiSizeMax:
                  28 * (defaultTargetPlatform == TargetPlatform.iOS ? 1.2 : 1),
            ),
            categoryViewConfig: const CategoryViewConfig(
              iconColorSelected: primary,
              indicatorColor: primary,
              backgroundColor: surface,
            ),
            bottomActionBarConfig: const BottomActionBarConfig(
              showBackspaceButton: false,
              backgroundColor: surface,
              buttonColor: primary,
              buttonIconColor: Colors.white,
            ),
            searchViewConfig: const SearchViewConfig(backgroundColor: surface),
            skinToneConfig: const SkinToneConfig(),
          ),
        ),
      );
    },
  );
}
