import 'package:flutter_application_1/chat/chat_service.dart';
import 'package:flutter_application_1/chat/model/chat_models.dart';
import 'package:flutter_application_1/chat/utils/chat_inbox_cache.dart';
import 'package:flutter_application_1/chat/utils/chat_navigation.dart';
import 'package:flutter_application_1/core/utils/app_snackbar.dart';
import 'package:get/get.dart';

class ChatInboxController extends GetxController {
  final ChatService _service = ChatService();

  final RxBool isSelecting = false.obs;
  final selectedKeys = <String>{}.obs;
  final RxBool isHiding = false.obs;
  final _hidingKeys = <String>{};

  bool allSelected(List<ChatInboxItem> items) =>
      items.isNotEmpty && selectedKeys.length == items.length;

  void exitSelection() {
    isSelecting.value = false;
    selectedKeys.clear();
  }

  void enterSelection(String roomKey) {
    isSelecting.value = true;
    selectedKeys
      ..clear()
      ..add(roomKey);
  }

  void toggleSelected(String roomKey) {
    if (selectedKeys.contains(roomKey)) {
      selectedKeys.remove(roomKey);
    } else {
      selectedKeys.add(roomKey);
    }
  }

  void toggleSelectAll(List<ChatInboxItem> items) {
    if (allSelected(items)) {
      selectedKeys.clear();
    } else {
      selectedKeys.assignAll(items.map((e) => e.roomKey));
      isSelecting.value = true;
    }
  }

  void onLongPress(ChatInboxItem item) {
    if (isSelecting.value) {
      toggleSelected(item.roomKey);
    } else {
      enterSelection(item.roomKey);
    }
  }

  void onTap(ChatInboxItem item) {
    if (isSelecting.value) {
      toggleSelected(item.roomKey);
      return;
    }
    ChatNavigation.openThread(
      scope: item.scope,
      scopeId: item.scopeId,
      title: item.title,
      imageUrl: item.imageUrl,
    );
  }

  Future<void> hideSelected(List<ChatInboxItem> items) async {
    final keys = selectedKeys.toSet();
    final toHide = items.where((item) => keys.contains(item.roomKey)).toList();
    await hideThreads(toHide);
  }

  Future<bool> hideThreads(List<ChatInboxItem> items) async {
    final toHide = items
        .where((item) => !_hidingKeys.contains(item.roomKey))
        .toList();
    if (toHide.isEmpty) return false;

    final keys = toHide.map((item) => item.roomKey).toSet();
    _hidingKeys.addAll(keys);
    isHiding.value = true;
    ChatInboxCache.removeKeys(keys);
    selectedKeys.removeAll(keys);
    if (selectedKeys.isEmpty) {
      isSelecting.value = false;
    }

    try {
      final ok = await _service.hideThreads(toHide);
      if (!ok) {
        await ChatInboxCache.invalidate();
        AppSnackbar.error(
          title: 'Chat',
          message: toHide.length == 1
              ? 'Could not delete this conversation.'
              : 'Could not delete some conversations.',
        );
        return false;
      }
      if (toHide.length > 1) {
        AppSnackbar.success(
          title: 'Chat',
          message: 'Deleted ${toHide.length} conversations.',
        );
      }
      return true;
    } finally {
      _hidingKeys.removeAll(keys);
      isHiding.value = _hidingKeys.isNotEmpty;
    }
  }
}
