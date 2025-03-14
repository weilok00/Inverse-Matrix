import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'matrix_input.dart';
import 'matrix_output.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MatrixInputPage extends StatefulWidget {
  @override
  _MatrixInputPageState createState() => _MatrixInputPageState();
}

class _MatrixInputPageState extends State<MatrixInputPage> {
  int matrixSize = 2;
  List<List<TextEditingController>> matrixControllers = [];
  String inverseMatrix = "";
  String determinantText = "";
  String errorMessage = "";
  bool showSteps = false;
  List<String> steps = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _generateMatrix();
  }

    void _generateMatrix() {
      setState(() {
        matrixControllers = List.generate(
          matrixSize,
          (i) => List.generate(matrixSize, (j) => TextEditingController()),
        );
        inverseMatrix = "";
        errorMessage = "";
      });
    }

  void _computeInverse() async {
    List<List<String>> matrix = matrixControllers.map((row) {
      return row.map((controller) {
        return controller.text;
      }).toList();
    }).toList();

    try {
      var response = await http.post(
        Uri.parse('http://localhost:5000/matrix_inverse'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'matrix': matrix}),
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);

        String determinantLatex = data['determinant'];
        List<List<String>> inverseMatrixData = (data['inverse'] as List<dynamic>)
            .map((row) => (row as List<dynamic>).map((e) => e.toString()).toList())
            .toList();

        List<String> stepsData = List<String>.from(data['steps']);

        String formattedInverse = _formatInverseMatrixAsLatex(inverseMatrixData);

        setState(() {
          determinantText = determinantLatex;
          inverseMatrix = formattedInverse;
          errorMessage = "";
          steps = stepsData;
          showSteps = true;
        });
      } else {
        var data = jsonDecode(response.body);
        setState(() {
          errorMessage = data['error'];
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "An error occurred: $e";
      });
    }
  }


  /// ✅ Format the Input Matrix for Display
  String _formatInputMatrixAsLatex() {
    String matrixString = r'\begin{bmatrix}';
    for (int i = 0; i < matrixSize; i++) {
      List<String> row = [];
      for (int j = 0; j < matrixSize; j++) {
        String value = matrixControllers[i][j].text;
        row.add(value.isEmpty ? "0" : value);
      }
      matrixString += row.join(' & ');
      if (i < matrixSize - 1) {
        matrixString += r'\\';
      }
    }
    matrixString += r'\end{bmatrix}';
    return matrixString;
  }

String _formatInverseMatrixAsLatex(List<List<String>> matrix) {
  int mid = matrix[0].length ~/ 2;
  String alignment = 'c' * mid + '|' + 'c' * (matrix[0].length - mid);

  String matrixString = r'\left[\begin{array}{' + alignment + r'}';
  
  for (var row in matrix) {
    String left = row.sublist(0, mid).join(' & ');
    String right = row.sublist(mid).join(' & ');
    matrixString += '$left & $right \\\\';
  }

  matrixString += r'\end{array}\right]';
  return matrixString;
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Math.tex(
          r'\text{Matrix Inverse Calculator}', // ✅ LaTeX formatted title
          textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            MatrixInput(
              matrixSize: matrixSize,
              matrixControllers: matrixControllers,
              onMatrixSizeChanged: (size) {
                setState(() {
                  matrixSize = size;
                  _generateMatrix();
                });
              },
              onComputeInverse: _computeInverse, // ✅ Compute inverse when button is pressed
            ),
            MatrixOutput(
              inputMatrix: _formatInputMatrixAsLatex(), // ✅ Pass formatted matrix
              determinantText: determinantText,
              inverseMatrix: inverseMatrix,
              errorMessage: errorMessage,
              showSteps: showSteps,
              steps: steps,
            ),
          ],
        ),
      ),
    );
  }
}