import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class WebSiteListTile extends StatefulWidget {
  const WebSiteListTile({
    super.key,
    this.title = 'Site web',
    this.titleStyle,
    this.contentStyle,
    this.initialValue,
    this.icon = Icons.link,
    this.onSaved,
    this.isMandatory = false,
    this.enabled = true,
    this.canVisit = true,
    this.controller,
  });

  final String title;
  final TextStyle? titleStyle;
  final TextStyle? contentStyle;
  final String? initialValue;
  final IconData icon;
  final Function(String?)? onSaved;
  final bool isMandatory;
  final bool enabled;
  final TextEditingController? controller;
  final bool canVisit;

  @override
  State<WebSiteListTile> createState() => _WebSiteListTileState();
}

class _WebSiteListTileState extends State<WebSiteListTile> {
  late final _websiteController = widget.controller ?? TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null) {
      _websiteController.text = widget.initialValue.toString();
      _addHttp(_websiteController.text);
    }
  }

  // coverage:ignore-start
  _visit() async => await launchUrl(Uri.parse(_websiteController.text));
  // coverage:ignore-end

  void _addHttp(String value) {
    if (value == '') return;

    if (!value.startsWith('http:') && !value.startsWith('https:')) {
      _websiteController.text = 'https://$value';
    }
    if (widget.onSaved != null) widget.onSaved!(_websiteController.text);
  }

  @override
  void didUpdateWidget(covariant WebSiteListTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != null &&
        _websiteController.text != widget.controller?.text) {
      _websiteController.text = widget.initialValue.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (hasFocus) {
        if (!hasFocus) _addHttp(_websiteController.text);
      },
      child: InkWell(
        onTap:
            !widget.canVisit || widget.enabled || _websiteController.text == ''
                ? null
                : _visit,
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            TextFormField(
              controller: _websiteController,
              decoration: InputDecoration(
                icon: const SizedBox(width: 30),
                labelText: '${widget.isMandatory ? '* ' : ''}${widget.title}',
                labelStyle:
                    widget.titleStyle ?? const TextStyle(color: Colors.black),
                disabledBorder: InputBorder.none,
              ),
              style:
                  widget.contentStyle ?? const TextStyle(color: Colors.black),
              enabled: widget.enabled,
              onSaved: (value) => _addHttp(value!),
              keyboardType: TextInputType.url,
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Icon(
                widget.icon,
                color:
                    widget.canVisit
                        ? Theme.of(context).primaryColor
                        : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
