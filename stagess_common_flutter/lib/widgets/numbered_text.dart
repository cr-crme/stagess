import 'package:flutter/material.dart';

class NumberedText extends StatelessWidget {
  const NumberedText(
    this.elements, {
    super.key,
    this.interline = 0,
    this.style,
  });

  final List<String> elements;
  final TextStyle? style;
  final double interline;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: elements
          .asMap()
          .keys
          .map(
            (i) => Padding(
              padding: EdgeInsets.only(top: i != 0 ? interline : 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${i + 1}. ', style: style),
                  SizedBox(width: 4.0),
                  Flexible(child: Text(elements[i], style: style)),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
