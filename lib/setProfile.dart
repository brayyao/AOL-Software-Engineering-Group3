// ignore: unused_import
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SetProfilePage extends StatefulWidget {
  @override
  _SetProfilePageState createState() => _SetProfilePageState();
}

class _SetProfilePageState extends State<SetProfilePage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  File? _image;
  bool isPickingImage = false;
  String email = "", password = "", dob = "";

  @override
  void initState() {
    super.initState();
    loadTempData();
  }

  // Fungsi untuk memuat data dari SharedPreferences
  Future<void> loadTempData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      email = prefs.getString('email') ?? "";
      password = prefs.getString('password') ?? "";
      dob = prefs.getString('dob') ?? "";
    });
  }

  // Fungsi untuk memilih gambar dari galeri
  Future<void> pickImage() async {
    if (isPickingImage) return; // Mencegah pemanggilan ganda

    isPickingImage = true;
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    isPickingImage = false;

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  // Fungsi untuk mengirimkan data akhir ke server
  Future<void> submitFinalData() async {
    if (nameController.text.isEmpty ||
        addressController.text.isEmpty ||
        _image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Harap lengkapi semua data")),
      );
      return;
    }

    final uri = Uri.parse("http://10.0.2.2:3000/register");
    final request = http.MultipartRequest('POST', uri)
      ..fields['email'] = email
      ..fields['password'] = password
      ..fields['dob'] = dob
      ..fields['name'] = nameController.text
      ..fields['address'] = addressController.text
      ..files.add(
          await http.MultipartFile.fromPath('profile_image', _image!.path));

    try {
      final response = await request.send();

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear(); // Hapus data setelah berhasil registrasi

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Registrasi berhasil!")),
        );

        // Navigasi ke halaman utama
        // Navigator.pushReplacement(
        //     context, MaterialPageRoute(builder: (context) => HomePage()));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Registrasi gagal! Silakan coba lagi.")),
        );
      }
    } catch (e) {
      print("Error: $e"); // Debugging jika ada error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                "Terjadi kesalahan jaringan atau server tidak merespons.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: Text("Set Profile"), backgroundColor: Colors.pink[200]),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Text("Set Your Profile",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            GestureDetector(
              onTap: pickImage,
              child: CircleAvatar(
                radius: 60,
                backgroundImage: _image != null ? FileImage(_image!) : null,
                child: _image == null ? Icon(Icons.camera_alt, size: 40) : null,
              ),
            ),
            SizedBox(height: 20),
            buildInputField("Name", nameController, false),
            SizedBox(height: 10),
            buildInputField("Address", addressController, false),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: submitFinalData,
              style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.pink[300]),
              child:
                  Text("Save Profile", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

// Fungsi untuk membangun input field
Widget buildInputField(
    String label, TextEditingController controller, bool isPassword) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      SizedBox(height: 5),
      TextField(
        controller: controller,
        obscureText: isPassword,
        decoration: InputDecoration(
          contentPadding: EdgeInsets.all(10),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    ],
  );
}

// Dummy HomePage (Gantilah dengan halaman utama aplikasimu)
class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Home"), backgroundColor: Colors.pink[200]),
      body: Center(
        child: Text("Welcome to Home Page!", style: TextStyle(fontSize: 20)),
      ),
    );
  }
}
