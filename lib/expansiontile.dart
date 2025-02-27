import 'package:flutter/material.dart';

class MatrixExpansionTile extends StatelessWidget {
  final List<Widget> titleContent;
  final List<Widget> childrenContent;

  const MatrixExpansionTile({
    Key? key,
    required this.titleContent,
    required this.childrenContent,
  }) : super(key: key);


  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.blue[50], // Light blue background
        border: Border.all(
          color: Colors.grey,
          width: 2.0,
          style: BorderStyle.solid,
        ),
        borderRadius: const BorderRadius.all(Radius.circular(10)),
      ),
      child: ExpansionTile(
        title: Column(children: titleContent),
        children: childrenContent,
      ),
    );
  }
}
