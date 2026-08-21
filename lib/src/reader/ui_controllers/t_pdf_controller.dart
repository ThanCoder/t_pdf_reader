// ignore_for_file: public_member_api_docs, sort_constructors_first
part of '../t_pdf_reader.dart';

class TPdfController extends ITPdfController {
  TPdfController({
    TPdfWidgetBuilder? widgetBuilder,
    TPdfEventBuilder? eventBuilder,
  }) : widgetBuilder = widgetBuilder ?? const TPdfWidgetBuilder(),
       eventBuilder = eventBuilder ?? const TPdfEventBuilder();

  final TPdfWidgetBuilder widgetBuilder;
  final TPdfEventBuilder eventBuilder;
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
  final Widget Function(BuildContext context, PageOffset pageOffset)? footerBuilder;
  final ScrollbarWidgetBuilder Function(BuildContext context, int page)?
  scrollbarBuilder;
  final Widget Function(BuildContext context, bool isLoading, double? progress)?
  lodingBuilder;
  final Widget Function(BuildContext context, String errorMessage)?
  errorBuilder;
  const TPdfWidgetBuilder({
    this.footerBuilder,
    this.scrollbarBuilder,
    this.lodingBuilder,
    this.errorBuilder,
  });
}

class ScrollbarWidgetBuilder {
  final ScrollbarWidgetInfo widgetInfo;
  final Widget builder;
  const ScrollbarWidgetBuilder({
    required this.widgetInfo,
    required this.builder,
  });
}
