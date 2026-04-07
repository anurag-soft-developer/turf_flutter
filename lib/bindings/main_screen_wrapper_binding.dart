import 'package:get/get.dart';
import '../core/components/bottom_navigation_panel/navigation_controller.dart';

class NavigationBinding extends Bindings {
  @override
  void dependencies() {
    // Only load the navigation controller
    // Individual screen controllers will be loaded dynamically
    Get.put<NavigationController>(NavigationController(), permanent: true);
  }
}
