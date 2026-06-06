import 'package:flutter/cupertino.dart';

class ErrorDialog extends StatelessWidget {
  final String message;
  final String buttonLabel;
  final VoidCallback? onButtonPressed;

  const ErrorDialog({
    super.key,
    required this.message,
    this.buttonLabel = 'OK',
    this.onButtonPressed,
  });

  static void show(
    BuildContext context, {
    required String message,
    String buttonLabel = 'OK',
    VoidCallback? onButtonPressed,
  }) {
    showCupertinoDialog(
      context: context,
      builder: (context) => ErrorDialog(
        message: message,
        buttonLabel: buttonLabel,
        onButtonPressed: onButtonPressed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: const Text('Error'),
      content: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(message),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () {
            Navigator.of(context).pop();
            onButtonPressed?.call();
          },
          child: Text(buttonLabel),
        ),
      ],
    );
  }
}
