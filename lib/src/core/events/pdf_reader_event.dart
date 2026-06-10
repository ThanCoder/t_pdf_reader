sealed class PdfReaderEvent {}

class PdfScreenSizeChanged extends PdfReaderEvent {
  final double zoom;
  final double maxWidth;
  PdfScreenSizeChanged(this.zoom, this.maxWidth);
}

class PdfOnLoaded extends PdfReaderEvent {
  final int totalPage;
  final Duration loadedElapsedTime;
  PdfOnLoaded({required this.totalPage, required this.loadedElapsedTime});
}

class PdfPageChanged extends PdfReaderEvent {
  final int page;
  PdfPageChanged(this.page);
}

class PdfZoomChanged extends PdfReaderEvent {
  final double zoom;
  PdfZoomChanged(this.zoom);
}

class PdfError extends PdfReaderEvent {
  final String error;
  PdfError(this.error);
}
