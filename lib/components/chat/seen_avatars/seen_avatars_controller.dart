import 'dart:async';

import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:get/get.dart';

class SeenAvatarUser {
  const SeenAvatarUser({
    required this.id,
    required this.name,
    this.imageUrl,
  });

  final String id;
  final String name;
  final String? imageUrl;
}

class SeenAvatarsController extends GetxController {
  SeenAvatarsController({
    required this.userIds,
    required this.resolveUser,
  });

  final List<String> userIds;
  final Future<User?> Function(String id) resolveUser;

  final users = <SeenAvatarUser>[].obs;

  @override
  void onInit() {
    super.onInit();
    users.assignAll([
      for (final id in userIds) SeenAvatarUser(id: id, name: ''),
    ]);
    unawaited(_load());
  }

  Future<void> _load() async {
    final loaded = <SeenAvatarUser>[];
    for (final id in userIds) {
      final user = await resolveUser(id);
      loaded.add(
        SeenAvatarUser(
          id: id,
          name: user?.name ?? 'Player',
          imageUrl: user?.imageSource,
        ),
      );
    }
    users.assignAll(loaded);
  }
}
