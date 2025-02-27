import 'package:flutter/material.dart';

class MatrixInput extends StatelessWidget {
  final int matrixSize;
  final List<List<TextEditingController>> matrixControllers;
  final Function(int) onMatrixSizeChanged;
  final VoidCallback onComputeInverse; // ✅ Callback for the button

  const MatrixInput({
    required this.matrixSize,
    required this.matrixControllers,
    required this.onMatrixSizeChanged,
    required this.onComputeInverse, // ✅ Pass function to trigger inverse computation
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
              onMatrixSizeChanged(value);
            }
          },
        ),
        const SizedBox(height: 20),
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

        //  "Compute Inverse" Button Added
        ElevatedButton(
          onPressed: onComputeInverse, //  Calls the function passed from parent
          child: const Text(
            "Inverse",
            style: TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }
}
