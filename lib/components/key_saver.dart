import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// Class Password tidak berubah
class Password {
  final int id;
  final String provider;
  final String username;
  final String password;

  Password({
    required this.id,
    required this.provider,
    required this.password,
    required this.username,
  });

  Password.fromJson(Map<String, dynamic> json)
      : id = json['id'] as int,
        provider = json['provider'] as String,
        username = json['username'] as String,
        password = json['password'] as String;
}

class View extends StatefulWidget {
  const View({Key? key}) : super(key: key);

  @override
  _ViewState createState() => _ViewState();
}

class _ViewState extends State<View> {
  late Future<List<Password>> futurePasswords;
  final TextEditingController username_view = TextEditingController();
  final TextEditingController password_view = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    futurePasswords = fetchPasswords();
  }

  // Fungsi fetchPasswords tidak berubah
  Future<List<Password>> fetchPasswords() async {
    final response = await http.post(
      Uri.parse("https://password-manager-liart-mu.vercel.app/get"),
    );

    if (response.statusCode == 200) {
      List<dynamic> decodedList = jsonDecode(response.body);
      List<Password> passwords = decodedList.map((item) {
        return Password.fromJson(item as Map<String, dynamic>);
      }).toList();
      return passwords;
    } else {
      throw Exception("Failed to load passwords");
    }
  }

  void _refreshPasswords() {
    setState(() {
      futurePasswords = fetchPasswords();
    });
  }

  // Fungsi _getProviderIcon tidak berubah
  Widget _getProviderIcon(String provider) {
    IconData icon;
    Color color;
    String lowerCaseProvider = provider.toLowerCase();

    switch (lowerCaseProvider) {
      case "google":
        icon = FontAwesomeIcons.google;
        color = Colors.redAccent;
        break;
      case "instagram":
        icon = FontAwesomeIcons.instagram;
        color = Colors.purpleAccent;
        break;
      case "shoope":
        icon = FontAwesomeIcons.cartShopping;
        color = Colors.orangeAccent;
        break;
      case "facebook":
        icon = FontAwesomeIcons.facebook;
        color = Colors.blueAccent;
        break;
      case "github":
        icon = FontAwesomeIcons.github;
        color = Colors.black;
        break;
      case "tokopedia":
        icon = FontAwesomeIcons.cartShopping;
        color = Colors.green;
      default:
        icon = FontAwesomeIcons.key;
        color = Colors.blueAccent;
    }

    return CircleAvatar(
      radius: 24,
      backgroundColor: color.withOpacity(0.15),
      child: FaIcon(icon, color: color, size: 22),
    );
  }

  // --- IMPLEMENTASI FITUR TAMBAH PASSWORD ---
  void _addPassword() {
    final _providerController = TextEditingController();
    final _usernameController = TextEditingController();
    final _passwordController = TextEditingController();
    final _formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
                  const SizedBox(height: 20),
                  const Text("Tambah Akun Baru", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _providerController,
                    decoration: _inputDecoration("Provider (e.g., Google)"),
                    validator: (value) => value!.isEmpty ? 'Provider tidak boleh kosong' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _usernameController,
                    decoration: _inputDecoration("Username atau Email"),
                    validator: (value) => value!.isEmpty ? 'Username tidak boleh kosong' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: _inputDecoration("Password"),
                    obscureText: true,
                    validator: (value) => value!.isEmpty ? 'Password tidak boleh kosong' : null,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyan,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        _performAddPassword(
                          _providerController.text,
                          _usernameController.text,
                          _passwordController.text,
                        );
                      }
                    },
                    child: const Text("Simpan", style: TextStyle(fontSize: 16, color: Colors.white)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _performAddPassword(String provider, String username, String password) async {
    final response = await http.post(
      Uri.parse("https://password-manager-liart-mu.vercel.app/add"),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'provider': provider,
        'username': username,
        'password': password,
      },

    );

    if (mounted) {
      Navigator.pop(context); // Tutup bottom sheet
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Akun berhasil ditambahkan!'), backgroundColor: Colors.green),
        );
        _refreshPasswords(); // Muat ulang data
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menambahkan akun.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // --- IMPLEMENTASI FITUR HAPUS PASSWORD ---
  void _deletePassword(int id) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Konfirmasi Hapus'),
          content: const Text('Apakah Anda yakin ingin menghapus akun ini? Tindakan ini tidak dapat dibatalkan.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop(); // Tutup dialog konfirmasi
                _performDeletePassword(id);
              },
              child: const Text('Hapus', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performDeletePassword(int id) async {
    final response = await http.post(
      Uri.parse("https://password-manager-liart-mu.vercel.app/delete"),
      headers: <String, String>{
        'id': id.toString(),
      },
    );

    if (mounted) {
      Navigator.pop(context); // Tutup bottom sheet detail
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Akun berhasil dihapus!'), backgroundColor: Colors.green),
        );
        _refreshPasswords(); // Muat ulang data
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menghapus akun.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.grey[100],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  // Build method tidak berubah
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        title: const Text(
          'Key Saver',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 24),
        ),
        actions: [
          IconButton(
            onPressed: _addPassword,
            icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.black87, size: 28),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: FutureBuilder<List<Password>>(
        future: futurePasswords,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.cyan));
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)));
          } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            List<Password> passwordsList = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              itemCount: passwordsList.length,
              itemBuilder: (context, index) {
                Password currentPassword = passwordsList[index];
                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  color: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(15.0),
                    onTap: () {
                      setState(() {
                        username_view.text = currentPassword.username;
                        password_view.text = currentPassword.password;
                        _isPasswordVisible = false;
                      });
                      _showPasswordDetails(context, currentPassword);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          _getProviderIcon(currentPassword.provider),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currentPassword.provider,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  currentPassword.username,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, color: Colors.black38, size: 16),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          } else {
            return const Center(
              child: Text(
                "Belum ada password tersimpan.",
                style: TextStyle(color: Colors.black54, fontSize: 16),
              ),
            );
          }
        },
      ),
    );
  }

  // Method _showPasswordDetails diupdate untuk memanggil fungsi delete
  void _showPasswordDetails(BuildContext context, Password currentPassword) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter modalSetState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 50,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        _getProviderIcon(currentPassword.provider),
                        const SizedBox(width: 16),
                        Text(
                          currentPassword.provider,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 28),
                          onPressed: () {
                            // Panggil fungsi hapus dengan konfirmasi
                            _deletePassword(currentPassword.id);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),
                    _buildTextField(
                      controller: username_view,
                      label: "Username",
                      icon: FontAwesomeIcons.user,
                      isReadOnly: true,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: password_view,
                      label: "Password",
                      icon: FontAwesomeIcons.lock,
                      isPassword: true,
                      isPasswordVisible: _isPasswordVisible,
                      onVisibilityToggle: () {
                        modalSetState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                      onCopy: () {
                        Clipboard.setData(ClipboardData(text: currentPassword.password));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Password disalin ke clipboard!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        "Tips: Manfaatkan fitur hapus lalu buat baru jika ingin mengubah password. Fitur edit masih dalam pengembangan! 😉",
                        style: TextStyle(color: Colors.black54, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Method _buildTextField tidak berubah
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool isPasswordVisible = false,
    bool isReadOnly = false,
    VoidCallback? onVisibilityToggle,
    VoidCallback? onCopy,
  }) {
    return TextField(
      controller: controller,
      readOnly: isReadOnly || isPassword,
      obscureText: isPassword && !isPasswordVisible,
      style: const TextStyle(color: Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.black54),
        filled: true,
        fillColor: Colors.grey[200],
        prefixIcon: Icon(icon, color: Colors.blueGrey, size: 20),
        suffixIcon: isPassword
            ? Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                isPasswordVisible ? FontAwesomeIcons.eyeSlash : FontAwesomeIcons.eye,
                color: Colors.black54,
                size: 18,
              ),
              onPressed: onVisibilityToggle,
            ),
            IconButton(
              icon: const Icon(FontAwesomeIcons.copy, color: Colors.black54, size: 18),
              onPressed: onCopy,
            ),
          ],
        )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.cyan),
        ),
      ),
    );
  }
}