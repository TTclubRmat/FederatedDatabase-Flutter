import 'dart:math';

import 'package:federateddatabaseflutter/generated/federation.pb.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class PlotChart extends StatefulWidget {
  final List<CheckResult> results;
  final String xValue;
  final String yValue;

  const PlotChart({
    Key? key,
    required this.results,
    required this.xValue,
    required this.yValue,
  }) : super(key: key);

  @override
  _PlotChartState createState() => _PlotChartState();
}

class _PlotChartState extends State<PlotChart> {
  Offset? hoveredPoint;

  @override
  Widget build(BuildContext context) {

    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return MouseRegion(
                onHover: (event) {
                  setState(() {
                    hoveredPoint = event.localPosition;
                  });
                },
                onExit: (event) {
                  setState(() {
                    hoveredPoint = null;
                  });
                },
                child: CustomPaint(
                  painter: PlotPainter(
                    results: widget.results,
                    xValue: widget.xValue,
                    yValue: widget.yValue,
                    hoveredPoint: hoveredPoint,
                    size: constraints.biggest,
                  ),

                ),

              );
            },
          ),
        ),
        SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendItem(Colors.red, "Database 1"),
            SizedBox(width: 16),
            _buildLegendItem(Colors.green, "Database 2"),
            SizedBox(width: 16),
            _buildLegendItem(Colors.blue, "Database 3"),
          ],
        ),

      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          color: color,
        ),
        const SizedBox(width: 8),
        Text(label),
      ],
    );
  }
}

class PlotPainter extends CustomPainter {
  final List<CheckResult> results;
  final String xValue;
  final String yValue;
  final Offset? hoveredPoint;
  final Size size;

  PlotPainter({
    required this.results,
    required this.xValue,
    required this.yValue,
    required this.hoveredPoint,
    required this.size,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 首先检查 xValue 和 yValue 是否存在
    // print("xValue: $xValue, yValue: $yValue");
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeWidth = 1;

    // 计算坐标范围
    double minX = double.infinity, maxX = double.negativeInfinity;
    double minY = double.infinity, maxY = double.negativeInfinity;

    for (var result in results) {
      minX = min(minX, result.positionX.toDouble());
      maxX = max(maxX, result.positionX.toDouble());
      minY = min(minY, result.positionY.toDouble());
      maxY = max(maxY, result.positionY.toDouble());
    }

    // 考虑默认的点
    try {
      minX = min(minX, double.parse(xValue));
      maxX = max(maxX, double.parse(xValue));
      minY = min(minY, double.parse(yValue));
      maxY = max(maxY, double.parse(yValue));
    } catch (e) {
      // 如果解析失败,停止绘制
      print('Error parsing xValue or yValue: $e');
      return;
    }

    // 添加边距
    minX -= 3;
    maxX += 3;
    minY -= 3;
    maxY += 3;

    // 确保范围不超过0-200
    minX = max(0, minX);
    maxX = min(200, maxX);
    minY = max(0, minY);
    maxY = min(200, maxY);

    // 计算比例
    double scaleX = size.width / (maxX - minX);
    double scaleY = size.height / (maxY - minY);


    // 画坐标轴-----------------------------------------------------------------------------
    paint.color = Colors.black;
    canvas.drawLine(Offset(0, size.height), Offset(size.width, size.height), paint);
    canvas.drawLine(Offset(0, size.height), Offset(0, 0), paint);

    paint.color = Colors.grey.withOpacity(0.5);
    TextPainter textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    // 辅助函数来绘制带padding的文本
    void drawPaddedText(Canvas canvas, String text, Offset offset, TextPainter textPainter, {bool alignRight = false}) {
      const double padding = 4;

      textPainter.text = TextSpan(
        text: text,
        style: const TextStyle(color: Colors.black, fontSize: 12),
      );
      textPainter.layout();

      // 绘制文本
      if (alignRight) {
        textPainter.paint(canvas, Offset(offset.dx - textPainter.width - padding, offset.dy - textPainter.height / 2));
      } else {
        textPainter.paint(canvas, Offset(offset.dx - textPainter.width / 2, offset.dy));
      }
    }

    for (int i = 0; i <= 10; i++) {
      double x = i * size.width / 10;
      double y = i * size.height / 10;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);

      // X轴标注
      double xValue = minX + (maxX - minX) * i / 10;
      String xLabel = xValue.toStringAsFixed(2);
      drawPaddedText(canvas, xLabel, Offset(x, size.height + 5), textPainter);

      // Y轴标注
      double yValue = maxY - (maxY - minY) * i / 10;
      String yLabel = yValue.toStringAsFixed(2);
      drawPaddedText(canvas, yLabel, Offset(-5, y), textPainter, alignRight: true);
    }


    // 画数据点-----------------------------------------------------------------------------
    for (var result in results) {
      switch (result.databaseId) {
        case 1:
          paint.color = Colors.red;
          break;
        case 2:
          paint.color = Colors.green;
          break;
        case 3:
          paint.color = Colors.blue;
          break;
      }

      Offset point = _getPointPosition(result.positionX.toDouble(), result.positionY.toDouble(), minX, minY, scaleX, scaleY);
      canvas.drawCircle(point, 4, paint);
    }

    // 画默认点-----------------------------------------------------------------------------
    paint.color = Colors.black;
    Offset userPoint = _getPointPosition(int.parse(xValue).toDouble(), int.parse(yValue).toDouble(), minX, minY, scaleX, scaleY);
    canvas.drawCircle(userPoint, 6, paint);

    // 画提示框-----------------------------------------------------------------------------
    if (hoveredPoint != null) {
      CheckResult? nearestResult = _findNearestResult(hoveredPoint!,int.parse(xValue), int.parse(yValue), minX, minY, scaleX, scaleY);
      if (nearestResult != null) {
        _drawTooltip(canvas, nearestResult, minX, minY, scaleX, scaleY);
      }
    }
  }

  CheckResult? _findNearestResult(Offset point,int x, int y, double minX, double minY, double scaleX, double scaleY) {
    double minDistance = double.infinity;
    CheckResult? nearestResult;

    for (var result in results) {
      Offset resultPoint = _getPointPosition(result.positionX.toDouble(), result.positionY.toDouble(), minX, minY, scaleX, scaleY);
      double distance = (resultPoint - point).distance;
      if (distance < minDistance && distance < 10) {
        minDistance = distance;
        nearestResult = result;
      }
    }

    CheckResult newResult = CheckResult()..positionX = x..positionY = y..databaseId = 0;

    Offset resultPoint = _getPointPosition(x.toDouble(), y.toDouble(), minX, minY, scaleX, scaleY);
    double distance = (resultPoint - point).distance;
    if (distance < minDistance && distance < 10) {
      minDistance = distance;
      nearestResult = newResult;
    }

    return nearestResult;


  }

  // 坐标转换函数
  Offset _getPointPosition(double x, double y, double minX, double minY, double scaleX, double scaleY) {
    return Offset(
      (x - minX) * scaleX,
      size.height - (y - minY) * scaleY,
    );
  }

  void _drawTooltip(Canvas canvas, CheckResult result, double minX, double minY, double scaleX, double scaleY) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'X: ${result.positionX}, Y: ${result.positionY}',
        style: TextStyle(color: Colors.white, fontSize: 12),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    Offset point = _getPointPosition(result.positionX.toDouble(), result.positionY.toDouble(), minX, minY, scaleX, scaleY);
    Rect rect = Rect.fromCenter(
      center: point.translate(0, -20),
      width: textPainter.width + 16,
      height: textPainter.height + 8,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(4)),
      Paint()..color = Colors.black.withOpacity(0.8),
    );

    textPainter.paint(canvas, rect.topLeft.translate(8, 4));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}