import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'home.dart' as home;
import 'chats.dart' as chats;


class Menu extends StatefulWidget {
  const Menu({Key? key}) : super(key: key);

  @override
  _MenuState createState() => _MenuState();
}

class _MenuState extends State<Menu> with SingleTickerProviderStateMixin {
  late TabController controller;


  @override
  void initState() {
    controller = TabController(length: 2, vsync: this);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TabBarView(
        controller: controller,
        children: [home.Utama(), chats.Chats()],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),

            ),
          ],
        ),
        child: TabBar(
          tabs: [
            Tab(icon: Icon(FontAwesomeIcons.heartCircleBolt,size: 16,), text: "Berdua"),
            Tab(icon: Icon(FontAwesomeIcons.solidMessage,size: 16,), text: "Chats"),
          ],
          controller: controller,
        ),
      ),
    );
  }
}
