import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // Removed const constructor to avoid const-with-nonconst issues.
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
  int matrixSize = 2; // Default is 2x2
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

  /// Generate blank TextFields for the chosen matrix size.
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

  /// Read user input, compute determinant and inverse.
  void _computeInverse() {
    // Read matrix input from controllers.
    List<List<double>> matrix = matrixControllers.map((row) {
      return row.map((controller) {
        return double.tryParse(controller.text) ?? 0.0;
      }).toList();
    }).toList();

    // Calculate determinant (only 2x2 in this example).
    double det = _calculateDeterminant(matrix);
    if (det == 0) {
      setState(() {
        inverseMatrix = "";
        determinantText = "";
        errorMessage = r'\text{The matrix is singular and cannot be inverted.}';
      });
      return;
    }

    // Attempt to invert the matrix.
    List<List<double>>? inv = _invertMatrix(matrix);
    if (inv == null) {
      setState(() {
        errorMessage = r'\text{Error computing the inverse.}';
      });
      return;
    }

    // Format results.
    String formattedMatrix = _formatMatrixWithFractions(inv);
    setState(() {
      errorMessage = "";
      determinantText = r'\text{Determinant: }' + det.toStringAsFixed(3);
      inverseMatrix = formattedMatrix;
      showSteps = true;
    });

    // Scroll down to reveal steps.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
      );
    });
  }

  /// Calculate determinant for a 2x2 matrix (simple example).
  double _calculateDeterminant(List<List<double>> matrix) {
    if (matrixSize == 2) {
      double a = matrix[0][0];
      double b = matrix[0][1];
      double c = matrix[1][0];
      double d = matrix[1][1];
      double det = a * d - b * c;
      steps.add(
        r'\text{Determinant} = (' +
            a.toString() +
            r' \times ' +
            d.toString() +
            r') - (' +
            b.toString() +
            r' \times ' +
            c.toString() +
            r') = ' +
            det.toString(),
      );
      return det;
    }
    // Placeholder for bigger matrices.
    return 1;
  }

  /// Invert a 2x2 matrix using Gaussian elimination.
  List<List<double>>? _invertMatrix(List<List<double>> matrix) {
    int n = matrix.length;
    // Create an augmented matrix of size n x 2n.
    List<List<double>> augmented =
        List.generate(n, (_) => List.generate(2 * n, (_) => 0.0));

    // Step 1: Augment with identity.
    steps.add(r'\text{Step 1: Augment the matrix with the identity matrix.}');
    for (int i = 0; i < n; i++) {
      for (int j = 0; j < n; j++) {
        augmented[i][j] = matrix[i][j];
      }
      augmented[i][n + i] = 1; // Identity on the right side
    }
    steps.add(_formatAugmentedMatrix(augmented));

    // Step 2: Gaussian elimination.
    for (int i = 0; i < n; i++) {
      double pivot = augmented[i][i];
      if (pivot == 0) return null; // Non-invertible if pivot is zero.

      // Normalize pivot row.
      for (int j = 0; j < 2 * n; j++) {
        augmented[i][j] /= pivot;
      }
      // Add a row-operation step, e.g. R1 -> 1/(pivot) R1
      steps.add(
        r'R_{' +
            (i + 1).toString() +
            r'} \rightarrow \frac{1}{' +
            pivot.toString() +
            r'}\,R_{' +
            (i + 1).toString() +
            '}',
      );
      steps.add(_formatAugmentedMatrix(augmented));

      // Eliminate in other rows.
      for (int k = 0; k < n; k++) {
        if (k != i) {
          double factor = augmented[k][i];
          for (int j = 0; j < 2 * n; j++) {
            augmented[k][j] -= factor * augmented[i][j];
          }
          // Add elimination step, e.g. R2 -> R2 - (factor) R1
          steps.add(
            r'R_{' +
                (k + 1).toString() +
                r'} \rightarrow R_{' +
                (k + 1).toString() +
                '} - (' +
                factor.toString() +
                r')\,R_{' +
                (i + 1).toString() +
                '}',
          );
          steps.add(_formatAugmentedMatrix(augmented));
        }
      }
    }

    steps.add(r'\text{Final step: Extract the inverse matrix from the augmented matrix.}');
    // Extract the inverse (right half of the augmented matrix).
    return List.generate(n, (i) => List.generate(n, (j) => augmented[i][j + n]));
  }

  /// Convert decimal to fraction in LaTeX.
  String _decimalToFraction(double number) {
    const double tolerance = 1.0E-6;
    // If integer, just return it.
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
    numerator ~/= gcd;
    denominator ~/= gcd;

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

  /// Greatest Common Divisor
  int _gcd(int a, int b) => b == 0 ? a.abs() : _gcd(b, a % b);

  /// Format a matrix as LaTeX pmatrix.
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

  /// Format augmented matrix as LaTeX with a vertical bar separating original from identity.
  String _formatAugmentedMatrix(List<List<double>> matrix) {
    int n = matrixSize;
    String colAlignment = "";
    // 'c' for each column in the original matrix.
    for (int i = 0; i < n; i++) {
      colAlignment += "c";
    }
    // Add vertical bar
    colAlignment += "|";
    // 'c' for each column in the identity/inverse portion.
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

  /// Format the user-input matrix A as LaTeX pmatrix.
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
          textStyle: const TextStyle(fontSize: 20),
        ),
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dropdown to select matrix size
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
            const SizedBox(height: 20),
            // Matrix input fields
            Column(
              children: List.generate(matrixSize, (i) {
                return Row(
                  children: List.generate(matrixSize, (j) {
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: TextField(
                          controller: matrixControllers[i][j],
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    );
                  }),
                );
              }),
            ),
            const SizedBox(height: 20),
            // Display input matrix A
            Math.tex(
              r'A = ' + _formatInputMatrixAsLatex(),
              textStyle: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            // Compute Inverse Button
            ElevatedButton(
              onPressed: _computeInverse,
              child: Math.tex(
                r'\text{Compute Inverse}',
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 20),
            // Error message if singular
            if (errorMessage.isNotEmpty)
              Math.tex(
                errorMessage,
                textStyle: const TextStyle(color: Colors.red, fontSize: 16),
              ),
            // Determinant and Inverse outputs (centered with space between)
            if (determinantText.isNotEmpty || inverseMatrix.isNotEmpty)
              Center(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (determinantText.isNotEmpty)
                      Math.tex(
                        determinantText,
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    if (determinantText.isNotEmpty && inverseMatrix.isNotEmpty)
                      const SizedBox(height: 20),
                    if (inverseMatrix.isNotEmpty)
                      Math.tex(
                        r'A^{-1} = ' + inverseMatrix,
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 20),
            // Step-by-Step Calculation Display
            if (showSteps)
              ExpansionTile(
                title: Math.tex(
                  r'\text{Show Step-by-Step Calculation}',
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                initiallyExpanded: true,
                children: steps.map((step) {
                  // If the step already begins with a backslash or 'R_{', treat it as LaTeX
                  // Otherwise, wrap it in \text{} for plain text.
                  final formattedStep = (step.startsWith(r'\') || step.startsWith('R_'))
                      ? step
                      : r'\text{' + step + r'}';

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 4.0,
                      horizontal: 8.0,
                    ),
                    child: Math.tex(
                      formattedStep,
                      textStyle: const TextStyle(
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
