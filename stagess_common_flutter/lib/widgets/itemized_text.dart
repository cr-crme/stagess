import 'package:flutter/material.dart';

class ItemizedText extends StatelessWidget {
  const ItemizedText(
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
                  Text(
                    '\u2022 ',
                    style: style,
                  ),
                  Flexible(
                      child: Text(
                    elements[i],
                    style: style,
                  )),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
