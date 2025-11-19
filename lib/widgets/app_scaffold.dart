import 'package:flutter/material.dart';

class AppScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final Widget? bottomBar;
  const AppScaffold({super.key, required this.title, required this.body, this.bottomBar});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CircleAvatar(backgroundImage: const AssetImage('assets/imgs/robot.png'), radius: 18, backgroundColor: Colors.white.withOpacity(.8)),
          )
        ],
      ),
      body: body,
      bottomNavigationBar: bottomBar,
    );
  }
}
