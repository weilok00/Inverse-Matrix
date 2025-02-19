import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_math_fork/flutter_math.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // Removed const keyword from constructor invocation to avoid const-with-nonconst errors.
  MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MatrixInputPage(),
    );
  }
}

class MatrixInputPage extends StatefulWidget {
  @override
  _MatrixInputPageState createState() => _MatrixInputPageState();
}

class _MatrixInputPageState extends State<MatrixInputPage> {
  int matrixSize = 2; // Default matrix size
  List<List<TextEditingController>> matrixControllers = [];
  String inverseMatrix = "";
  String determinantText = "";
  String errorMessage = "";
  bool showSteps = false;
  List<String> steps = []; // Store step-by-step calculation steps
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
        return double.tryParse(controller.text) ?? 0;
      }).toList();
    }).toList();

    double determinant = _calculateDeterminant(matrix);
    if (determinant == 0) {
      setState(() {
        inverseMatrix = "";
        determinantText = "";
        errorMessage = r'\text{The matrix is singular and cannot be inverted.}';
      });
      return;
    }

    List<List<double>>? inverse = _invertMatrix(matrix);
    if (inverse == null) {
      setState(() {
        errorMessage = r'\text{Error computing the inverse.}';
      });
      return;
    }

    String formattedMatrix = _formatMatrixWithFractions(inverse);

    setState(() {
      errorMessage = "";
      determinantText = r'\text{Determinant: }' + determinant.toStringAsFixed(3);
      inverseMatrix = formattedMatrix;
      showSteps = true;
    });

    // Scroll to the bottom after computation.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 500),
        curve: Curves.easeOut,
      );
    });
  }

  double _calculateDeterminant(List<List<double>> matrix) {
    if (matrixSize == 2) {
      double det = (matrix[0][0] * matrix[1][1]) - (matrix[0][1] * matrix[1][0]);
      steps.add(r'\mathrm{Determinant = (' +
          matrix[0][0].toString() +
          r' \times ' +
          matrix[1][1].toString() +
          r') - (' +
          matrix[0][1].toString() +
          r' \times ' +
          matrix[1][0].toString() +
          r') = ' +
          det.toString() +
          r'}');
      return det;
    }
    return 1; // Placeholder for larger matrices
  }

  List<List<double>>? _invertMatrix(List<List<double>> matrix) {
    int n = matrix.length;
    List<List<double>> augmented =
        List.generate(n, (i) => List.generate(2 * n, (j) => 0.0));

    // Step 1: Augment the matrix with the identity matrix.
    steps.add(r'\text{Step 1: Augment the matrix with the identity matrix:}');
    for (int i = 0; i < n; i++) {
      for (int j = 0; j < n; j++) {
        augmented[i][j] = matrix[i][j];
      }
      augmented[i][n + i] = 1;
    }
    steps.add(_formatAugmentedMatrix(augmented));

    // Step 2: Apply Gaussian elimination.
    for (int i = 0; i < n; i++) {
      double pivot = augmented[i][i];
      if (pivot == 0) return null;

      // Normalize pivot row.
      for (int j = 0; j < 2 * n; j++) {
        augmented[i][j] /= pivot;
      }
      steps.add(r'\text{Step ' +
          (i + 2).toString() +
          r': Normalize row ' +
          (i + 1).toString() +
          r' by dividing by pivot ' +
          pivot.toString() +
          r':}');
      steps.add(_formatAugmentedMatrix(augmented));

      // Eliminate other rows.
      for (int k = 0; k < n; k++) {
        if (k != i) {
          double factor = augmented[k][i];
          for (int j = 0; j < 2 * n; j++) {
            augmented[k][j] -= factor * augmented[i][j];
          }
          steps.add(r'\text{Eliminate row ' +
              (k + 1).toString() +
              r' using row ' +
              (i + 1).toString() +
              r' (factor: ' +
              factor.toString() +
              r'):}');
          steps.add(_formatAugmentedMatrix(augmented));
        }
      }
    }

    steps.add(r'\text{Final step: Extract the inverse matrix from the augmented matrix.}');
    return List.generate(n, (i) => List.generate(n, (j) => augmented[i][j + n]));
  }

  // Convert a decimal number to a fraction formatted in LaTeX.
  String _decimalToFraction(double number) {
    const double tolerance = 1.0E-6;
    if (number == number.roundToDouble()) {
      return number.toInt().toString();
    }
    int sign = number < 0 ? -1 : 1;
    number = number.abs();
    int numerator = 1;
    int denominator = 1;
    double fraction = numerator / denominator;
    while ((fraction - number).abs() > tolerance) {
      if (fraction < number) {
        numerator++;
      } else {
        denominator++;
        numerator = (number * denominator).round();
      }
      fraction = numerator / denominator;
    }
    int gcd = _gcd(numerator, denominator);
    numerator = numerator ~/ gcd;
    denominator = denominator ~/ gcd;
    if (denominator == 1) {
      return (sign < 0 ? "-" : "") + numerator.toString();
    } else {
      return (sign < 0 ? "-" : "") +
          r'\frac{' +
          numerator.toString() +
          '}{' +
          denominator.toString() +
          '}';
    }
  }

  // Helper method to compute the greatest common divisor.
  int _gcd(int a, int b) {
    return b == 0 ? a.abs() : _gcd(b, a % b);
  }

  // Format a matrix as a LaTeX pmatrix.
  String _formatMatrixWithFractions(List<List<double>> matrix) {
    String matrixString = r'\begin{pmatrix}';
    for (int i = 0; i < matrix.length; i++) {
      List<String> row = [];
      for (int j = 0; j < matrix[i].length; j++) {
        row.add(_decimalToFraction(matrix[i][j]));
      }
      matrixString += row.join(' & ');
      if (i < matrix.length - 1) {
        matrixString += r'\\';
      }
    }
    matrixString += r'\end{pmatrix}';
    return matrixString;
  }

  // Format the augmented matrix (for steps) as a LaTeX array with a vertical separator.
  String _formatAugmentedMatrix(List<List<double>> matrix) {
    int n = matrixSize;
    String colAlignment = "";
    for (int i = 0; i < n; i++) {
      colAlignment += "c";
    }
    colAlignment += "|";
    for (int i = 0; i < n; i++) {
      colAlignment += "c";
    }
    String matrixString = r'\left[\begin{array}{' + colAlignment + r'}';
    for (int i = 0; i < matrix.length; i++) {
      List<String> row = [];
      for (int j = 0; j < matrix[i].length; j++) {
        row.add(_decimalToFraction(matrix[i][j]));
      }
      matrixString += row.join(" & ");
      if (i < matrix.length - 1) {
        matrixString += r'\\';
      }
    }
    matrixString += r'\end{array}\right]';
    return matrixString;
  }

  // Format the input matrix A as LaTeX.
  String _formatInputMatrixAsLatex() {
    String matrixString = r'\begin{pmatrix}';
    for (int i = 0; i < matrixSize; i++) {
      List<String> row = [];
      for (int j = 0; j < matrixSize; j++) {
        double value = double.tryParse(matrixControllers[i][j].text) ?? 0;
        row.add(_decimalToFraction(value));
      }
      matrixString += row.join(' & ');
      if (i < matrixSize - 1) {
        matrixString += r'\\';
      }
    }
    matrixString += r'\end{pmatrix}';
    return matrixString;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Math.tex(
          r'\text{Matrix Inverse Calculator (Step-by-Step)}',
          textStyle: TextStyle(fontSize: 20),
        ),
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dropdown to select matrix size.
            DropdownButton<int>(
              value: matrixSize,
              items: [2, 3, 4].map((size) {
                return DropdownMenuItem<int>(
                  value: size,
                  child: Text("${size}x$size Matrix"),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    matrixSize = value;
                    _generateMatrix();
                  });
                }
              },
            ),
            SizedBox(height: 20),
            // Matrix input fields.
            Column(
              children: List.generate(matrixSize, (i) {
                return Row(
                  children: List.generate(matrixSize, (j) {
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.all(4.0),
                        child: TextField(
                          controller: matrixControllers[i][j],
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    );
                  }),
                );
              }),
            ),
            SizedBox(height: 20),
            // Display input matrix A.
            Math.tex(
              r'A = ' + _formatInputMatrixAsLatex(),
              textStyle: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 20),
            // Compute Inverse Button.
            ElevatedButton(
              onPressed: _computeInverse,
              child: Math.tex(
                r'\text{Compute Inverse}',
                textStyle: TextStyle(fontSize: 16),
              ),
            ),
            SizedBox(height: 20),
            // Error message.
            if (errorMessage.isNotEmpty)
              Math.tex(
                errorMessage,
                textStyle: TextStyle(color: Colors.red, fontSize: 16),
              ),
            // Centered outputs: Determinant and A⁻¹ with space between.
            if (determinantText.isNotEmpty || inverseMatrix.isNotEmpty)
              Center(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (determinantText.isNotEmpty)
                      Math.tex(
                        determinantText,
                        textStyle: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    if (determinantText.isNotEmpty && inverseMatrix.isNotEmpty)
                      SizedBox(height: 20),
                    if (inverseMatrix.isNotEmpty)
                      Math.tex(
                        r'A^{-1} = ' + inverseMatrix,
                        textStyle: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
            SizedBox(height: 20),
            // Step-by-Step Calculation Display.
            if (showSteps)
              ExpansionTile(
                title: Math.tex(
                  r'\text{Show Step-by-Step Calculation}',
                  textStyle: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                initiallyExpanded: true,
                children: steps.map((step) {
                  String formattedStep = step.startsWith(r'\')
                      ? step
                      : r'\text{' + step + r'}';
                  return Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: 4.0,
                      horizontal: 8.0,
                    ),
                    child: Math.tex(
                      formattedStep,
                      textStyle: TextStyle(
                        fontSize: 16,
                        fontFamily: 'Courier',
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}
