import 'package:flutter/material.dart';

class AnimatedExpandingCard extends StatefulWidget {
  const AnimatedExpandingCard({
    super.key,
    required this.header,
    required this.child,
    this.expandingDuration = const Duration(milliseconds: 300),
    this.onTapHeader,
    this.canChangeExpandedState = true,
    this.initialExpandedState = false,
    this.preventTapWhenAnimating = true,
    this.tappingPermitted,
    this.elevation = 10.0,
  });

  final Duration expandingDuration;
  final Widget Function(BuildContext, bool isExpanded) header;
  final Function(bool newState)? onTapHeader;
  final Widget child;
  final bool canChangeExpandedState;
  final bool initialExpandedState;
  final bool preventTapWhenAnimating;
  final Future<bool> Function(bool currentExpandedState)? tappingPermitted;
  final double elevation;

  @override
  State<AnimatedExpandingCard> createState() => _AnimatedExpandingCardState();
}

class _AnimatedExpandingCardState extends State<AnimatedExpandingCard>
    with TickerProviderStateMixin {
  late bool _isExpanded = widget.initialExpandedState;

  late final AnimationController _expandingAnimationController =
      AnimationController(vsync: this, duration: widget.expandingDuration);
  late final Animation<double> _expandingAnimation = CurvedAnimation(
    parent: _expandingAnimationController,
    curve: Curves.fastOutSlowIn,
  );
  late final Tween<double> _expandingTween = Tween(begin: 0, end: 1);

  @override
  void initState() {
    super.initState();
    if (widget.initialExpandedState) {
      _expandingAnimationController.animateTo(1, duration: const Duration());
    }
  }

  bool _isAnimating = false;

  void _trackIsAnimating() async {
    setState(() {
      _isAnimating = true;
    });
    await Future.delayed(widget.expandingDuration);
    setState(() {
      _isAnimating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: widget.elevation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () async {
              if (widget.tappingPermitted != null &&
                  !await widget.tappingPermitted!(_isExpanded)) {
                return;
              }

              if (_isAnimating && widget.preventTapWhenAnimating) {
                return;
              }

              if (widget.canChangeExpandedState) {
                _isExpanded = !_isExpanded;
                _isExpanded
                    ? _expandingAnimationController.forward()
                    : _expandingAnimationController.reverse();
                _trackIsAnimating();
              }
              if (widget.onTapHeader != null) widget.onTapHeader!(_isExpanded);
              setState(() {});
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(child: widget.header(context, _isExpanded)),
                widget.canChangeExpandedState
                    ? Padding(
                        padding: const EdgeInsets.only(left: 12.0, right: 16.0),
                        child: Icon(
                          _isExpanded ? Icons.expand_less : Icons.expand_more,
                          size: 30,
                          color: Colors.grey[700],
                        ),
                      )
                    : const SizedBox.shrink(),
              ],
            ),
          ),
          _expandingAnimation.value == 0 && !_isExpanded
              ? Container()
              : SizeTransition(
                  sizeFactor: _expandingTween.animate(_expandingAnimation),
                  child: widget.child,
                ),
        ],
      ),
    );
  }
}
