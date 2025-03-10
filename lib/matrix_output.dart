
import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'expansiontile.dart';
import 'matrix_operations.dart'; // ✅ Ensure matrix_operations.dart is imported

class MatrixOutput extends StatelessWidget {
  final String inputMatrix;
  final String determinantText;
  final String inverseMatrix;
  final String errorMessage;
  final bool showSteps;
  final List<String> steps;

  const MatrixOutput({
    required this.inputMatrix,
    required this.determinantText,
    required this.inverseMatrix,
    required this.errorMessage,
    required this.showSteps,
    required this.steps,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        //  Show User Input Matrix A
       if (inputMatrix.isNotEmpty)
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Math.tex(
            r'A = ' + inputMatrix, // ✅ Use the correctly formatted input matrix
            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 10),

        // ✅ Show Error Message if Matrix is Singular
        if (errorMessage.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Math.tex(
              errorMessage,
              textStyle: const TextStyle(color: Colors.red, fontSize: 16),
            ),
          ),
        const SizedBox(height: 10),

        // ✅ Convert determinant & inverse matrix values into fractions before display
        if (determinantText.isNotEmpty || inverseMatrix.isNotEmpty)
          MatrixExpansionTile(
            titleContent: [
              Math.tex(
                r'\text{Answer}',
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
            childrenContent: [
              if (determinantText.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Math.tex(
                    r'\text{Determinant: }' + decimalToFraction(double.tryParse(determinantText) ?? 0), // ✅ Convert determinant
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                ),
                const Divider(),
              ],
              if (inverseMatrix.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Math.tex(
                    r'A^{-1} = ' + inverseMatrix, // ✅ Already formatted as a fraction
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                ),
            ],
          ),
        const SizedBox(height: 10),

        // Step-by-Step Calculation Section with Fraction Formatting
        if (showSteps)
        MatrixExpansionTile(
          titleContent: [
            Math.tex(
              r'\text{Step-by-Step Calculation}',
              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
          childrenContent: steps.map((step) {
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Math.tex(_replaceDecimalsWithFractions(step), // ✅ Ensure decimals are replaced
                  textStyle: const TextStyle(fontSize: 16)),
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// ✅ Convert all decimal numbers in step-by-step calculations to fractions
String _replaceDecimalsWithFractions(String step) {
  return step.replaceAllMapped(RegExp(r'[-+]?\d*\.\d+'), (match) {
    double number = double.tryParse(match.group(0) ?? "0") ?? 0;
    return decimalToFraction(number); // ✅ Converts to **simplified fraction**
  });
}
