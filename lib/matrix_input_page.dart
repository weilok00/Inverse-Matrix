import 'package:flutter/material.dart';
import 'matrix_input.dart';
import 'matrix_output.dart';
import 'matrix_operations.dart';

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
      determinantText = "";
      errorMessage = "";
      showSteps = false;
      steps.clear();
    });
  }

  void _computeInverse() {
    List<List<double>> matrix = matrixControllers.map((row) {
      return row.map((controller) {
        return double.tryParse(controller.text) ?? 0.0;
      }).toList();
    }).toList();

    steps.clear(); // Reset steps for fresh calculations
    double det = calculateDeterminant(matrix, steps);
    if (det == 0) {
      setState(() {
        inverseMatrix = "";
        determinantText = "";
        errorMessage = r'\text{The matrix is singular and cannot be inverted.}';
        showSteps = true;
      });
      return;
    }

    List<List<double>>? inv = invertMatrix(matrix, steps);
    if (inv == null) {
      setState(() {
        errorMessage = r'\text{Error computing the inverse.}';
        showSteps = true;
      });
      return;
    }

    setState(() {
      errorMessage = "";
      determinantText = det.toStringAsFixed(3);
      inverseMatrix = formatMatrixWithFractions(inv);
      showSteps = true;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
      );
    });
  }

String _formatInputMatrixAsLatex() {
  String matrixString = r'\begin{bmatrix}';
  for (int i = 0; i < matrixSize; i++) {
    List<String> row = [];
    for (int j = 0; j < matrixSize; j++) {
      double value = double.tryParse(matrixControllers[i][j].text) ?? 0;

      // ✅ Display whole numbers as integers, otherwise as fractions
      if (value == value.roundToDouble()) {
        row.add(value.toInt().toString());
      } else {
        row.add(decimalToFraction(value)); // ✅ Convert to fraction if it's not an integer
      }
    }
    matrixString += row.join(' & ');
    if (i < matrixSize - 1) {
      matrixString += r'\\';
    }
  }
  matrixString += r'\end{bmatrix}';
  return matrixString;
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Matrix Inverse Calculator"),
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