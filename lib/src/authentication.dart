import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'widgets.dart';

class AuthFunc extends StatelessWidget {
  const AuthFunc({
    Key? key,
    required this.loggedIn,
    required this.signOut,
  }) : super(key: key);

  final bool loggedIn;
  final void Function() signOut;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: CustomStyledButton(
                onPressed: () {
                  !loggedIn ? context.push('/sign-in') : signOut();
                },
                child: !loggedIn ? const Text('Нэвтрэх') : const Text('Гарах'),
                borderRadius: BorderRadius.circular(5),
                color: Colors.blue,
              ),
            ),
          ),
          Visibility(
            visible: loggedIn,
            child: Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 24, bottom: 8),
                child: CustomStyledButton(
                  onPressed: () {
                    context.push('/profile');
                  },
                  child: const Text('Профайл'),
                  borderRadius: BorderRadius.circular(5),
                  color: Colors.green,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CustomStyledButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final BorderRadius? borderRadius;
  final Color color;

  const CustomStyledButton({
    Key? key,
    required this.onPressed,
    required this.child,
    required this.color,
    this.borderRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      child: DefaultTextStyle(
        style: TextStyle(color: Colors.white),
        child: child,
      ),
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius ?? BorderRadius.circular(0),
        ),
        backgroundColor: color,
      ),
    );
  }
}
