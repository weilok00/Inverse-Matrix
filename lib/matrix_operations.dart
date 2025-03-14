/// Inverts a 2x2 or 3x3 matrix using Gaussian elimination.
double calculateDeterminant(List<List<double>> matrix, List<String> steps) {
  int n = matrix.length;

  if (n == 2) {
    double a = matrix[0][0];
    double b = matrix[0][1];
    double c = matrix[1][0];
    double d = matrix[1][1];
    double det = a * d - b * c;

    steps.add(
      r'\text{Determinant} = (' + a.toString() + r' \times ' +
          d.toString() + r') - (' + b.toString() + r' \times ' +
          c.toString() + r') = ' + det.toString(),
    );

    return det;
  }

  if (n == 3) {
    double a = matrix[0][0], b = matrix[0][1], c = matrix[0][2];
    double d = matrix[1][0], e = matrix[1][1], f = matrix[1][2];
    double g = matrix[2][0], h = matrix[2][1], i = matrix[2][2];

    double det = a * (e * i - f * h) - 
                 b * (d * i - f * g) + 
                 c * (d * h - e * g);

    steps.add(
      r'\text{Determinant} = ' +
          a.toString() + r'(' + e.toString() + r' \times ' + i.toString() +
          r' - ' + f.toString() + r' \times ' + h.toString() + r') - ' +
          b.toString() + r'(' + d.toString() + r' \times ' + i.toString() +
          r' - ' + f.toString() + r' \times ' + g.toString() + r') + ' +
          c.toString() + r'(' + d.toString() + r' \times ' + h.toString() +
          r' - ' + e.toString() + r' \times ' + g.toString() + r') = ' +
          det.toString(),
    );

    return det;
  }

  return 1; // Placeholder for unsupported sizes.
}

String decimalToFraction(double number) {
  const double tolerance = 1.0E-6;

  // ✅ If number is an integer, return as integer (no fraction)
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

  // ✅ Fully simplify the fraction using the GCD function
  int gcdValue = gcd(numerator, denominator);
  numerator ~/= gcdValue;
  denominator ~/= gcdValue;

  // ✅ If denominator is 1, return as whole number
  if (denominator == 1) {
    return (sign < 0 ? "-" : "") + numerator.toString();
  } else {
    return (sign < 0 ? "-" : "") + r'\frac{' + numerator.toString() + '}{' + denominator.toString() + '}';
  }
}

/// ✅ Function to Compute Greatest Common Divisor (GCD)
int gcd(int a, int b) {
  return (b == 0) ? a.abs() : gcd(b, a % b);
}

String formatMatrixWithFractions(List<List<double>> matrix) {
  String matrixString = r'\begin{bmatrix}';
  for (int i = 0; i < matrix.length; i++) {
    List<String> row = [];
    for (int j = 0; j < matrix[i].length; j++) {
      row.add(decimalToFraction(matrix[i][j])); // ✅ Ensure all fractions are simplified
    }
    matrixString += row.join(' & ');
    if (i < matrix.length - 1) {
      matrixString += r'\\';
    }
  }
  matrixString += r'\end{bmatrix}';
  return matrixString;
}



List<List<double>>? invertMatrix(List<List<double>> matrix, List<String> steps) {
  int n = matrix.length;

  // Ensure only 2x2 or 3x3 matrices are processed.
  if (n != 2 && n != 3) return null;

  List<List<double>> augmented =
      List.generate(n, (_) => List.generate(2 * n, (_) => 0.0));
  
  // Step 1: Augment the matrix with the identity matrix.
  steps.add(r'\text{Apply ERO}');
  for (int i = 0; i < n; i++) {
    for (int j = 0; j < n; j++) {
      augmented[i][j] = matrix[i][j];
    }
    augmented[i][n + i] = 1; // Identity matrix on the right
  }
  steps.add(formatAugmentedMatrix(augmented));

  // Step 2: Apply Gaussian elimination.
  for (int i = 0; i < n; i++) {
    double pivot = augmented[i][i];

    // If the pivot is zero, the matrix is singular (non-invertible).
    if (pivot == 0) return null;

    // Normalize the pivot row.
    for (int j = 0; j < 2 * n; j++) {
      augmented[i][j] /= pivot;
    }
    steps.add(
      r'R_{' + (i + 1).toString() + r'} \rightarrow \frac{1}{' +
          pivot.toString() + r'}\,R_{' + (i + 1).toString() + '}',
    );
    steps.add(formatAugmentedMatrix(augmented));

    // Eliminate the other rows.
    for (int k = 0; k < n; k++) {
      if (k != i) {
        double factor = augmented[k][i];
        for (int j = 0; j < 2 * n; j++) {
          augmented[k][j] -= factor * augmented[i][j];
        }
        steps.add(
          r'R_{' + (k + 1).toString() + r'} \rightarrow R_{' +
              (k + 1).toString() + '} - (' + factor.toString() +
              r')\,R_{' + (i + 1).toString() + '}',
        );
        steps.add(formatAugmentedMatrix(augmented));
      }
    }
  }

  return List.generate(n, (i) => List.generate(n, (j) => augmented[i][j + n]));
}


/// Format augmented matrix as LaTeX with a vertical bar separating original from identity.
String formatAugmentedMatrix(List<List<double>> matrix) {
  int n = matrix.length;
  String colAlignment = "";
  
  for (int i = 0; i < n; i++) colAlignment += "c";
  colAlignment += "|";
  for (int i = 0; i < n; i++) colAlignment += "c";

  String matrixString = r'\left[\begin{array}{' + colAlignment + r'}';
  for (int i = 0; i < matrix.length; i++) {
    List<String> row = [];
    for (int j = 0; j < matrix[i].length; j++) {
      row.add(matrix[i][j].toStringAsFixed(3));
    }
    matrixString += row.join(" & ");
    if (i < matrix.length - 1) {
      matrixString += r'\\';
    }
  }
  matrixString += r'\end{array}\right]';
  return matrixString;
}