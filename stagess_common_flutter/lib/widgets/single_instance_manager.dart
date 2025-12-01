import 'dart:js_interop';

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

class SingleInstanceManager extends StatefulWidget {
  const SingleInstanceManager(
      {super.key, required this.child, required this.isNotAllowedChild});

  final Widget child;
  final Widget isNotAllowedChild;

  @override
  State<SingleInstanceManager> createState() => _SingleInstanceManagerState();
}

class _SingleInstanceManagerState extends State<SingleInstanceManager> {
  bool _isInstanceValid = true;

  void _preventMultipleTabs() {
    final channel = web.BroadcastChannel('stagess');
    // Listen for tab-open broadcasts
    channel.onmessage = ((web.MessageEvent event) {
      if (event.data.dartify() == 'new instance') {
        setState(() => _isInstanceValid = false);
      }
    }).toJS;

    channel.postMessage('new instance'.toJS);
  }

  @override
  void initState() {
    super.initState();
    _preventMultipleTabs();
  }

  @override
  Widget build(BuildContext context) {
    return _isInstanceValid ? widget.child : widget.isNotAllowedChild;
  }
}
