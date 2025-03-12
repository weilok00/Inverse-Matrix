import sympy as sp
from sympy.parsing.sympy_parser import parse_expr, standard_transformations, implicit_multiplication_application
from flask import Flask, request, jsonify

app = Flask(__name__)

def parse_matrix(matrix_data):
    """Converts JSON matrix data into a SymPy matrix with symbolic support."""
    if not matrix_data:
        return None

    transformations = standard_transformations + (implicit_multiplication_application,)

    matrix = sp.Matrix([
        [
            parse_expr(value, transformations=transformations) if isinstance(value, str) else value
            for value in row
        ]
        for row in matrix_data
    ])
    return matrix

def format_augmented_matrix(matrix):
    """Formats the augmented matrix using LaTeX with a clean vertical separator."""
    left = matrix[:, :matrix.shape[0]]
    right = matrix[:, matrix.shape[0]:]

    rows = []
    for i in range(matrix.shape[0]):
        left_row = ' & '.join([sp.latex(left[i, j]) for j in range(left.shape[1])])
        right_row = ' & '.join([sp.latex(right[i, j]) for j in range(right.shape[1])])
        rows.append(f"{left_row} & {right_row}")

    # Use c|c to specify a single vertical separator
    latex_matrix = r'\left[ \begin{array}{' + 'c' * left.shape[1] + '|' + 'c' * right.shape[1] + '}\n'
    latex_matrix += r'\\'.join(rows)
    latex_matrix += r'\end{array} \right]'
    return latex_matrix

def matrix_inversion_steps(matrix):
    """Calculate inverse and capture steps with vertical separator."""
    steps = []
    n = matrix.shape[0]

    # Augment with identity matrix
    identity = sp.eye(n)
    augmented = matrix.row_join(identity)
    steps.append(format_augmented_matrix(augmented))

    # Perform Gaussian elimination
    for i in range(n):
        # Normalize the pivot row
        factor = augmented[i, i]
        if factor != 0:
            augmented.row_op(i, lambda v, _: sp.simplify(v / factor))
            steps.append(rf"R_{{{i + 1}}} \to \frac{{1}}{{{sp.latex(factor)}}} R_{{{i + 1}}}")
            steps.append(format_augmented_matrix(augmented))

        # Eliminate other rows
        for j in range(n):
            if i != j:
                factor = augmented[j, i]
                augmented.row_op(j, lambda v, k: sp.simplify(v - factor * augmented[i, k]))
                steps.append(rf"R_{{{j + 1}}} \to R_{{{j + 1}}} - ({sp.latex(factor)})R_{{{i + 1}}}")
                steps.append(format_augmented_matrix(augmented))

    inverse = augmented[:, n:]
    return inverse, steps

@app.route('/matrix_inverse', methods=['POST'])
def matrix_inverse():
    """Compute the inverse, determinant, and step-by-step calculations."""
    try:
        data = request.get_json()
        matrix_data = data.get('matrix')

        if not matrix_data:
            return jsonify({"error": "No matrix provided"}), 400

        matrix = parse_matrix(matrix_data)
        determinant = matrix.det()

        if determinant == 0:
            return jsonify({"error": "Matrix is singular and cannot be inverted"}), 400

        # Perform inversion with steps
        inverse_matrix, steps = matrix_inversion_steps(matrix)

        # Simplify the inverse matrix
        inverse_matrix = inverse_matrix.applyfunc(sp.simplify)

        # Convert outputs to LaTeX
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
