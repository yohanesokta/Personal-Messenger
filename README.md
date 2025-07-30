

Aplikasi perpesanan pribadi yang aman, intim, dan kaya fitur, dirancang khusus untuk dua orang. Dibangun dengan Flutter dan ditenagai oleh Firebase Cloud Messaging.


-----

## 📝 Tentang Proyek

**Hanya Kita Berdua** adalah solusi modern untuk komunikasi yang privat dan personal. Di dunia yang penuh dengan aplikasi sosial yang ramai, proyek ini menawarkan sebuah ruang digital yang tenang dan aman, hanya untuk Anda dan seseorang yang spesial. Aplikasi ini tidak hanya fokus pada pengiriman pesan, tetapi juga pada pengalaman pengguna yang intim dengan fitur-fitur yang mendukung interaksi mendalam, mulai dari balasan pesan hingga penguncian aplikasi otomatis untuk menjaga privasi.

Proyek ini merupakan studi kasus dalam membangun aplikasi modern yang kompleks dengan Flutter, mengintegrasikan layanan latar belakang, notifikasi push, dan fitur keamanan tingkat lanjut.

-----

## ✨ Fitur Utama

  - 🔒 **Layar Kunci PIN**: Keamanan dimulai dari awal. Aplikasi dilindungi oleh PIN untuk memastikan hanya Anda yang bisa mengaksesnya.
  - 🔄 **Penguncian Otomatis**: Aplikasi akan otomatis kembali ke layar kunci saat dibuka dari riwayat (background), memberikan lapisan keamanan tambahan.
  - 💬 **Real-time Chat**: Pengalaman chatting yang mulus dengan indikator pesan terkirim.
  - 🖼️ **Pengiriman Gambar**: Bagikan momen melalui gambar dengan pratinjau dan opsi untuk menambahkan caption.
  - ↪️ **Balas Pesan**: Konteks percakapan tetap terjaga dengan fitur balas pesan geser (*swipe-to-reply*).
  - 🔔 **Notifikasi Push Cerdas**: Ditenagai oleh FCM, dengan notifikasi *pop-up* (heads-up) yang interaktif.
  - 🤫 **Pemicu Senyap (Silent Trigger)**: Kemampuan untuk me-refresh data di latar belakang tanpa mengganggu pengguna dengan notifikasi.
  - 🚀 **Layanan Latar Belakang (Foreground Service)**: Notifikasi "Aplikasi Siaga" yang persisten memastikan aplikasi selalu siap menerima pesan.
  - 📞 **Fitur Panggilan Video & Suara**: Integrasi Webview untuk panggilan video dan suara langsung dari aplikasi.
  - 🔋 **Manajemen Baterai**: Mengarahkan pengguna untuk menonaktifkan optimisasi baterai demi keandalan layanan.

-----

## 🛠️ Teknologi & Arsitektur

Proyek ini dibangun menggunakan serangkaian teknologi modern untuk memastikan aplikasi yang tangguh dan efisien.

  - **Framework**: [Flutter](https://flutter.dev/)
  - **Bahasa**: [Dart](https://dart.dev/)
  - **Arsitektur State Management**: [Provider](https://pub.dev/packages/provider)
  - **Push Notifications**: [Firebase Cloud Messaging (FCM)](https://firebase.google.com/docs/cloud-messaging)
  - **Background Processing**:
      - [flutter\_background\_service](https://pub.dev/packages/flutter_background_service) untuk Foreground Service yang persisten.
      - Komunikasi antar *isolate* (FCM & Service) menggunakan pola "Mailbox" via [shared\_preferences](https://pub.dev/packages/shared_preferences).
  - **UI & Komponen**:
      - [scrollable\_positioned\_list](https://www.google.com/search?q=https://pub.dev/packages/scrollable_positioned_list) untuk daftar chat yang efisien.
      - [emoji\_picker\_flutter](https://pub.dev/packages/emoji_picker_flutter) untuk input emoji.
      - [image\_picker](https://pub.dev/packages/image_picker) untuk memilih gambar dari galeri.
  - **Perizinan**: [permission\_handler](https://pub.dev/packages/permission_handler)
  - **Environment Variables**: [flutter\_dotenv](https://pub.dev/packages/flutter_dotenv)

-----

## 🚀 Memulai Proyek

Untuk menjalankan proyek ini di lingkungan lokal Anda, ikuti langkah-langkah berikut.

### Prasyarat

  - Pastikan Anda sudah menginstal **Flutter SDK** (versi 3.x atau lebih tinggi).
  - Sebuah IDE seperti **Visual Studio Code** atau **Android Studio**.
  - Emulator Android atau perangkat fisik.

### Instalasi & Konfigurasi

1.  **Clone Repositori**

    ```sh
    git clone [URL_REPOSITORI_ANDA]
    cd [NAMA_FOLDER_PROYEK]
    ```

2.  **Instal Dependensi**
    Jalankan perintah berikut untuk mengunduh semua package yang dibutuhkan.

    ```sh
    flutter pub get
    ```

3.  **Konfigurasi Firebase**
    Proyek ini memerlukan Firebase untuk notifikasi.

      - Buat proyek baru di [Firebase Console](https://console.firebase.google.com/).
      - Daftarkan aplikasi Android Anda (pastikan nama paketnya cocok, misal: `com.yohaneschelin.secret`).
      - Unduh file `google-services.json` dan letakkan di dalam folder `android/app/`.

4.  **Konfigurasi Environment Variables**

      - Buat sebuah file baru bernama `.env` di folder utama (root) proyek Anda.
      - Tambahkan variabel yang dibutuhkan, terutama URL backend Anda.

    <!-- end list -->

    ```env
    SOCKET_URL=...
    ```

      - Pastikan Anda juga sudah mendaftarkan file `.env` di `pubspec.yaml`:

    <!-- end list -->

    ```yaml
    flutter:
      assets:
        - .env
        - assets/profiles.jpeg
    ```

5.  **Jalankan Aplikasi**
    Hubungkan perangkat atau jalankan emulator, lalu gunakan perintah berikut:

    ```sh
    flutter run
    ```