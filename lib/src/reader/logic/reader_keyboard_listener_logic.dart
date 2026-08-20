part of '../t_pdf_reader.dart';

mixin ReaderKeyboardListenerLogic {
  TPdfController get controller;
  ReaderStateController get stateController;
  FocusNode get keyboardFocusNode;

  Widget listenReaderKeyboardEvents({required Widget child}) {
    return Focus(
      focusNode: keyboardFocusNode,
      autofocus: true,
      onKeyEvent: (node, event) {
        // before config
        final before = controller.eventBuilder.onKeyEventBeforeConfig;
        if (before != null) {
          final result = before(node, event);

          if (result == KeyEventResult.handled) {
            return result;
          }
        }
        // Default config
        if (event is KeyDownEvent) {
          switch (event.logicalKey) {
            case LogicalKeyboardKey.arrowDown:
              stateController.scrollDown();
              return KeyEventResult.handled;

            case LogicalKeyboardKey.arrowUp:
              stateController.scrollUp();
              return KeyEventResult.handled;

            case LogicalKeyboardKey.pageDown:
              stateController.pageDown();
              return KeyEventResult.handled;
            case LogicalKeyboardKey.arrowRight:
              stateController.pageDown();
              return KeyEventResult.handled;

            case LogicalKeyboardKey.pageUp:
              stateController.pageUp();
              return KeyEventResult.handled;
            case LogicalKeyboardKey.arrowLeft:
              stateController.pageUp();
              return KeyEventResult.handled;
          }
        }
        // after config
        final afterCof = controller.eventBuilder.onKeyEventAfterConfig;
        if (afterCof != null) {
          return afterCof(node, event);
        }
        return .ignored;
      },

      child: child,
    );
  }
}
