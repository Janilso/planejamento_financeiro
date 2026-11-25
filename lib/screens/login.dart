import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:planejamento_financeiro/commons/icons.dart';
import 'package:planejamento_financeiro/commons/images.dart';
import 'package:planejamento_financeiro/screens/home.dart';
import 'package:planejamento_financeiro/theme/colors.dart';
import 'package:planejamento_financeiro/widgets/button.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool loading = false;

  Future<void> _loginWithGoogle() async {
    try {
      setState(() {
        loading = true;
      });
      final GoogleSignInAccount googleUser = await GoogleSignIn.instance
          .authenticate();
      // await GoogleSignIn.instance.signOut();

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);

      if (!mounted) return;
      if (userCredential.user?.email != null) {
        Navigator.pushReplacement(
          context,
          CupertinoPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (error) {
      if (error is GoogleSignInException &&
          error.code == GoogleSignInExceptionCode.canceled) {
        return;
      }
      // TODO: implement error feedback
      print("====>>>>>>>>>>>>>>>Errorrr $error");
      // await FirebaseAuth.instance.signOut();
      // ;
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //     content: Text('Erro ao fazer login: $error'),
      //     backgroundColor: AppColors.secondary,
      //   ),
      // );
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: ListView(
          shrinkWrap: true,
          children: [
            AppImage.logoWhite(width: 168, height: 117),
            const SizedBox(height: 12),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: 64, left: 44, right: 44),
        child: AppButton(
          text: 'ENTRAR / CADASTRAR',
          icon: AppIcons.google,
          loading: loading,
          onPressed: _loginWithGoogle,
        ),
      ),
    );
  }
}
