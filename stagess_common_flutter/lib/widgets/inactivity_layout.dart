import 'dart:async';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:stagess_common_flutter/providers/backend_list_provided.dart';

final _logger = Logger('InactivityLayout');

class InactivityLayout extends StatefulWidget {
  const InactivityLayout({
    super.key,
    required this.navigatorKey,
    this.timeout = const Duration(minutes: 15),
    this.gracePeriod = const Duration(seconds: 60),
    required this.onTimedout,
    required this.showGracePeriod,
    required this.child,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final Duration timeout;
  final Duration gracePeriod;
  final Future<bool> Function(BuildContext) onTimedout;
  final Future<bool> Function(BuildContext) showGracePeriod;
  final Widget child;

  @override
  State<InactivityLayout> createState() => _InactivityLayoutState();
}

class _InactivityLayoutState extends State<InactivityLayout> {
  late final _InactivityService _inactivityService = _InactivityService._(
    duration: widget.timeout,
    onTimeout: () async {
      _logger.info(
        'User has been inactive for ${widget.timeout.inMinutes} minutes. Signing out.',
      );

      final context = widget.navigatorKey.currentContext!;
      final shouldShowGracePeriod = await widget.showGracePeriod(context);
      if (!context.mounted) return;

      final hasTimedout =
          shouldShowGracePeriod
              ? (await showDialog<bool>(
                    barrierDismissible: false,
                    context: context,
                    builder:
                        (context) =>
                            _TimingOutDialog(gracePeriod: widget.gracePeriod),
                  ) ??
                  true)
              : true;
      if (!hasTimedout || !context.mounted) {
        _inactivityService.userHasInteracted();
        return;
      }

      // If the reconnecting dialog is showing, close it first
      if (_isShowingWaitForReconnexionDialog) {
        Navigator.of(context).pop();
        _isShowingWaitForReconnexionDialog = false;
      }

      final restartTimer = await widget.onTimedout(context);
      if (restartTimer) _inactivityService.userHasInteracted();
    },
  );

  @override
  void dispose() {
    super.dispose();
    _inactivityService.dispose();
  }

  bool _isShowingWaitForReconnexionDialog = false;
  void _onConnexionStatusChanged(isConnected) async {
    if (isConnected) {
      if (_isShowingWaitForReconnexionDialog) {
        Navigator.of(widget.navigatorKey.currentContext!).pop();
      }
      _isShowingWaitForReconnexionDialog = false;
      return;
    }

    if (_isShowingWaitForReconnexionDialog) return;
    _isShowingWaitForReconnexionDialog = true;
    await showDialog(
      context: widget.navigatorKey.currentContext!,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: Text('Connexion perdue'),
            content: Text(
              'La connexion au serveur a été perdue. Nous tentons de nous reconnecter.',
            ),
          ),
    );
    _isShowingWaitForReconnexionDialog = false;
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _inactivityService.userHasInteracted(),
      child: Builder(
        builder: (context) {
          BackendListProvided.onConnexionStatusChanged.listen(
            _onConnexionStatusChanged,
          );

          return widget.child;
        },
      ),
    );
  }
}

class _InactivityService {
  Timer? _timer;
  final Duration duration;
  final VoidCallback onTimeout;

  ///
  /// Initialize the InactivityService singleton.
  /// [duration] is the duration of inactivity before calling [onTimeout].
  /// [onTimeout] is the callback to call when the user has been inactive for [duration].
  /// Throws an exception if the service is already initialized.
  _InactivityService._({required this.duration, required this.onTimeout}) {
    _startTimer();
  }

  ///
  /// Call this method whenever the user interacts with the app to reset the inactivity timer.
  ///
  void userHasInteracted() {
    _startTimer();
  }

  ///
  /// Dispose the service and cancel the timer.
  ///
  void dispose() {
    _timer?.cancel();
  }

  ///
  /// Start or restart the inactivity timer.
  ///
  void _startTimer() {
    debugPrint('Inactivity timer started for ${duration.inSeconds} seconds.');
    _timer?.cancel();
    _timer = Timer(duration, _hasTimedOut);
  }

  ///
  /// Called when the inactivity timer has timed out.
  ///
  void _hasTimedOut() {
    _timer?.cancel();
    onTimeout();
  }
}

class _TimingOutDialog extends StatefulWidget {
  const _TimingOutDialog({required this.gracePeriod});

  final Duration gracePeriod;

  @override
  State<_TimingOutDialog> createState() => _TimingOutDialogState();
}

class _TimingOutDialogState extends State<_TimingOutDialog> {
  late int _remainingSeconds;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.gracePeriod.inSeconds;
    _startCountdown();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 1) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _hasTimedOut();
      }
    });
  }

  void _hasTimedOut() {
    _countdownTimer?.cancel();
    Navigator.of(context).pop(true);
  }

  void _cancelTimeout() {
    _countdownTimer?.cancel();
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Déconnexion imminente'),
      content: Text(
        'Vous serez déconnecté dans $_remainingSeconds ${_remainingSeconds == 1 ? 'seconde' : 'secondes'} en raison d\'une période d\'inactivité.\n\n'
        'Appuyez sur OK pour rester connecté.',
      ),
      actions: [TextButton(onPressed: _cancelTimeout, child: const Text('OK'))],
    );
  }
}
