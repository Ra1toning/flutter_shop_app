import 'package:firebase_auth/firebase_auth.dart'
    hide EmailAuthProvider, PhoneAuthProvider;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../provider/globalProvider.dart';
import '../src/authentication.dart';
import '../src/widgets.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Нэвтрэх'),
      ),
      body: Center(
        child: ListView(
          children: <Widget>[
            const SizedBox(height: 8),
            Consumer<Global_provider>(
              builder: (context, appState, _) => AuthFunc(
                  loggedIn: appState.loggedIn,
                  signOut: () {
                    FirebaseAuth.instance.signOut();
                  }),
            ),
          ],
        ),
      ),
    );
  }
}
