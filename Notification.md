# Arsitektur Notifikasi Baru

Dokumen ini menjelaskan arsitektur notifikasi baru yang diimplementasikan untuk aplikasi ini, dengan fokus pada stabilitas, efisiensi, dan penghapusan duplikasi.

## 1. Strategi Arsitektur: Unified Stream Handler

Arsitektur ini didasarkan pada prinsip **satu sumber kebenaran (Single Source of Truth)** untuk semua pesan Firebase Cloud Messaging (FCM) yang masuk. Sumber tunggal tersebut adalah stream `FirebaseMessaging.onMessage`. Pendekatan ini secara fundamental menyederhanakan logika karena tidak ada lagi penanganan terpisah untuk pesan yang datang saat aplikasi di *foreground* versus *background*.

### Komponen Utama:

1.  **FCM Topic "message"**: Satu-satunya channel di mana backend mengirim semua notifikasi push. Seluruh aplikasi hanya berlangganan ke satu topic ini.
2.  **Persistent Background Service**: Sebuah `ForegroundService` (`FlutterBackgroundService`) yang berjalan terus-menerus. Tugas utamanya adalah mendengarkan stream `FirebaseMessaging.onMessage` dan memutuskan apakah perlu menampilkan notifikasi lokal.
3.  **UI/App State Listener**: Logika di dalam lapisan UI aplikasi yang juga mendengarkan stream `FirebaseMessaging.onMessage` yang sama. Tugasnya adalah me-refresh data dan UI chat saat aplikasi berada di *foreground*.
4.  **Lifecycle Manager**: Sebuah mekanisme (`WidgetsBindingObserver`) yang secara andal memberi tahu *Background Service* tentang status aplikasi saat ini (apakah sedang dibuka atau tidak).

Arsitektur ini menghapus total kebutuhan untuk menyimpan pesan di `SharedPreferences` sebagai antrian (queue), yang merupakan sumber utama kompleksitas dan bug pada implementasi sebelumnya.

## 2. Alur Data Notifikasi

Alur data terpadu untuk semua kondisi aplikasi adalah sebagai berikut:

```text
               +-----------------+
               |   FCM Backend   |
               +-----------------+
                      | (Topic: "message")
                      V
+------------------------------------------------------+
|                    FLUTTER APP                       |
|                                                      |
|         +------------------------------------+       |
|         | FirebaseMessaging.onMessage Stream |       |
|         +------------------------------------+       |
|                        |                             |
|         +------------------------------------+       |
|         |      Message Handler (Decision)    |       |
|         +------------------------------------+       |
|            /                           \             |
|           /                             \            |
|          V                               V           |
| +-------------------+        +-----------------------+ |
| |   APP FOREGROUND  |        | APP BACKGROUND/KILLED | |
| +-------------------+        +-----------------------+ |
|          |                               |           |
|          V                               V           |
| +-------------------+        +-----------------------+ |
| |    - No Notif     |        | - Show Local Notif    | |
| |    - Reload Chat  |        | - (No UI action)      | |
| +-------------------+        +-----------------------+ |
|                                                      |
+------------------------------------------------------+
```

## 3. Keunggulan Solusi Ini

-   **Stabil & Efisien**: Menggunakan listener *event-driven* dari stream native FCM jauh lebih hemat baterai dan CPU daripada melakukan polling `SharedPreferences` setiap beberapa detik.
-   **Tidak Duplikat**: Hanya ada satu alur logika terpadu. Setiap pesan yang masuk diperiksa statusnya, lalu ditangani sesuai kondisi (foreground/background). Tidak ada lagi cabang logika terpisah yang berisiko tumpang tindih atau menyebabkan notifikasi ganda.
-   **Tidak Spam Notifikasi**: Adanya `Lifecycle Manager` memastikan notifikasi tidak akan pernah muncul saat pengguna sedang aktif menggunakan aplikasi, sehingga meningkatkan pengalaman pengguna.
-   **Modern & Android-Friendly**: Arsitektur ini selaras dengan praktik terbaik pengembangan Android modern. Ia menggunakan `ForegroundService` untuk tugas jangka panjang dan menghormati *lifecycle* aplikasi, sehingga tidak mudah dihentikan oleh sistem operasi.
