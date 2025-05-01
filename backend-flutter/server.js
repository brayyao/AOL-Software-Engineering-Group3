const express = require("express");
const mysql = require("mysql");
const mongoose = require("mongoose");
const multer = require("multer");
const path = require("path");
const { v4: uuidv4 } = require("uuid");
const bodyParser = require("body-parser");
const cors = require("cors");
const bcrypt = require("bcrypt");
const fs = require("fs");

const app = express();
const port = 3000;

app.use(cors());
app.use(bodyParser.json());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Koneksi ke MySQL dengan Pool
const db = mysql.createPool({
  connectionLimit: 10,
  host: "localhost",
  user: "root",
  password: "",
  database: "academiaplus",
});

// Koneksi ke MongoDB
mongoose
  .connect("mongodb://localhost:27017/academia_plus", {
    useNewUrlParser: true,
    useUnifiedTopology: true,
  })
  .then(() => console.log("MongoDB Connected"))
  .catch((err) => console.error("MongoDB Connection Failed:", err));

const profileSchema = new mongoose.Schema({
  studentID: String,
  name: String,
  address: String,
  profileImage: String,
});

const Profile = mongoose.model("Profile", profileSchema);

// Konfigurasi Multer untuk upload gambar
const storage = multer.diskStorage({
  destination: "uploads/",
  filename: (req, file, cb) => {
    const uniqueName = uuidv4() + path.extname(file.originalname);
    cb(null, uniqueName);
  },
});

const upload = multer({ storage });

// **Endpoint untuk registrasi user**
app.post("/register", async (req, res) => {
  const { email, password, dob } = req.body;

  if (!email || !password || !dob) {
    return res.status(400).json({ error: "Semua field harus diisi" });
  }

  const checkEmailSQL =
    "SELECT COUNT(*) AS count FROM student WHERE StudentEmail = ?";
  db.query(checkEmailSQL, [email], async (err, results) => {
    if (err) {
      console.error("Error saat mengecek email:", err);
      return res.status(500).json({ error: "Terjadi kesalahan pada server" });
    }

    if (results[0].count > 0) {
      return res
        .status(400)
        .json({ status: "email_exists", message: "Email sudah digunakan!" });
    }

    const hashedPassword = await bcrypt.hash(password, 10);
    const studentID = uuidv4();

    const insertSQL = `
      INSERT INTO student 
      (StudentID, StudentName, StudentAddress, StudentPFP, StudentEmail, StudentDOB, StudentPassword) 
      VALUES (?, ?, ?, ?, ?, ?, ?)
    `;

    db.query(
      insertSQL,
      [studentID, "", "", "", email, dob, hashedPassword],
      (err) => {
        if (err) {
          console.error("Gagal menambahkan data:", err);
          return res.status(500).json({ error: "Gagal menambahkan data" });
        }
        res.json({
          status: "success",
          message: "Registrasi berhasil",
          id: studentID,
        });
      }
    );
  });
});

// **Endpoint Set Profile (MongoDB + MySQL)**
app.post("/setProfile", upload.single("profile_image"), async (req, res) => {
  try {
    const { studentID, name, address } = req.body;

    if (!studentID || !name || !address || !req.file) {
      return res.status(400).json({ error: "Semua field harus diisi!" });
    }

    // Periksa apakah studentID ada di MySQL
    db.query(
      "SELECT * FROM student WHERE StudentID = ?",
      [studentID],
      async (err, results) => {
        if (err) {
          console.error("Error mencari StudentID:", err);
          return res
            .status(500)
            .json({ error: "Terjadi kesalahan pada server" });
        }

        if (results.length === 0) {
          return res.status(404).json({ error: "StudentID tidak ditemukan!" });
        }

        // Simpan data ke MongoDB
        const newProfile = new Profile({
          studentID,
          name,
          address,
          profileImage: `/uploads/${req.file.filename}`,
        });

        await newProfile.save();

        // Update MySQL
        const updateSQL = `UPDATE student SET StudentName = ?, StudentAddress = ?, StudentPFP = ? WHERE StudentID = ?`;
        db.query(
          updateSQL,
          [name, address, `/uploads/${req.file.filename}`, studentID],
          (err) => {
            if (err) {
              console.error("Error updating student profile:", err);
              return res
                .status(500)
                .json({ error: "Gagal memperbarui profil di database" });
            }
            res.status(200).json({ message: "Profile berhasil diperbarui" });
          }
        );
      }
    );
  } catch (error) {
    console.error("Error:", error);
    res.status(500).json({ error: "Gagal menyimpan profil" });
  }
});

// **Endpoint Get Profiles (MongoDB)**
app.get("/profiles", async (req, res) => {
  try {
    const profiles = await Profile.find();
    res.status(200).json(profiles);
  } catch (error) {
    res.status(500).json({ error: "Gagal mengambil data profil" });
  }
});

// **Endpoint untuk login**
app.post("/login", (req, res) => {
  const { email, password } = req.body;

  const sql = "SELECT * FROM student WHERE StudentEmail = ?";
  db.query(sql, [email], async (err, results) => {
    if (err) {
      console.error("Error mencari pengguna:", err);
      return res
        .status(500)
        .json({ status: "error", message: "Terjadi kesalahan pada server" });
    }

    if (results.length === 0) {
      return res
        .status(404)
        .json({ status: "not_found", message: "Email tidak ditemukan" });
    }

    const user = results[0];

    // Bandingkan password dengan hash
    const match = await bcrypt.compare(password, user.StudentPassword);
    if (!match) {
      return res
        .status(401)
        .json({ status: "wrong_password", message: "Password salah" });
    }

    res.json({
      status: "success",
      message: "Login berhasil",
      studentID: user.StudentID,
    });
  });
});

// Jalankan server
app.listen(port, () => {
  console.log(`Server berjalan di http://localhost:${port}`);
});
