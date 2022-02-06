import 'package:flutter/material.dart';
import 'package:smart_doorbell_with_horn_detection/utils/const.dart';

class HomePage extends StatefulWidget {
  HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text(appTitle),
        centerTitle: true,
      ),
    );
  }
}
