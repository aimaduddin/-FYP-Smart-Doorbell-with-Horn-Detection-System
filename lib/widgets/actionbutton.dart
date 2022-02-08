import 'package:flutter/material.dart';
import 'package:smart_doorbell_with_horn_detection/utils/const.dart';

class ActionButton extends StatelessWidget {
  final IconData icon;
  final String textInButton;
  final VoidCallback callback;
  final Color borderColor;

  const ActionButton({
    Key? key,
    required this.icon,
    required this.textInButton,
    required this.callback,
    this.borderColor = primaryColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      width: 150,
      child: OutlinedButton(
        onPressed: callback,
        style: OutlinedButton.styleFrom(
          side: BorderSide(
              width: 1.0,
              // ignore: unnecessary_null_comparison
              color: borderColor != null ? borderColor : primaryColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(textInButton),
            SizedBox(
              width: 5,
            ),
            Icon(
              icon,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
