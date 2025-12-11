# 📱 Target Ibadah Harian - Mobile App

Aplikasi gamifikasi untuk tracking dan motivasi ibadah harian umat Muslim. Fitur utama mencakup jadwal sholat real-time, tracking bacaan Al-Qur'an, dzikir counter, pencatatan sedekah, dan sistem poin & level untuk meningkatkan konsistensi ibadah.

---

## 📋 Daftar Isi

- [Fitur Utama](#-fitur-utama)
- [Teknologi & API](#-teknologi--api)
- [Endpoint API yang Digunakan](#-endpoint-api-yang-digunakan)
- [Arsitektur Aplikasi](#-arsitektur-aplikasi)
- [Cara Instalasi](#-cara-instalasi)
- [Panduan Penggunaan](#-panduan-penggunaan)
- [Testing Results](#-testing-results)
- [Pengembang](#-pengembang)

---

## ✨ Fitur Utama

### 🕌 Jadwal Sholat Real-Time
- Menampilkan 5 waktu sholat harian berdasarkan lokasi pengguna
- Countdown otomatis ke sholat berikutnya (update setiap detik)
- Support 8+ kota besar di Indonesia
- Data diambil dari Aladhan Prayer Times API

### 📖 Tracking Bacaan Al-Qur'an
- Daftar lengkap 114 surah dengan teks Arab, transliterasi, dan terjemahan Indonesia
- Progress bar untuk setiap surah
- Auto-save progress saat scroll
- Data diambil dari Quran API by Gading Dev

### 📿 Dzikir Counter (Tasbih Digital)
- Counter digital untuk berbagai jenis dzikir
- Support Subhanallah, Alhamdulillah, Allahu Akbar, dll
- Rekomendasi jumlah per dzikir
- Auto-save counter

### 💰 Tracking Sedekah
- Pencatatan sedekah dengan kategori
- Total sedekah bulan berjalan
- History lengkap dengan tanggal
- Disimpan di Firebase Firestore

### 🎯 Manajemen Target Ibadah
- CRUD target ibadah (Create, Read, Update, Delete)
- Filter berdasarkan kategori
- Search target
- Set tanggal target spesifik
- Disimpan di Firebase Firestore

### 🏆 Sistem Gamifikasi
- Level & Points system
- Streak tracking (konsistensi harian)
- Achievement badges
- Progress chart 7 hari terakhir
- Statistik per kategori ibadah

### 🌓 Dark Mode Support
- Toggle dark/light theme
- Persist preference ke SharedPreferences

### 🔔 Notification System
- Reminder waktu sholat (5x sehari)
- Motivasi harian (4x sehari)
- Custom notification schedule

---

## 🛠 Teknologi & API

### Framework & State Management
- **Flutter 3.4.3** - Cross-platform mobile framework
- **Provider** - State management
- **Dart 3.x** - Programming language

### Backend & Database
- **Firebase Authentication** - User authentication
- **Cloud Firestore** - NoSQL database untuk targets & sedekah
- **SharedPreferences** - Local storage untuk settings & cache

### HTTP & API Integration
- **http ^1.1.0** - HTTP client untuk API calls
- **dio** (optional) - Alternative HTTP client

### External APIs

1. **[Aladhan Prayer Times API](https://aladhan.com/prayer-times-api)**
   - Endpoint: `https://api.aladhan.com/v1`
   - Purpose: Jadwal sholat berdasarkan lokasi

2. **[Quran API by Gading Dev](https://github.com/gadingnst/quran-api)**
   - Endpoint: `https://api.quran.gading.dev`
   - Purpose: Data Al-Qur'an lengkap dengan terjemahan

### Libraries Lainnya
- **intl** - Internationalization & date formatting
- **flutter_local_notifications** - Local push notifications
- **timezone** - Timezone handling untuk notifications
- **shared_preferences** - Local data persistence

---

## 🌐 Endpoint API yang Digunakan

### 1. Aladhan Prayer Times API

#### Get Prayer Times by City

```http
GET https://api.aladhan.com/v1/timingsByCity/{date}
```

**Parameters:**
- `city` (string) - Nama kota (contoh: "Malang")
- `country` (string) - Nama negara (contoh: "Indonesia")
- `method` (int) - Calculation method (default: 20 - ISNA)

**Response Example:**

```json
{
  "code": 200,
  "status": "OK",
  "data": {
    "timings": {
      "Fajr": "04:30",
      "Dhuhr": "12:00",
      "Asr": "15:15",
      "Maghrib": "18:00",
      "Isha": "19:15"
    },
    "date": {
      "gregorian": {
        "date": "12-12-2024"
      }
    },
    "meta": {
      "timezone": "Asia/Jakarta"
    }
  }
}
```

**Implementasi:**

```dart
// File: lib/services/prayer_api_service.dart
static Future<PrayerTime?> getPrayerTimesByCity({
  required String city,
  required String country,
  DateTime? date,
}) async {
  final url = Uri.parse(
    '$_baseUrl/timingsByCity/$dateStr'
    '?city=$city&country=$country&method=$_calculationMethod',
  );
  
  final response = await http.get(url);
  // ... parsing logic
}
```

#### Get Monthly Prayer Times

```http
GET https://api.aladhan.com/v1/calendarByCity/{year}/{month}
```

---

### 2. Quran API by Gading Dev

#### Get All Surah List

```http
GET https://api.quran.gading.dev/surah
```

**Response Example:**

```json
{
  "code": 200,
  "data": [
    {
      "number": 1,
      "name": {
        "short": "الفاتحة",
        "transliteration": {
          "id": "Al-Fatihah"
        },
        "translation": {
          "id": "Pembukaan"
        }
      },
      "numberOfVerses": 7,
      "revelation": {
        "id": "Mekkah"
      }
    }
  ]
}
```

**Implementasi:**

```dart
// File: lib/services/quran_api_service.dart
static Future<List<Map<String, dynamic>>> getAllSurah() async {
  final url = Uri.parse('$_baseUrl/surah');
  final response = await http.get(url);
  
  final jsonData = json.decode(response.body);
  return (jsonData['data'] as List).map((surah) => {
    'number': surah['number'],
    'name': surah['name']['transliteration']['id'],
    'totalVerses': surah['numberOfVerses'],
    // ... mapping lainnya
  }).toList();
}
```

#### Get Surah Detail with Verses

```http
GET https://api.quran.gading.dev/surah/{surahNumber}
```

**Response Example:**

```json
{
  "code": 200,
  "data": {
    "number": 1,
    "numberOfVerses": 7,
    "name": {
      "short": "الفاتحة",
      "transliteration": { "id": "Al-Fatihah" }
    },
    "verses": [
      {
        "number": { "inSurah": 1 },
        "text": {
          "arab": "بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ",
          "transliteration": {
            "en": "Bismillaahir Rahmaanir Raheem"
          }
        },
        "translation": {
          "id": "Dengan nama Allah Yang Maha Pengasih, Maha Penyayang."
        },
        "audio": {
          "primary": "https://cdn.alquran.cloud/media/audio/ayah/ar.alafasy/1"
        }
      }
    ]
  }
}
```

---

## 🏗 Arsitektur Aplikasi

### Layer Architecture

```
lib/
├── models/              # Data models
│   ├── user_model.dart
│   ├── target_ibadah_model.dart
│   └── prayer_time_model.dart
│
├── services/            # Business logic & API calls
│   ├── auth_service.dart
│   ├── target_service.dart
│   ├── prayer_api_service.dart      # ✅ HTTP GET Prayer Times
│   ├── quran_api_service.dart       # ✅ HTTP GET Quran Data
│   ├── gamification_service.dart
│   ├── notification_service.dart
│   ├── json_service.dart
│   └── firebase/
│       ├── firebase_auth_service.dart
│       ├── firebase_target_service.dart
│       └── firebase_sedekah_service.dart
│
├── providers/           # State management
│   ├── theme_provider.dart
│   ├── locale_provider.dart
│   └── quran_progress_provider.dart
│
├── screens/             # UI Pages
│   ├── splash_screen.dart
│   ├── login_screen.dart
│   ├── home_screen.dart
│   ├── sholat_screen.dart           # ✅ Consume Prayer API
│   ├── quran_screen.dart            # ✅ Consume Quran API
│   ├── surah_detail_screen.dart     # ✅ Consume Quran API
│   ├── dzikir_screen.dart
│   ├── sedekah_screen.dart
│   ├── progress_screen.dart
│   ├── progress_home_screen.dart
│   └── profile_screen.dart
│
├── widgets/             # Reusable components
│   ├── bottom_navigation.dart
│   ├── custom_button.dart
│   └── custom_text_field.dart
│
├── constants.dart       # App constants & themes
└── main.dart           # Entry point
```

### State Management Flow

```
User Action (Tap Button)
    ↓
Screen (UI Layer)
    ↓
Provider (State Management)
    ↓
Service (Business Logic + HTTP Request)  ✅ API Call Here
    ↓
HTTP Response → JSON Parsing → Model
    ↓
Provider notifyListeners()
    ↓
Screen Rebuild (Show Data)
```

### Error Handling Strategy

```dart
// Contoh di prayer_api_service.dart
static Future<PrayerTime?> getPrayerTimesByCity({
  required String city,
  required String country,
  bool useFallback = true,
}) async {
  try {
    // 1. Try API Call
    final response = await http.get(url).timeout(
      const Duration(seconds: 10),
    );
    
    if (response.statusCode == 200) {
      // Success: Parse & return data
      return PrayerTime.fromJson(jsonData);
    } else {
      // HTTP Error: Use fallback
      if (useFallback) return _getFallbackPrayerTimes();
      return null;
    }
  } catch (e) {
    // Network Error: Use fallback
    if (useFallback) return _getFallbackPrayerTimes();
    return null;
  }
}

// Fallback with hardcoded data
static Future<PrayerTime?> _getFallbackPrayerTimes() async {
  return PrayerTime(
    fajr: '04:30',
    dhuhr: '12:00',
    // ... default times
  );
}
```

### Asynchronous UI Pattern

```dart
// Menggunakan FutureBuilder
FutureBuilder<List<Map<String, dynamic>>>(
  future: QuranApiService.getAllSurah(),
  builder: (context, snapshot) {
    // Loading State
    if (snapshot.connectionState == ConnectionState.waiting) {
      return Center(child: CircularProgressIndicator());
    }
    
    // Error State
    if (snapshot.hasError) {
      return Center(
        child: Text('Error: ${snapshot.error}'),
      );
    }
    
    // Empty State
    if (!snapshot.hasData || snapshot.data!.isEmpty) {
      return Center(child: Text('Tidak ada data'));
    }
    
    // Success State
    final surahList = snapshot.data!;
    return ListView.builder(
      itemCount: surahList.length,
      itemBuilder: (context, index) {
        return SurahCard(surah: surahList[index]);
      },
    );
  },
)
```

---

## 📥 Cara Instalasi

### Prerequisites

- Flutter SDK ≥ 3.4.3
- Dart SDK ≥ 3.0.0
- Android Studio / VS Code
- Git
- Firebase Project (sudah dikonfigurasi)

### Step-by-Step Installation

#### 1. Clone Repository

```bash
git clone https://github.com/YOUR_USERNAME/targetibadah-gamifikasi.git
cd targetibadah-gamifikasi
```

#### 2. Install Dependencies

```bash
flutter pub get
```

#### 3. Firebase Setup

Aplikasi ini sudah dikonfigurasi dengan Firebase. File `google-services.json` dan `firebase_options.dart` sudah ada di repository.

Jika ingin menggunakan Firebase project sendiri:

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login ke Firebase
firebase login

# Configure FlutterFire
flutterfire configure
```

#### 4. Run Application

**Android:**

```bash
flutter run
```

**iOS (Mac only):**

```bash
cd ios
pod install
cd ..
flutter run
```

#### 5. Build APK (Release)

```bash
flutter build apk --release
```

APK akan tersimpan di: `build/app/outputs/flutter-apk/app-release.apk`

---

## 📖 Panduan Penggunaan

### 1. Registrasi & Login

**Buat Akun Baru:**
- Tap "Daftar Sekarang" di halaman login
- Isi: Nama Lengkap, Email, Password (min 6 karakter)
- Centang "Syarat & Ketentuan"
- Tap "Buat Akun"

**Login dengan Akun Demo:**
```
Email: Nirma@gmail.com
Password: nirma123
```

### 2. Dashboard (Home)

- **Jadwal Sholat Card**: Menampilkan 5 waktu sholat hari ini dengan countdown real-time
- **Progress Card**: Lihat persentase target harian yang sudah diselesaikan
- **Kategori Icons**: Tap untuk akses fitur spesifik (Sholat/Qur'an/Dzikir/Sedekah)
- **Daftar Target**: Checkbox untuk mark target sebagai selesai

### 3. Kelola Target Ibadah

- Tap menu "Target" (ikon kalender) di bottom nav
- **Tambah Target**: Tap tombol + → Isi form → Simpan
- **Edit Target**: Tap ikon ⋮ pada target → "Edit"
- **Hapus Target**: Tap ikon ⋮ → "Hapus" → Konfirmasi
- **Search**: Ketik nama target di search bar
- **Filter**: Tap chip kategori untuk filter

### 4. Jadwal Sholat

- Tap kategori "Sholat" dari Home
- Lihat 5 waktu sholat dengan countdown ke sholat berikutnya
- Sholat berikutnya ditandai dengan border berwarna dan countdown yang update setiap detik
- **Ubah Lokasi**: Settings → Lokasi → Pilih kota

### 5. Tracking Bacaan Al-Qur'an

- Tap kategori "Qur'an" dari Home
- Browse daftar 114 surah dengan progress bar
- **Baca Surah**: Tap surah → Scroll untuk auto-save progress
- **Reset Progress**: Tap ikon refresh di AppBar

### 6. Dzikir Counter

- Tap kategori "Dzikir"
- Pilih jenis dzikir dari dropdown
- Tap tombol **+** (hijau) untuk increment
- Tap tombol **-** (merah) untuk decrement
- Tap tombol **↻** (kuning) untuk reset

### 7. Tracking Sedekah

- Tap kategori "Sedekah"
- Isi jumlah (Rupiah) dan keterangan
- Tap "Catat Sedekah"
- **Hapus**: Swipe left pada item history → Konfirmasi

### 8. Progress & Gamifikasi

- Tap menu "Progress" di bottom nav
- Lihat Level & Points saat ini
- **Streak**: Cek konsistensi harian (hari berturut-turut)
- **Grafik 7 Hari**: Bar chart progress mingguan
- **Statistik Kategori**: Progress per jenis ibadah
- **Achievements**: Badge yang sudah di-unlock

### 9. Profile

- Tap menu "Profile"
- **Edit Profil**: Ubah nama & email
- **Ubah Password**: Ganti password lama dengan baru
- **Logout**: Tap "Keluar" → Konfirmasi

### 10. Settings

- Tap menu "Settings"
- **Mode Gelap**: Toggle untuk dark/light theme
- **Notifikasi Sholat**: Toggle reminder waktu sholat
- **Notifikasi Motivasi**: Toggle pesan motivasi harian
- **Lokasi**: Pilih kota untuk jadwal sholat
- **Test Notifikasi**: Tap untuk test apakah notifikasi berfungsi

---

## 🧪 Testing Results

### API Integration Testing

#### ✅ Prayer Times API

- **Endpoint Tested**: `GET /timingsByCity/{date}`
- **Test Cases**: 
  - ✅ Berhasil fetch jadwal sholat untuk Jakarta
  - ✅ Berhasil fetch untuk Surabaya
  - ✅ Handle timeout dengan fallback
  - ✅ Parse JSON ke PrayerTime model
  - ✅ Countdown update setiap detik

#### ✅ Quran API

- **Endpoint Tested**: 
  - `GET /surah` (Get all surah)
  - `GET /surah/{number}` (Get surah detail)
- **Test Cases**: 
  - ✅ Fetch 114 surah berhasil
  - ✅ Detail surah dengan verses & translation
  - ✅ Progress auto-save saat scroll
  - ✅ Handle empty/error state

### Error Handling Testing

| Scenario | Expected Behavior | Status |
|----------|------------------|--------|
| No Internet Connection | Show fallback data + error message | ✅ Pass |
| API Timeout (>10s) | Trigger fallback mechanism | ✅ Pass |
| Invalid City Name | Use default Jakarta data | ✅ Pass |
| Empty API Response | Show "Tidak ada data" | ✅ Pass |
| HTTP 404/500 Error | Show error message + retry option | ✅ Pass |

---

## 👨‍💻 Pengembang

- **Nama**: Nirma Nur Diana
- **NIM**: 230605110147
- **Mata Kuliah**: Mobile Programming
- **Dosen Pengampu**: A'LA SYAUQI, M.Kom
- **Semester**: Ganjil 2025/2026
- **Universitas**: Universitas Islam Negeri Maulana Malik Ibrahim Malang
- **Prodi**: Teknik Informatika

---

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- [Aladhan API](https://aladhan.com/prayer-times-api) - Prayer times data
- [Quran API by Gading Dev](https://github.com/gadingnst/quran-api) - Al-Qur'an data with Indonesian translation
- [Firebase](https://firebase.google.com/) - Backend & authentication
- Flutter Community - Various packages & plugins
- Material Design - UI/UX guidelines

---

## 📞 Contact

Jika ada pertanyaan atau feedback, silakan hubungi:

- **Email**: 230605110147@student.uin-malang.ac.id
- **GitHub**: [@Nrmadn](https://github.com/Nrmadn)
- **LinkedIn**: [Nirma Nur Diana](https://linkedin.com/in/nirma-nur-diana)

---

<p align="center">Made with ❤️ by Nirma Nur Diana</p>