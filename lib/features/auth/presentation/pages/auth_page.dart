import 'package:flutter/material.dart';
import 'package:social/features/auth/presentation/pages/login_page.dart';
import 'package:social/features/auth/presentation/pages/register_page.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key, required});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool showLoginPage = true;

  void tooglePages() {
    setState(() {
      showLoginPage = !showLoginPage;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (showLoginPage) {
      return LoginPage(tooglePages: tooglePages);
    } else {
      return RegisterPage(tooglePages: tooglePages);
    }
  }
}
