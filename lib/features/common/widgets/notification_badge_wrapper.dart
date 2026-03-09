import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/services/notification_service.dart';
import '../../../data/services/auth_service.dart';
import '../../notification/notification_screen.dart';

class NotificationBadgeWrapper extends StatelessWidget {
  final Widget child;

  const NotificationBadgeWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.user;

    if (user == null) {
      return IconButton(
        icon: child,
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => NotificationScreen()));
        },
      );
    }

    return StreamBuilder<int>(
      stream: Provider.of<NotificationService>(context).getUnreadCount(user.uid),
      builder: (context, snapshot) {
        int unreadCount = 0;
        if (snapshot.hasData) {
          unreadCount = snapshot.data!;
        }

        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: child,
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => NotificationScreen()));
              },
            ),
            if (unreadCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.5),
                        blurRadius: 4,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                  constraints: BoxConstraints(
                    minWidth: 12,
                    minHeight: 12,
                  ),
                  child: Text(
                    unreadCount > 9 ? '9+' : '$unreadCount',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
