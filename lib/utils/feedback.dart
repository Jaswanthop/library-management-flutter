import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Floating feedback message used after every action.
void showToast(
  BuildContext context,
  String message, {
  bool error = false,
  IconData? icon,
}) {
  final AppColors colors = context.colors;
  final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 3),
        content: Row(
          children: <Widget>[
            Icon(
              icon ??
                  (error
                      ? Icons.error_outline_rounded
                      : Icons.check_circle_outline_rounded),
              size: 18,
              color: error ? colors.danger : colors.success,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
}
