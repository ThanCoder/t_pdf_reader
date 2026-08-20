// ignore_for_file: public_member_api_docs, sort_constructors_first
class ScrollbarInfo {
  const ScrollbarInfo({required this.thumbTop, required this.thumbHeight});

  final double thumbTop;
  final double thumbHeight;

  ScrollbarInfo copyWith({double? thumbTop, double? thumbHeight}) {
    return ScrollbarInfo(
      thumbTop: thumbTop ?? this.thumbTop,
      thumbHeight: thumbHeight ?? this.thumbHeight,
    );
  }
}

class ScrollbarWidgetInfo {
  final double? positionRight;
  final double? positionLeft;
  final double thumbWidth;
  final double thumbHeight;
  const ScrollbarWidgetInfo({
    this.positionRight,
    this.positionLeft,
    required this.thumbWidth,
    required this.thumbHeight,
  });

  @override
  String toString() {
    return 'ScrollbarWidgetInfo(positionRight: $positionRight, positionLeft: $positionLeft, thumbWidth: $thumbWidth, thumbHeight: $thumbHeight)';
  }
}
