import 'package:get/get.dart';

class MainViewModel extends GetxController {
  int _selectedIndex = 1; // Start on Home tab
  int get selectedIndex => _selectedIndex;

  void onItemTapped(int index) {
    _selectedIndex = index;
    update();
  }
}
