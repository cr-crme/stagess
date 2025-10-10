import 'package:flutter/material.dart';

class StickyHeadExpansionPanel {
  final bool isExpanded;
  final bool canTapOnHeader;
  final Widget Function(BuildContext context, Key key, bool isExpanded)
  headerBuilder;
  final Widget body;

  StickyHeadExpansionPanel({
    required this.headerBuilder,
    required this.isExpanded,
    this.canTapOnHeader = false,
    required this.body,
  });
}

class StickyHeadExpansionPanelList extends StatefulWidget {
  const StickyHeadExpansionPanelList({
    super.key,
    required this.outerScrollController,
    required this.headerTarget,
    this.scrollHeight = 80,
    required this.expansionCallback,
    this.elevation,
    required this.children,
  });

  final double? elevation;
  final ScrollController outerScrollController;
  final double headerTarget;
  final double scrollHeight;
  final ExpansionPanelCallback expansionCallback;
  final List<StickyHeadExpansionPanel> children;

  @override
  State<StickyHeadExpansionPanelList> createState() =>
      _StickyHeadExpansionPanelListState();
}

class _StickyHeadExpansionPanelListState
    extends State<StickyHeadExpansionPanelList> {
  final _headerKey = GlobalKey();

  final ScrollController _innerScrollController = ScrollController();

  double get _getHeaderPosition {
    final box = _headerKey.currentContext?.findRenderObject() as RenderBox?;
    return box?.localToGlobal(Offset.zero).dy ?? 0;
  }

  Future<void> _handleScroll() async {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();

    widget.outerScrollController.addListener(_handleScroll);
    _innerScrollController.addListener(_handleScroll);
  }

  @override
  void didUpdateWidget(covariant StickyHeadExpansionPanelList oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Make sure not to add multiple listeners
    widget.outerScrollController.removeListener(_handleScroll);
    _innerScrollController.removeListener(_handleScroll);

    // Add listeners to the scroll controllers
    widget.outerScrollController.addListener(_handleScroll);
    _innerScrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    widget.outerScrollController.removeListener(_handleScroll);
    _innerScrollController.removeListener(_handleScroll);
    _innerScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isHeaderAtTop =
        (_getHeaderPosition >
            widget.headerTarget - (widget.scrollHeight / 2)) &&
        (_getHeaderPosition < widget.headerTarget + (widget.scrollHeight / 2));
    debugPrint(
      '${widget.headerTarget - (widget.scrollHeight / 2)} < $_getHeaderPosition < ${widget.headerTarget + (widget.scrollHeight / 2)}',
    );

    return ExpansionPanelList(
      elevation: widget.elevation ?? 2,
      expansionCallback: widget.expansionCallback,
      children:
          widget.children
              .map(
                (sticky) => ExpansionPanel(
                  headerBuilder:
                      (context, isExpanded) =>
                          sticky.headerBuilder(context, _headerKey, isExpanded),
                  canTapOnHeader: sticky.canTapOnHeader,
                  isExpanded: sticky.isExpanded,
                  body: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight:
                          MediaQuery.of(context).size.height -
                          widget.headerTarget,
                    ),
                    child: SingleChildScrollView(
                      controller: _innerScrollController,
                      physics:
                          isHeaderAtTop
                              ? const FixedScrollPhysics()
                              : const NeverScrollableScrollPhysics(),
                      child: sticky.body,
                    ),
                  ),
                ),
              )
              .toList(),
    );
  }
}

/// Custom physics that limits scroll delta
class FixedScrollPhysics extends ClampingScrollPhysics {
  const FixedScrollPhysics({super.parent});

  @override
  FixedScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return FixedScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    // Adjust offset so it is max out at 80 pixels per scroll
    const maxScroll = 80.0;
    return super.applyPhysicsToUserOffset(
      position,
      offset.clamp(-maxScroll, maxScroll),
    );
  }
}
