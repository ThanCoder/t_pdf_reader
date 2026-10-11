// ignore_for_file: public_member_api_docs, sort_constructors_first
part of '../t_pdf_reader.dart';

class TPdfController extends ITPdfController {
  TPdfController({
    TPdfWidgetBuilder? widgetBuilder,
    TPdfEventBuilder? eventBuilder,
    this.pageImageWorkerType = .singleThread,
  }) : widgetBuilder = widgetBuilder ?? const TPdfWidgetBuilder(),
       eventBuilder = eventBuilder ?? const TPdfEventBuilder();

  final TPdfWidgetBuilder widgetBuilder;
  final TPdfEventBuilder eventBuilder;
  final IPageImageWorkerType pageImageWorkerType;
}

class TPdfEventBuilder {
  final KeyEventResult Function(FocusNode node, KeyEvent event)?
  onKeyEventBeforeConfig;
  final KeyEventResult Function(FocusNode node, KeyEvent event)?
  onKeyEventAfterConfig;
  const TPdfEventBuilder({
    this.onKeyEventBeforeConfig,
    this.onKeyEventAfterConfig,
  });
}

class TPdfWidgetBuilder {
  const TPdfWidgetBuilder({
    this.footerBuilder,
    this.scrollbarBuilder,
    this.loadingBuilder,
    this.errorBuilder,
    this.placeholderBuilder,
    this.pageImageLoadingBuilder,
    this.pdfViewerBackgroundWidget,
  });
  final Widget Function(BuildContext context)? pdfViewerBackgroundWidget;
  final Widget Function(BuildContext context, PageOffset offset)?
  pageImageLoadingBuilder;
  final Widget Function(BuildContext context, PageOffset pageOffset)?
  footerBuilder;

  /// ### default Widgets
  ///
  /// `defaultScrollbar1`,`defaultScrollbarMinimal`,`defaultScrollbarNeon`,`defaultScrollbarCyber`,
  /// `defaultScrollbarAurora`,`defaultScrollbarGlass`,
  /// `defaultScrollbarCyberDots`,`defaultScrollbarGlow`,
  ///
  /// ### Example
  /// ```
  /// scrollbarBuilder: (context, page) {
  ///   return defaultScrollbar1; // default
  ///   //custom
  ///   return .new(
  ///     widgetInfo: .new(thumbWidth: 20, thumbHeight: 40),
  ///     builder: defaultScrollbarGlow(thumbWidth: 20, thumbHeight: 40),
  ///   );
  /// },
  /// ```
  final ScrollbarWidgetBuilder Function(BuildContext context, int page)?
  scrollbarBuilder;
  final Widget Function(BuildContext context, bool isLoading, double? progress)?
  loadingBuilder;
  final Widget Function(BuildContext context, String errorMessage)?
  errorBuilder;
  final Widget Function(BuildContext context)? placeholderBuilder;
}

class ScrollbarWidgetBuilder {
  final ScrollbarWidgetInfo widgetInfo;
  final Widget builder;
  const ScrollbarWidgetBuilder({
    required this.widgetInfo,
    required this.builder,
  });
}
