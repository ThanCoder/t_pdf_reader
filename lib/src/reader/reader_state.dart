// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';

import 'package:t_pdf_reader/src/reader/page_offset.dart';

class ReaderState {
  final double currentScrollOffset;
  final double currentScrollOffsetX;
  final double totalContentHeight;
  final double maxScale;
  final double minScale;
  final double zoomFactor;
  final BoxConstraints? lastConstraints;
  final List<PageOffset> pageOffsets;
  final List<PageOffset> visiblePages;
  ReaderState({
    this.currentScrollOffset = 0,
    this.currentScrollOffsetX = 0,
    this.totalContentHeight = 0,
    this.maxScale = 0.2,
    this.minScale = 5,
    this.zoomFactor = 0.7,
    this.lastConstraints,
    required this.pageOffsets,
    this.visiblePages = const [],
  });

  ReaderState copyWith({
    double? currentScrollOffset,
    double? currentScrollOffsetX,
    double? totalContentHeight,
    double? maxScale,
    double? minScale,
    double? zoomFactor,
    BoxConstraints? lastConstraints,
    List<PageOffset>? pageOffsets,
    List<PageOffset>? visiblePages,
  }) {
    return ReaderState(
      currentScrollOffset: currentScrollOffset ?? this.currentScrollOffset,
      currentScrollOffsetX: currentScrollOffsetX ?? this.currentScrollOffsetX,
      totalContentHeight: totalContentHeight ?? this.totalContentHeight,
      maxScale: maxScale ?? this.maxScale,
      minScale: minScale ?? this.minScale,
      zoomFactor: zoomFactor ?? this.zoomFactor,
      lastConstraints: lastConstraints ?? this.lastConstraints,
      pageOffsets: pageOffsets ?? this.pageOffsets,
      visiblePages: visiblePages ?? this.visiblePages,
    );
  }
}
