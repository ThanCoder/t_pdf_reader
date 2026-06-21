import 'dart:async';

import 'package:t_pdf_reader/src/reader/reader_layout_engine.dart';
import 'package:t_pdf_reader/src/reader/reader_state.dart';
import 'package:t_pdf_reader/src/reader/state_events.dart';
import 'package:than_pdf_engine/core/types.dart';

class ReaderStateController {
  final _controller = StreamController<ReaderState>.broadcast();
  Stream<ReaderState> get stateStream => _controller.stream;
  late ReaderState _state;
  ReaderState get state => _state;
  late List<PageSize> pageSizes = [];

  void setPageSizes(List<PageSize> pageSizes) {
    this.pageSizes = pageSizes;
    _state = ReaderState(pageOffsets: []);
  }

  void dispatch(StateEvent event) {
    if (event is LayoutChanged) {
      _handleLayout(event);
    } else if (event is MouseScrollChanged) {
      _handleMouseScroll(event);
    } else if (event is MouseThumbScrollChanged) {
      _handleMouseThumbScroll(event);
    }
  }

  void _handleMouseThumbScroll(MouseThumbScrollChanged event) {
    double newScroll = event.scrollY;
    // လက်ရှိ ရှိပြီးသား pageOffsets မြေပုံပေါ်မူတည်ပြီး visible pages ကို စစ်ထုတ်သည်
    if (state.lastConstraints != null) {
      newScroll = newScroll.clamp(
        0.0,
        state.totalContentHeight - state.lastConstraints!.maxHeight,
      );
    }
    _state = _state.copyWith(currentScrollOffset: newScroll);
    _buildVisiblePagesList();
  }

  void _handleMouseScroll(MouseScrollChanged event) {
    double newScroll = _state.currentScrollOffset + event.scrollDelta.dy;
    // လက်ရှိ ရှိပြီးသား pageOffsets မြေပုံပေါ်မူတည်ပြီး visible pages ကို စစ်ထုတ်သည်
    if (state.lastConstraints != null) {
      newScroll = newScroll.clamp(
        0.0,
        state.totalContentHeight - state.lastConstraints!.maxHeight,
      );
    }
    _state = _state.copyWith(currentScrollOffset: newScroll);
    _buildVisiblePagesList();
  }

  void _handleLayout(LayoutChanged event) {
    if (pageSizes.isEmpty) return;

    // (က) Pure Engine ထံမှ စာမျက်နှာမြေပုံ အသစ်ကို တွက်ထုတ်ခိုင်းသည်
    final newOffsets = ReaderLayoutEngine.calculatePageOffsets(
      pageSizeList: pageSizes, // Event ထဲကနေ မူရင်း PDF sizes ကို ယူမယ်
      zoomFactor: _state.zoomFactor,
    );

    double totalHeight = newOffsets.fold(0, (sum, item) => sum + item.height);

    // (ခ) Layout Data များကို State ထဲသို့ အရင် သိမ်းဆည်းလိုက်သည်
    _state = _state.copyWith(
      pageOffsets: newOffsets,
      totalContentHeight: totalHeight,
      lastConstraints: event.constraints,
    );

    _buildVisiblePagesList();
  }

  void _buildVisiblePagesList() {
    if (_state.lastConstraints == null) return;

    final visible = ReaderLayoutEngine.getVisiblePages(
      allPageOffsets: _state.pageOffsets,
      scrollOffset: state.currentScrollOffset,
      viewportHeight: _state.lastConstraints!.maxHeight,
      zoomFactor: _state.zoomFactor,
    );

    // State ကို အပြီးသတ် Update လုပ်ပြီး Stream ထဲသို့ ပို့လွှတ် (emit) သည်
    _state = _state.copyWith(visiblePages: visible);
    _controller.add(_state);
  }

  void dispose() {
    _controller.close();
  }
}
