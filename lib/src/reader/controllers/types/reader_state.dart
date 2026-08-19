// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:t_pdf_reader/src/reader/controllers/types/scrollbar_info.dart';

class ReaderState {
  double currentOffset = 0;
  double totalOffset = 0;
  double recentViewportHeight = 0;
  double recentViewportWidth = 0;
  bool scrollbarDragging = false;
  double zoom = 1.0;
  double maxZoom = 5.0;
  double minZoom = 0.1;
  double zoomStep = 0.2;
  int totalPage = 0;
  int page = 0;
  ScrollbarInfo? scrollbarInfo;
  double scrollbarThumbHeight = 40;
  double scrollbarHeight = 0;
  double currentOffsetX = 0;
  // Sensitivity Factor (0.1 = အလွန်နှေး, 0.3 = ငြိမ့်ငြိမ့်လေး, 1.0 = မူလအတိုင်း မြန်)
  double zoomSensitivity = 0.3;
  bool isReady = false;
}
