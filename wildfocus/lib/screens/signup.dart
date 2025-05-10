import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wildfocus/screens/home.dart';
import 'login.dart';
import 'package:wildfocus/customs/customcolors.dart';
import 'package:google_sign_in/google_sign_in.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final formKey = GlobalKey<FormState>();
  late String email, password, userName, passwordControl;
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;

  final firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn googleSignIn = GoogleSignIn();

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: CustomColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: SizedBox(
            height: height - MediaQuery.of(context).padding.top,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(height: 40),
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text(
                            'Kayıt Ol',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: CustomColors.primaryText,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(
                            Icons.eco,
                            size: 32,
                            color: CustomColors.iconColor,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Yeni hesap oluştur',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                  Form(
                    key: formKey,
                    child: Column(
                      children: [
                        buildInputField(
                          'Full Name',
                          Icons.person,
                          (val) => userName = val!,
                        ),
                        const SizedBox(height: 15),
                        buildInputField(
                          'Email',
                          Icons.email,
                          (val) => email = val!,
                        ),
                        const SizedBox(height: 15),
                        buildPasswordField('Password', Icons.lock, true),
                        const SizedBox(height: 15),
                        buildPasswordField(
                          'Confirm Password',
                          Icons.lock_outline,
                          false,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      const SizedBox(height: 5),
                      ElevatedButton(
                        onPressed: signUp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: CustomColors.button,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 100,
                            vertical: 15,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          'Kayıt Ol',
                          style: TextStyle(color: CustomColors.buttontext),
                        ),
                      ),
                      const SizedBox(height: 30),
                      GestureDetector(
                        onTap: () {
                          signInWithGoogle();
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'images/google.png',
                              height: 45,
                              width: 45,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "Google ile devam et ",
                        style: TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Hesabın var mı? ",
                            style: TextStyle(color: Colors.black),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const LoginPage()),
                            ),
                            child: const Text(
                              "Giriş yap",
                              style: TextStyle(
                                decoration: TextDecoration.underline,
                                fontWeight: FontWeight.bold,
                                color: CustomColors.primaryText,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildInputField(
    String hint,
    IconData icon,
    Function(String?) onSaved,
  ) {
    return TextFormField(
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: CustomColors.primaryText),
        filled: true,
        fillColor: CustomColors.textfieldFill,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
      ),
      onSaved: onSaved,
      validator: (val) => val!.isEmpty ? 'Please enter $hint' : null,
    );
  }

  Widget buildPasswordField(String hint, IconData icon, bool isMain) {
    return TextFormField(
      obscureText: isMain ? obscurePassword : obscureConfirmPassword,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: CustomColors.primaryText),
        filled: true,
        fillColor: CustomColors.textfieldFill,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
        suffixIcon: IconButton(
          icon: Icon(
            (isMain ? obscurePassword : obscureConfirmPassword)
                ? Icons.visibility
                : Icons.visibility_off,
            color: Colors.black,
          ),
          onPressed: () {
            setState(() {
              if (isMain) {
                obscurePassword = !obscurePassword;
              } else {
                obscureConfirmPassword = !obscureConfirmPassword;
              }
            });
          },
        ),
      ),
      onSaved: (val) {
        if (isMain) {
          password = val!;
        } else {
          passwordControl = val!;
        }
      },
      validator: (val) => val!.isEmpty ? 'Please enter $hint' : null,
    );
  }

  void signUp() async {
    if (formKey.currentState!.validate()) {
      formKey.currentState!.save();
      if (password != passwordControl) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Passwords do not match'),
            backgroundColor: CustomColors.error,
          ),
        );
        return;
      }

      try {
        await firebaseAuth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration error: ${e.toString()}'),
            backgroundColor: CustomColors.error,
          ),
        );
      }
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      // Oturumu kapat, her girişte kullanıcıyı tekrar sor
      await googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        // Kullanıcı iptal etti
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await firebaseAuth.signInWithCredential(credential);

      if (userCredential.user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) =>  HomeScreen()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Google sign-in error: ${e.toString()}'),
          backgroundColor: CustomColors.error,
        ),
      );
    }
  }
}
