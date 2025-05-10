import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/material.dart';

import 'package:wildfocus/customs/customcolors.dart';

import 'forgotpassword.dart';

import 'home.dart';

import 'signup.dart';



class LoginPage extends StatefulWidget {

  const LoginPage({super.key});



  @override

  _LoginPageState createState() => _LoginPageState();

}



class _LoginPageState extends State<LoginPage> {

  final formKey = GlobalKey<FormState>();

  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;



  String? email;

  String? password;



  @override

  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: CustomColors.background,

      body: SafeArea(

        child: Column(

          children: [

            Expanded(

              child: Center(

                child: SingleChildScrollView(

                  padding: const EdgeInsets.symmetric(horizontal: 32),

                  child: Form(

                    key: formKey,

                    child: Column(

                      mainAxisAlignment: MainAxisAlignment.center,

                      children: [

                        // Hoşgeldiniz yazısı buraya taşındı

                        Row(

                          mainAxisAlignment: MainAxisAlignment.center,

                          children: const [

                            Text(

                              'Hoşgeldiniz',

                              style: TextStyle(

                                fontSize: 28,

                                fontWeight: FontWeight.bold,

                                color:  CustomColors.primaryText,

                              ),

                            ),

                            SizedBox(width: 8),

                            Icon(

                              Icons.eco,

                              size: 32,

                              color:  CustomColors.primaryText,

                            ),

                          ],

                        ),

                        const SizedBox(height: 40),

                        buildTextFormField(

                          hintText: 'Email',

                          icon: Icons.person,

                          onSaved: (value) => email = value,

                          validator: (value) =>

                              value!.isEmpty ? 'Email boş olamaz.' : null,

                        ),

                        const SizedBox(height: 20),

                        buildTextFormField(

                          hintText: 'Şifre',

                          icon: Icons.lock,

                          obscureText: true,

                          onSaved: (value) => password = value,

                          validator: (value) =>

                              value!.isEmpty ? 'Şifre boş olamaz.' : null,

                        ),

                        const SizedBox(height: 10),

                        Align(

                          alignment: Alignment.centerRight,

                          child: TextButton(

                            onPressed: () => Navigator.push(

                              context,

                              MaterialPageRoute(

                                builder: (context) => const ForgotPassword(),

                              ),

                            ),

                            child: const Text(

                              'Şifremi Unuttum',

                              style: TextStyle(

                                decoration: TextDecoration.underline,

                                fontWeight: FontWeight.bold,

                                color:  CustomColors.primaryText,

                              ),

                            ),

                          ),

                        ),

                      ],

                    ),

                  ),

                ),

              ),

            ),

            Padding(

              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),

              child: Column(

                children: [

                  loginButton(context),

                  const SizedBox(height: 16),

                  Row(

                    mainAxisAlignment: MainAxisAlignment.center,

                    children: [

                      const Text("Hesabın yok mu? "),

                      GestureDetector(

                        onTap: () => Navigator.push(

                          context,

                          MaterialPageRoute(

                            builder: (context) => const SignupPage(),

                          ),

                        ),

                        child: const Text(

                          "Hesap Oluştur",

                          style: TextStyle(

                            decoration: TextDecoration.underline,

                            fontWeight: FontWeight.bold,

                            color: CustomColors.primaryText,

                          ),

                        ),

                      ),

                    ],

                  ),

                ],

              ),

            ),

          ],

        ),

      ),

    );

  }



  Widget buildTextFormField({

    required String hintText,

    required IconData icon,

    required FormFieldSetter<String> onSaved,

    required FormFieldValidator<String> validator,

    bool obscureText = false,

  }) {

    return SizedBox(

      width: double.infinity,

      child: TextFormField(

        validator: validator,

        onSaved: onSaved,

        obscureText: obscureText,

        decoration: InputDecoration(

          prefixIcon: Icon(icon, color:  CustomColors.primaryText),

          hintText: hintText,

          filled: true,

          fillColor:  CustomColors.textfieldFill,

          contentPadding: const EdgeInsets.symmetric(vertical: 18),

          border: OutlineInputBorder(

            borderRadius: BorderRadius.circular(16),

            borderSide: BorderSide.none,

          ),

        ),

      ),

    );

  }



  Widget loginButton(BuildContext context) {

    return SizedBox(

      width: double.infinity,

      child: ElevatedButton(

        onPressed: () => login(context),

        style: ElevatedButton.styleFrom(

          backgroundColor: CustomColors.button,

          shape: RoundedRectangleBorder(

            borderRadius: BorderRadius.circular(30),

          ),

          padding: const EdgeInsets.symmetric(vertical: 16),

        ),

        child: const Text(

          'Giriş Yap',

          style: TextStyle(fontSize: 18, color: CustomColors.buttontext),

        ),

      ),

    );

  }



  void showSnackBar(BuildContext context, String message, IconData icon) {

    ScaffoldMessenger.of(context).showSnackBar(

      SnackBar(

        content: Row(

          children: [

            Icon(icon, color: Colors.white),

            const SizedBox(width: 8),

            Text(message),

          ],

        ),

        backgroundColor: CustomColors.error,

      ),

    );

  }



  Future<void> login(BuildContext context) async {

    if (formKey.currentState!.validate()) {

      formKey.currentState!.save();

      try {

        await firebaseAuth.signInWithEmailAndPassword(

          email: email!,

          password: password!,

        );

        Navigator.pushReplacement(

          context,

          MaterialPageRoute(builder: (context) => HomeScreen()),

        );

      } catch (e) {

        showSnackBar(context, 'Giriş bilgileri hatalı.', Icons.close);

      }

    } else {

      showSnackBar(context, 'Lütfen bilgileri eksiksiz doldurun.', Icons.error);

    }

  }

}










