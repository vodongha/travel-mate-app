import 'package:flutter/material.dart';

/// Centres content and caps its width on wide screens (web / tablet / desktop) so a single-column
/// layout doesn't stretch edge-to-edge. On phones it's a no-op. Keeps height tight so inner
/// scrollables / `Expanded` still work.
class ResponsiveCenter extends StatelessWidget {
  const ResponsiveCenter({super.key, required this.child, this.maxWidth = 720});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width =
            constraints.maxWidth < maxWidth ? constraints.maxWidth : maxWidth;
        return Center(
          child: SizedBox(
            width: width,
            height:
                constraints.maxHeight.isFinite ? constraints.maxHeight : null,
            child: child,
          ),
        );
      },
    );
  }
}
