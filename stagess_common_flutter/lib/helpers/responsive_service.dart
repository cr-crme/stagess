import 'package:flutter/material.dart';

enum ScreenSize {
  small,
  medium,
  large;

  static ScreenSize fromWidth(double width) {
    if (width < ResponsiveService.smallScreenWidth) {
      return ScreenSize.small;
    } else if (width >= ResponsiveService.smallScreenWidth &&
        width < ResponsiveService.largeScreenWidth) {
      return ScreenSize.medium;
    } else {
      return ScreenSize.large;
    }
  }

  bool operator <(ScreenSize other) {
    return index < other.index;
  }

  bool operator >(ScreenSize other) {
    return index > other.index;
  }

  bool operator <=(ScreenSize other) {
    return index <= other.index;
  }

  bool operator >=(ScreenSize other) {
    return index >= other.index;
  }
}

class ResponsiveService {
  // Define the breakpoints
  static final smallScreenWidth = 600.0;
  static final largeScreenWidth = 1024.0;
  static final maxBodyWidth = 800.0;

  // Method to check if the current screen size is mobile
  static ScreenSize getScreenSize(BuildContext context) {
    return ScreenSize.fromWidth(MediaQuery.of(context).size.width);
  }

  static void popOf(BuildContext context) {
    if (ResponsiveService.getScreenSize(context) != ScreenSize.small) return;
    if (!Navigator.canPop(context)) return;

    Navigator.of(context).pop();
  }

  static Scaffold scaffoldOf(
    BuildContext context, {
    PreferredSizeWidget? appBar,
    Widget? smallDrawer,
    Widget? mediumDrawer,
    Widget? largeDrawer,
    required Widget body,
  }) {
    final screenSize = ResponsiveService.getScreenSize(context);

    return Scaffold(
      appBar: switch (screenSize) {
        ScreenSize.small => appBar,
        _ => null,
      },
      drawer: switch (screenSize) {
        ScreenSize.small => smallDrawer,
        _ => null,
      },
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          switch (screenSize) {
            ScreenSize.small => SizedBox.shrink(),
            ScreenSize.medium => mediumDrawer ?? SizedBox.shrink(),
            ScreenSize.large => largeDrawer ?? SizedBox.shrink(),
          },
          Expanded(
            child: Scaffold(
              appBar: switch (screenSize) {
                ScreenSize.small => null,
                _ => appBar,
              },
              body: LayoutBuilder(
                builder: (context, constraints) {
                  final edgeInsets = switch (screenSize) {
                    ScreenSize.medium => EdgeInsets.only(right: 4.0),
                    ScreenSize.large => EdgeInsets.symmetric(
                        horizontal: constraints.maxWidth < maxBodyWidth
                            ? 0.0
                            : (constraints.maxWidth - maxBodyWidth) / 2,
                      ),
                    _ => EdgeInsets.zero,
                  };
                  return Padding(padding: edgeInsets, child: body);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  static PreferredSizeWidget appBarOf(
    BuildContext context, {
    Widget? title,
    List<Widget>? actions,
    Widget? leading,
    PreferredSizeWidget? bottom,
  }) {
    return AppBar(
      title: title,
      actions: actions,
      leadingWidth: ResponsiveService.getScreenSize(context) == ScreenSize.small
          ? null
          : 0,
      leading: (ResponsiveService.getScreenSize(context) == ScreenSize.small
          ? leading
          : SizedBox.shrink()),
      bottom: bottom,
    );
  }
}
