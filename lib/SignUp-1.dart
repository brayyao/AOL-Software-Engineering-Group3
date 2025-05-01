import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'SignIn-1.dart'; // Pastikan nama file sesuai
import 'setProfile.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(MaterialApp(
      home: Home(),
      routes: {
        '/SignIn-1': (context) => SignInPage(),
        '/setProfile.dart': (context) => SetProfilePage(),
      },
    ));

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  DateTime? selectedDate;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  void initState() {
    super.initState();
    loadTempData();
  }

  Future<void> saveTempData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('email', emailController.text);
    await prefs.setString('password', passwordController.text);
    await prefs.setString(
        'dob',
        selectedDate != null
            ? DateFormat("yyyy-MM-dd").format(selectedDate!)
            : "");
  }

  Future<void> loadTempData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      emailController.text = prefs.getString('email') ?? "";
      passwordController.text = prefs.getString('password') ?? "";
      String? dobString = prefs.getString('dob');
      if (dobString != null && dobString.isNotEmpty) {
        selectedDate = DateTime.parse(dobString);
      }
    });
  }

  Future<void> proceedToNextStep() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Semua field harus diisi!")),
      );
      return;
    }
    await saveTempData();
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => SetProfilePage()));
  }

  Future<void> submitData() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Semua field harus diisi!")),
      );
      return;
    }

    try {
      final url = Uri.parse("http://10.0.2.2:3000/register");
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": emailController.text,
          "password": passwordController.text,
          "dob": selectedDate != null
              ? DateFormat("yyyy-MM-dd").format(selectedDate!)
              : null,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Registrasi berhasil!")),
        );
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SetProfilePage()),
        );
      } else {
        final responseData = jsonDecode(response.body);
        if (responseData['status'] == 'email_exists') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text("Email sudah digunakan! Silakan pakai email lain.")),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Registrasi gagal! Silakan coba lagi.")),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Terjadi kesalahan: $e")),
      );
    }
  }

  void resetForm() {
    setState(() {
      emailController.clear();
      passwordController.clear();
      selectedDate = null; // Reset DOB ke default
    });
  }

  void navigateToSignIn() {
    resetForm();
    Navigator.pushNamed(context, '/SignIn-1');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.pink[200]),
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
                  height: 1.0,
                ),
              ),
              Text(
                "When Passion Meets Innovation",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: "Lucida_Calligraphy",
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
                child: Column(
                  children: [
                    Text(
                      'Sign Up',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF575591),
                        fontSize: 32,
                        fontFamily: 'Lalezar',
                      ),
                    ),
                    buildInputField("Email:", emailController, false),
                    SizedBox(height: 5),
                    buildDOBField(),
                    SizedBox(height: 5),
                    buildInputField("Password:", passwordController, true),
                    SizedBox(height: 1.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton(
                          onPressed: navigateToSignIn,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFF4658B),
                            padding: EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30)),
                          ),
                          child: Text('Sign In',
                              style: TextStyle(color: Colors.white)),
                        ),
                        ElevatedButton(
                          onPressed: submitData,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF575591),
                            padding: EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30)),
                          ),
                          child: Text('Next',
                              style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ],
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

  Widget buildDOBField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Date of Birth:',
            style: TextStyle(
                color: Colors.black, fontSize: 16, fontFamily: 'Lalezar')),
        SizedBox(height: 5),
        SizedBox(
          width: 400,
        ),
        GestureDetector(
          onTap: () async {
            DateTime? pickedDate = await showDatePicker(
              context: context,
              initialDate: selectedDate,
              firstDate: DateTime(1900),
              lastDate: DateTime(2026),
            );

            if (pickedDate != null && pickedDate != selectedDate) {
              setState(() {
                selectedDate = pickedDate;
              });
            }
          },
          child: Container(
            width: 400,
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(color: Color(0xFFF4658B), width: 2),
              borderRadius: BorderRadius.circular(30),
              color: Colors.white,
            ),
            child: Text(
              selectedDate != null
                  ? DateFormat("dd/MM/yyyy").format(selectedDate!)
                  : "Pilih Tanggal Lahir", // 🔥 Jika null, tampilkan placeholder
              textAlign: TextAlign.left,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: selectedDate != null ? Colors.black : Colors.grey,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
