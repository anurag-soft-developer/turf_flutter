import 'package:get/get.dart';

/// UI helpers for Matches. List fetching is owned by flutter_query.
class MatchesController extends GetxController {
  final RxString searchQuery = ''.obs;

  void setSearchQuery(String value) {
    searchQuery.value = value.trim();
  }
}
