import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class SignInPage extends StatefulWidget {
  @override
  _SignInPageState createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  Future<void> signIn() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      final url = Uri.parse("http://10.0.2.2:3000/login");
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": emailController.text,
          "password": passwordController.text,
        }),
      );

      print("Response status: ${response.statusCode}");
      print("Response body: ${response.body}");

      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200) {
        if (responseData['status'] == 'success') {
          showSnackBar("Sign in berhasil.");
        } else if (responseData['status'] == 'wrong_password') {
          showSnackBar("Password salah! Coba lagi.");
        } else if (responseData['status'] == 'not_found') {
          showSnackBar("Email belum terdaftar! Daftar dulu.");
          Navigator.pushNamed(context, '/signUp-1');
        }
      } else {
        showSnackBar("Terjadi kesalahan, coba lagi nanti.");
      }
    } catch (e) {
      print("Error saat login: $e");
      showSnackBar("Terjadi kesalahan: $e");
    }
  }

  void showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text("Back to Sign Up"), backgroundColor: Colors.pink[200]),
      body: SingleChildScrollView(
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          color: Colors.pink[200],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "ACADEMIA+",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 64,
                  fontFamily: 'Lalezar',
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                "When Passion Meets Innovation",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Image.asset(
                'assets/signUp_pic.png',
                width: 600,
                height: 300,
                fit: BoxFit.cover,
              ),
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(color: Colors.black26, blurRadius: 5),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Text(
                        'Sign In',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF575591),
                          fontSize: 32,
                          fontFamily: 'Lalezar',
                        ),
                      ),
                      buildInputField("Email:", emailController, false),
                      SizedBox(height: 5),
                      buildInputField("Password:", passwordController, true),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/forgotPassword'),
                          child: Text("Forgot Password?",
                              style: TextStyle(color: Colors.pink[200])),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // ElevatedButton(
                          //   onPressed: () {
                          //     // Navigator.pushNamed(context, '/signUp-1');
                          //   },
                          //   style: ElevatedButton.styleFrom(
                          //     backgroundColor: Color(0xFF575591),
                          //     padding: EdgeInsets.symmetric(
                          //         horizontal: 20, vertical: 10),
                          //     shape: RoundedRectangleBorder(
                          //         borderRadius: BorderRadius.circular(30)),
                          //   ),
                          //   child: Text('Sign Up',
                          //       style: TextStyle(color: Colors.white)),
                          // ),
                          ElevatedButton(
                            onPressed: () async {
                              await signIn();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF575591),
                              padding: EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: Text('Next',
                                style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildInputField(
      String label, TextEditingController controller, bool isPassword) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: Colors.black, fontSize: 16, fontFamily: 'Lalezar')),
        SizedBox(height: 5),
        TextFormField(
          controller: controller,
          obscureText: isPassword,
          validator: (value) => value!.isEmpty ? "$label wajib diisi" : null,
          decoration: InputDecoration(
            contentPadding: EdgeInsets.all(10),
            hintText: isPassword ? "Input your password" : "Input your email",
            hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            filled: true,
            fillColor: Colors.white,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(color: Color(0xFFF4658B), width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(color: Colors.purple, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
