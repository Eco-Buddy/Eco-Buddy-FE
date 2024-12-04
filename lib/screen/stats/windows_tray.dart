import 'package:tray_manager/tray_manager.dart';
import 'dart:io';

import 'package:window_manager/window_manager.dart';

Future<void> setupWindowsTray() async {
  await trayManager.setIcon(
    Platform.isWindows
        ? 'assets/images/tray/tray_icon.ico'
        : 'assets/images/tray/tray_icon.png', // Ensure these paths are correct
  );

  Menu menu = Menu(
    items: [
      MenuItem(
        key: 'show_window',
        label: 'Show Window',
      ),
      MenuItem.separator(),
      MenuItem(
        key: 'exit_app',
        label: 'Exit App',
      ),
    ],
  );

  await trayManager.setContextMenu(menu);

  trayManager.addListener(TrayManagerListener());
}

class TrayManagerListener extends TrayListener {
  @override
  void onTrayIconMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    if (menuItem.key == 'show_window') {
      windowManager.show();
    } else if (menuItem.key == 'exit_app') {
      trayManager.destroy();
      exit(0);
    }
  }
}
