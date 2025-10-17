import 'package:flutter/material.dart';
import 'package:stagess_common_flutter/helpers/form_service.dart';
import 'package:url_launcher/url_launcher.dart';

class EmailListTile extends StatefulWidget {
  const EmailListTile({
    super.key,
    this.title = 'Courriel',
    this.titleStyle,
    this.contentStyle,
    this.initialValue,
    this.icon = Icons.mail,
    this.onSaved,
    this.isMandatory = false,
    this.enabled = true,
    this.canMail = true,
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
  final bool canMail;

  @override
  State<EmailListTile> createState() => _EmailListTileState();
}

class _EmailListTileState extends State<EmailListTile> {
  late final _emailController = widget.controller ?? TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null) {
      _emailController.text = widget.initialValue.toString();
    }
  }

  // coverage:ignore-start
  _email() async =>
      await launchUrl(Uri.parse('mailto:${_emailController.text}'));
  // coverage:ignore-end

  @override
  void didUpdateWidget(covariant EmailListTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled) return;

    if (widget.controller != null &&
        _emailController.text != widget.controller?.text) {
      _emailController.text = widget.initialValue.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.enabled || _emailController.text == '' ? null : _email,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(
              icon: const SizedBox(width: 30),
              labelText:
                  '${widget.isMandatory && widget.enabled ? '* ' : ''}${widget.title}',
              labelStyle:
                  widget.titleStyle ??
                  (widget.enabled
                      ? null
                      : const TextStyle(color: Colors.black)),
              disabledBorder: InputBorder.none,
            ),
            style:
                widget.contentStyle ??
                (widget.enabled ? null : const TextStyle(color: Colors.black)),
            validator: (value) {
              if (!widget.enabled) return null;

              if (!widget.isMandatory && (value == '' || value == null)) {
                return null;
              }

              return FormService.emailValidator(value);
            },
            enabled: widget.enabled,
            onSaved: widget.onSaved,
            keyboardType: TextInputType.emailAddress,
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Icon(
              widget.icon,
              color:
                  widget.canMail ? Theme.of(context).primaryColor : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
