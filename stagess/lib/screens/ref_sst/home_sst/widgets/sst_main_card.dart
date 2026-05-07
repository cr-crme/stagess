import 'package:flutter/material.dart';
import 'package:stagess_common_flutter/widgets/sub_title.dart';

class SstMainCard extends StatelessWidget {
  const SstMainCard({
    super.key,
    required this.title,
    required this.content,
    required this.onTap,
  });

  final String title;
  final Widget content;
  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 10,
      child: Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 12.0),
        child: ListTile(
          onTap: onTap,
          title: SubTitle(title, left: 0, top: 0),
          subtitle: content,
          subtitleTextStyle: Theme.of(context).textTheme.titleSmall,
          textColor: Colors.black,
        ),
      ),
    );
  }
}
