import 'package:caraxes_app/pages/auth/login_page.dart';
import 'package:caraxes_app/pages/auth/role_selection_page.dart';
import 'package:caraxes_app/pages/rescuer/rescuer_home_page.dart';
import 'package:caraxes_app/pages/victim/victim_home_page.dart';
import 'package:caraxes_app/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class GatewayPage extends StatelessWidget {
  const GatewayPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          final user = snapshot.data!;
          return FutureBuilder<String?>(
            future: AuthService().getUserRole(user.uid),
            builder: (context, roleSnapshot) {
              if (roleSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              final role = roleSnapshot.data;

              if (role == 'victim') {
                return const VictimHomePage();
              } else if (role == 'rescuer') {
                return const RescuerHomePage();
              } else {
                return const RoleSelectionPage();
              }
            },
          );
        }

        return const LoginPage();
      },
    );
  }
}
