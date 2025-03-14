import sympy as sp
from sympy.parsing.sympy_parser import (
    parse_expr, standard_transformations, implicit_multiplication_application
)
from flask import Flask, request, jsonify
import re

app = Flask(__name__)

# Enable implicit multiplication, e.g., 2x = 2*x
transformations = standard_transformations + (implicit_multiplication_application,)

def extract_symbols(matrix_data):
    """Extract unique symbols from the input matrix."""
    symbol_pattern = r'[a-zA-Z]'
    symbols = set()

    for row in matrix_data:
        for value in row:
            if isinstance(value, str):
                symbols.update(re.findall(symbol_pattern, value))

    # Declare symbols globally
    return {symbol: sp.Symbol(symbol) for symbol in symbols}

def parse_matrix(matrix_data):
    """Parse matrix data with dynamic symbol recognition."""
    local_dict = extract_symbols(matrix_data)

    try:
        matrix = sp.Matrix([
            [
                parse_expr(str(value), transformations=transformations, local_dict=local_dict)
                for value in row
            ]
            for row in matrix_data
        ])
        return matrix
    except Exception as e:
        raise ValueError(f"Invalid input detected: {e}")

def format_augmented_matrix(matrix):
    """Format the augmented matrix for LaTeX with a single vertical separator."""
    left = matrix[:, :matrix.shape[0]]
    right = matrix[:, matrix.shape[0]:]

    rows = []
    for i in range(matrix.shape[0]):
        left_row = ' & '.join([sp.latex(left[i, j]) for j in range(left.shape[1])])
        right_row = ' & '.join([sp.latex(right[i, j]) for j in range(right.shape[1])])
        rows.append(f"{left_row} & {right_row}")

    latex_matrix = r'\left[ \begin{array}{' + 'c' * left.shape[1] + '|' + 'c' * right.shape[1] + '}'
    latex_matrix += r'\\'.join(rows)
    latex_matrix += r'\end{array} \right]'
    return latex_matrix

def matrix_inversion_steps(matrix):
    """Compute inverse with detailed step-by-step calculations showing both affected and unaffected values."""
    steps = []
    n = matrix.shape[0]
    identity = sp.eye(n)
    augmented = matrix.row_join(identity)

    # Initial augmented matrix display
    steps.append(r"\quad \text{Apply ERO}")
    steps.append(format_augmented_matrix(augmented))

    # Gaussian elimination process
    for i in range(n):
        pivot = augmented[i, i]
        if pivot != 1:
            detailed_matrix = []
            for idx in range(n):
                row = []
                for j in range(augmented.shape[1]):
                    if idx == i:
                        # Show calculation for the pivot row
                        row.append(f"\\frac{{1}}{{{sp.latex(pivot)}}}({sp.latex(augmented[idx, j])})")
                    else:
                        # Unaffected rows are displayed as-is
                        row.append(sp.latex(augmented[idx, j]))
                detailed_matrix.append(' & '.join(row))

            # Simplify the pivot row
            simplified_matrix = augmented.copy()
            simplified_matrix.row_op(i, lambda v, _: sp.simplify(v / pivot))

            # Add the step
            steps.append(rf"R_{{{i + 1}}} \to \frac{{1}}{{{sp.latex(pivot)}}} R_{{{i + 1}}}")
            steps.append(
                r'\left[ \begin{array}{' + 'c' * n + '|' + 'c' * n + '}' +
                r'\\'.join(detailed_matrix) +
                r'\end{array} \right] = ' +
                format_augmented_matrix(simplified_matrix)
            )

            augmented = simplified_matrix

        # Eliminate other rows
        for j in range(n):
            if i != j:
                factor = augmented[j, i]
                if factor != 0:
                    detailed_matrix = []
                    for idx in range(n):
                        row = []
                        for k in range(augmented.shape[1]):
                            if idx == j:
                                # Display detailed calculation for affected row
                                row.append(f"({sp.latex(augmented[j, k])})-({sp.latex(factor)}*{sp.latex(augmented[i, k])})")
                            else:
                                # Unaffected rows displayed as-is
                                row.append(sp.latex(augmented[idx, k]))
                        detailed_matrix.append(' & '.join(row))

                    # Simplify the affected row
                    simplified_matrix = augmented.copy()
                    simplified_matrix.row_op(j, lambda v, k: sp.simplify(v - factor * augmented[i, k]))

                    # Add the elimination step
                    steps.append(rf"R_{{{j + 1}}} \to R_{{{j + 1}}} - ({sp.latex(factor)}) R_{{{i + 1}}}")
                    steps.append(
                        r'\left[ \begin{array}{' + 'c' * n + '|' + 'c' * n + '}' +
                        r'\\'.join(detailed_matrix) +
                        r'\end{array} \right] = ' +
                        format_augmented_matrix(simplified_matrix)
                    )
                    augmented = simplified_matrix

    inverse = augmented[:, n:]
    return inverse, steps

@app.route('/matrix_inverse', methods=['POST'])
def matrix_inverse():
    """Compute the inverse, determinant, and detailed step-by-step calculations."""
    try:
        data = request.get_json()
        matrix_data = data.get('matrix')

        if not matrix_data:
            return jsonify({"error": "No matrix provided"}), 400

        matrix = parse_matrix(matrix_data)
        determinant = matrix.det()

        if determinant == 0:
            return jsonify({"error": "Matrix is singular and cannot be inverted"}), 400

        inverse_matrix, steps = matrix_inversion_steps(matrix)
        inverse_matrix = inverse_matrix.applyfunc(sp.simplify)

        inverse_as_latex = [[sp.latex(entry) for entry in row] for row in inverse_matrix.tolist()]
        determinant_as_latex = sp.latex(sp.simplify(determinant))

        return jsonify({
            "inverse": inverse_as_latex,
            "determinant": determinant_as_latex,
            "steps": steps
        })

    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    app.run(debug=True)
