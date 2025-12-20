import 'dart:math';
import 'package:flutter/material.dart';

class BlockShape {
  final List<Point<int>> cells;
  final Color color;
  BlockShape(this.cells, this.color);

  static final List<Color> colors = [
    const Color(0xffFF6B6B),
    const Color(0xff6BCB77),
    const Color(0xff4D96FF),
    const Color(0xffFFD166),
    const Color(0xff845EC2),
  ];

  static final List<List<Point<int>>> shapes = [
    [Point(0, 0)], // single
    [Point(0, 0), Point(1, 0)], // two horizontal
    [Point(0, 0), Point(0, 1)], // two vertical
    [Point(0, 0), Point(1, 0), Point(0, 1), Point(1, 1)], // 2x2
    [Point(0, 0), Point(1, 0), Point(2, 0)], // 3 horizontal
    [Point(0, 0), Point(0, 1), Point(0, 2)], // 3 vertical
    [Point(0, 0), Point(1, 0), Point(2, 0), Point(1, 1)], // T-ish
    [Point(0, 0), Point(1, 0), Point(1, 1)], // small L
    [Point(0, 0), Point(1, 0), Point(2, 0), Point(3, 0)], // 4 horizontal
  ];
}
