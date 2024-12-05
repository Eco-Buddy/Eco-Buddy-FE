import 'package:tray_manager/tray_manager.dart';
import 'dart:io';

import 'package:window_manager/window_manager.dart';
import 'package:windows_notification/notification_message.dart';
import 'package:windows_notification/windows_notification.dart';

final _winNotifyPlugin = WindowsNotification(
  applicationId: "Eco_Buddy",
);

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

  sendStartupNotification();
}

void sendStartupNotification() async {
  NotificationMessage message = NotificationMessage.fromPluginTemplate(
    "앱이 실행 중 입니다.",
    "귀하의 앱이 시스템 트레이로 최소화되었습니다.",
    "트레이 아이콘을 클릭하세요.",
  );
  _winNotifyPlugin.showNotificationPluginTemplate(message);
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
