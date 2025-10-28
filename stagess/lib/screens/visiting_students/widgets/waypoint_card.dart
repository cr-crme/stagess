import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:stagess/common/extensions/visiting_priorities_extension.dart';
import 'package:stagess_common/models/itineraries/waypoint.dart';

class WaypointCard extends StatelessWidget {
  const WaypointCard({
    super.key,
    required this.name,
    required this.index,
    required this.waypoint,
    this.onTap,
    this.onDelete,
  });

  final String name;
  final int index;
  final Waypoint waypoint;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: key,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                  child: Icon(
                    waypoint.priority.icon,
                    color: waypoint.priority.color,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(color: Colors.black)),
                    waypoint.subtitle == null
                        ? SizedBox.shrink()
                        : Text(
                          waypoint.subtitle!,
                          style: const TextStyle(color: Colors.blueGrey),
                        ),
                  ],
                ),
              ],
            ),
          ),
          Row(
            children: [
              if (kIsWeb)
                MouseRegion(
                  cursor: SystemMouseCursors.grab,
                  child: ReorderableDragStartListener(
                    index: index,
                    child: Icon(Icons.drag_handle, color: Colors.black),
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.delete),
                color: Colors.red,
                onPressed: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
