part of 't_pdf_render_v3_base.dart';

class TCustomScrollbarWidget {
  final double scrollbarHeight;
  final double scrollbarWidth;
  final double scrollbarRightPosition;
  final Widget child;
  const TCustomScrollbarWidget({
    required this.scrollbarHeight,
    required this.scrollbarWidth,
    required this.scrollbarRightPosition,
    required this.child,
  });
}

final _defaultScrollbar = Container(
  decoration: BoxDecoration(
    color: Colors.deepPurple.withOpacity(0.7),
    borderRadius: BorderRadius.circular(20),
  ),
);
