import 'package:flutter/material.dart';
import 'matrix_input_page.dart'; // Import main input page

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MatrixInputPage(),
    );
  }
}
