import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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
      case "shoope": // Nama provider disesuaikan
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

  void _addpassword() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 30),
              const FaIcon(FontAwesomeIcons.gears, color: Colors.cyan, size: 40),
              const SizedBox(height: 20),
              const Text(
                "Fitur Belum Tersedia",
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Sabar ya, fitur ini sedang dalam pengembangan! 👨‍💻",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54, fontSize: 16),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

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
            onPressed: _addpassword,
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
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fitur hapus belum siap.')));
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
