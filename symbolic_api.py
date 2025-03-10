import sympy as sp
from flask import Flask, request, jsonify

app = Flask(__name__)

def parse_matrix(matrix_data):
    """Converts JSON matrix data into a SymPy matrix with symbolic support."""
    if not matrix_data:
        return None

    symbols = set()
    for row in matrix_data:
        for value in row:
            if isinstance(value, str):  
                symbols.add(value)

    sym_vars = {symbol: sp.symbols(symbol) for symbol in symbols}

    matrix = sp.Matrix([
        [sp.sympify(value, locals=sym_vars) if isinstance(value, str) else value for value in row]
        for row in matrix_data
    ])
    return matrix

@app.route('/matrix_inverse', methods=['POST'])
def matrix_inverse():
    """ Compute the inverse of a symbolic matrix """
    try:
        data = request.get_json()
        matrix_data = data.get('matrix')

        if not matrix_data:
            return jsonify({"error": "No matrix provided"}), 400

        matrix = parse_matrix(matrix_data)

        if matrix.det() == 0:
            return jsonify({"error": "Matrix is singular and cannot be inverted"}), 400

        inverse_matrix = matrix.inv()

        return jsonify({"inverse": str(inverse_matrix.tolist())})

    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    app.run(debug=True)
