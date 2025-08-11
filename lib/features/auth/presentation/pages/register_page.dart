import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social/features/auth/presentation/components/my_button.dart';
import 'package:social/features/auth/presentation/components/my_text_field.dart';
import 'package:social/features/auth/presentation/cubits/auth_cubit.dart';

class RegisterPage extends StatefulWidget {
  final void Function()? tooglePages;
  const RegisterPage({super.key, required this.tooglePages});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final pwController = TextEditingController();
  final confirmPwController = TextEditingController();

  //register pressed
  void register() {
    final String name = nameController.text;
    final String email = emailController.text;
    final String pw = pwController.text;
    final String confirmPw = confirmPwController.text;

    //auth cubit

    final authCubit = context.read<AuthCubit>();

    //empty kontrol
    if (email.isNotEmpty &&
        name.isNotEmpty &&
        pw.isNotEmpty &&
        confirmPw.isNotEmpty) {
      if (pw == confirmPw) {
        authCubit.register(name, email, pw);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Şifreler aynı değil!")));
      }
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Tüm alanları doldurunuz!")));
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    pwController.dispose();
    confirmPwController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25), //ortaladık
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                //logo
                Icon(
                  Icons.lock_open_rounded,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 50),

                //welcome
                Text(
                  "Hesap Oluşturun!",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 50),
                //email
                MyTextField(
                  controller: nameController,
                  hintText: "name",
                  obscureText: false,
                ),
                SizedBox(height: 10),
                //password
                MyTextField(
                  controller: emailController,
                  hintText: "email",
                  obscureText: false, // ** kullanımı
                ),
                SizedBox(height: 10),
                MyTextField(
                  controller: pwController,
                  hintText: "password",
                  obscureText: true, // ** kullanımı
                ),
                SizedBox(height: 10),
                MyTextField(
                  controller: confirmPwController,
                  hintText: "confirm password",
                  obscureText: true, // ** kullanımı
                ),
                SizedBox(height: 30),

                //register
                MyButton(onTap: register, text: "Kayıt Ol"),
                SizedBox(height: 20),

                //not a member
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Zaten üye misiniz?",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    GestureDetector(
                      onTap: widget.tooglePages,
                      child: Text(
                        "Giriş Yapın",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.inversePrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
