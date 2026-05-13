import 'package:flutter/material.dart';

class Search extends StatelessWidget implements PreferredSizeWidget {
  const Search({
    super.key,
    required this.controller,
  });

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Card(
        elevation: 0,
        child: ListTile(
          leading: const Icon(Icons.search),
          title: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Rechercher',
              border: InputBorder.none,
            ),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () => controller.text = '',
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(72);
}
