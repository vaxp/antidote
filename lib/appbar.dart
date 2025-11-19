import 'package:antidote/macbutton.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

class Appbar extends StatelessWidget implements PreferredSizeWidget {
  const Appbar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onPanStart: (_) async {
        await windowManager.startDragging();
      },
      child: Container(
        height: 40,
        alignment: Alignment.centerRight,
          color: Color.fromARGB(156, 0, 0, 0),
         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 20.0),
              child: Text(
                'Settings',
                style: TextStyle(
                  fontSize:16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const Spacer(),
            MacButton(
              color: Colors.red,
              onPressed: () => windowManager.close(),
            ),
            const SizedBox(width: 4),
            MacButton(
              color: Colors.yellow,
              onPressed: () => windowManager.minimize(),
            ),
            const SizedBox(width: 4),
            HoverMacButton(
              color: Colors.green,
              onPressed: () async {
                bool maximized = await windowManager.isMaximized();
                if (maximized) {
                  windowManager.unmaximize();
                } else {
                  windowManager.maximize();
                }
              },
            ),
   
          ],
        ),
      ),
    );
  }
}
