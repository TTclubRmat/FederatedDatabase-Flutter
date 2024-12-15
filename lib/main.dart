import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:federateddatabaseflutter/generated/federation.pb.dart';
import 'package:federateddatabaseflutter/generated/federation.pbgrpc.dart';
import 'package:grpc/grpc.dart';
import 'dbutils.dart';

// protoc文件编译命令
// protoc --dart_out=grpc:lib/generated -Iprotos protos/federation.proto

// flutter windows app编译命令
// flutter build windows

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
      minX = min(minX, double.parse(xValue!));
      maxX = max(maxX, double.parse(xValue!));
      minY = min(minY, double.parse(yValue!));
      maxY = max(maxY, double.parse(yValue!));
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

      Rect backgroundRect;
      if (alignRight) {
        backgroundRect = Rect.fromLTWH(
          offset.dx - textPainter.width - padding * 2,
          offset.dy - textPainter.height / 2 - padding,
          textPainter.width + padding * 2,
          textPainter.height + padding * 2,
        );
      } else {
        backgroundRect = Rect.fromLTWH(
          offset.dx - textPainter.width / 2 - padding,
          offset.dy - padding,
          textPainter.width + padding * 2,
          textPainter.height + padding * 2,
        );
      }

      // 绘制背景
      // canvas.drawRect(backgroundRect, Paint()..color = backgroundColor);

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
  // Offset _getPointPosition(int x, int y) {
  //   return Offset(
  //     x * size.width / 200,
  //     size.height - y * size.height / 200,
  //   );
  // }

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

// 用于校验数据库地址(addDatabase)的异步函数
Future<int> addDatabase(String newDatabase) async {
  final channel = ClientChannel('127.0.0.1',
      port: 50051,
      options: const ChannelOptions(
        credentials: ChannelCredentials.insecure(),
      ));

  final stub = FederationServiceClient(channel);

  try {
    AddRequest request = AddRequest()..address = newDatabase;
    AddResponse response = await stub.addDatabase(request);

    if (response.addResult == AddResult.Success) {
      return 1;
    } else {
      return 0;
    }
  } catch (e) {
    print('Caught error: $e');
    return -1;
  } finally {
    await channel.shutdown();
  }
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Federated Data Base',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        fontFamily: 'DengXian', // 设置全局字体
      ),
      home: const MainPage(title: '基于gRPC的联邦数据库'),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const DataBasePage(title: '数据库'),
    const SearchPage(title: '数据查询'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('查询'),
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: Colors.purple,
        // 选中项的颜色
        unselectedItemColor: Colors.grey,
        // 未选中项的颜色
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.data_array),
            label: '数据库',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: '数据查询',
          ),
        ],
      ),
    );
  }
}

class DataBasePage extends StatefulWidget {
  const DataBasePage({super.key, required this.title});

  final String title;

  @override
  State<DataBasePage> createState() => _DataBasePageState();
}

class _DataBasePageState extends State<DataBasePage> {
  List<String> databases = [];

  @override
  void initState() {
    super.initState();
    _loadDatabases();
  }

  Future<void> _loadDatabases() async {
    List<String> dbList = await getDbList('databases');
    if (dbList.isEmpty) {
      dbList = ['127.0.0.1:60051', '127.0.0.1:60052', '127.0.0.1:60053']; //, 127.0.0.1:60053
      await saveDbList('databases', dbList);
    }
    dbList = await getDbList('databases');
    setState(() {
      databases = dbList;
    });
  }

  void _showAddDatabaseDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String newDatabase = '';
        return AlertDialog(
          title: const Text('添加数据库'),
          content: TextField(
            onChanged: (value) {
              newDatabase = value;
            },
            decoration: const InputDecoration(hintText: '数据库地址'),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('取消'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('确定'),
              onPressed: () async {
                // 一个不可取消的对话框
                showDialog(
                  context: context,
                  barrierDismissible: false, // 点击外部区域不会关闭对话框
                  builder: (BuildContext context) {
                    return const AlertDialog(
                      title: Text('提示'),
                      content: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '正在校验...',
                            style: TextStyle(fontSize: 16), // 可以根据需要调整字体大小
                          ),
                          SizedBox(width: 25), // 添加间距
                          SizedBox(
                            width: 32, // 设置宽度
                            height: 32, // 设置高度，确保纵横比为1:1
                            child: CircularProgressIndicator(),
                          ),
                        ],
                      ),
                      actions: <Widget>[],
                    );
                  },
                );

                // 校验数据库地址并处理结果
                int addResult = await addDatabase(newDatabase);

                // 关闭“正在校验...”的对话框
                Navigator.of(context).pop();

                if (newDatabase.isNotEmpty) {
                  if (addResult == 1) {
                    databases.add(newDatabase);
                    await saveDbList('databases', databases);
                    setState(() {});
                    Navigator.of(context).pop();
                  } else {
                    String message = '未知错误';
                    if (addResult == 0) message = '数据库校验不通过，请检查数据库地址';
                    if (addResult == -1) message = '数据库服务器错误，请检查网络连接';

                    // 显示错误信息对话框
                    _showErrorDialog(message);
                  }
                } else {
                  print('数据库地址不能为空');
                  _showErrorDialog('数据库地址不能为空');
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('提示'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('确定'),
              onPressed: () {
                Navigator.of(context).pop(); // 关闭对话框
              },
            ),
          ],
        );
      },
    );
  }

  void _deleteDatabase(int index) async {
    if(index>=0&&index<=2){
      _showErrorDialog("禁止删除默认数据库");
    }else{
      databases.removeAt(index);
      await saveDbList('databases', databases);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: _showAddDatabaseDialog,
          child: const Text('添加数据库'),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: databases.length,
            itemBuilder: (context, index) {
              return ListTile(
                leading: const Icon(Icons.data_object),
                title: Text(databases[index]),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    _deleteDatabase(index);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class SearchPage extends StatefulWidget {
  const SearchPage({super.key, required this.title});

  final String title;

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  String queryType = 'Nearest';
  TextEditingController xController = TextEditingController();
  TextEditingController yController = TextEditingController();
  String queryNum = '10';
  String encrypt = '不加密';
  List<CheckResult> results = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('数据查询',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildDropdownField('查询类型', queryType, ['Nearest', 'AntiNearest'],
                    (value) {
                  setState(() {
                    queryType = value!;
                    if (queryType == 'AntiNearest') {
                      queryNum = '自动';
                      encrypt = '不加密';
                    }else{
                      queryNum = '10';
                    }

                  });
                }),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildTextField('x', xController)),
                const SizedBox(width: 16),
                Expanded(child: _buildTextField('y', yController)),
              ],
            ),
            const SizedBox(height: 16),
            _buildDropdownField(
              '查询条数',
              queryNum,
              queryType == 'Nearest'
                  ? List.generate(20, (index) => (index + 1).toString())
                  : ['自动'],
                  (value) {
                if (queryType == 'Nearest') {
                  setState(() => queryNum = value!);
                }
              },
              enabled: queryType == 'Nearest',
            ),
            const SizedBox(height: 16),
            _buildDropdownField('是否加密', encrypt, ['不加密', '加密'], (value) {
              setState(() => encrypt = value!);
            }),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: _submitQuery,
                child: const Text('提交查询'),
              ),
            ),
            const Divider(height: 32),
            const Text('查询结果',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            ...results.map((result) => _buildResultItem(result)).toList(),
            const Divider(height: 32),
            const Text('数据图表',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Padding(
              padding: const EdgeInsets.fromLTRB(35, 16, 35, 16), // 左、上、右、下各16像素的边距
              child: PlotChart(
                results: results,
                xValue: xController.text,
                yValue: yController.text,
              ),
            )


          ],
        ),
      ),
    );
  }

  // 下拉框
  Widget _buildDropdownField(
      String hint,
      String value,
      List<String> items,
      Function(String?) onChanged,
      {bool enabled = true}
      ) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        labelText: hint,
      ),
      value: value,
      items: items.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: enabled ? onChanged : null,
      disabledHint: Text(value),
    );
  }

  // 文本框
  Widget _buildTextField(String hint, TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        labelText: hint,
      ),
      keyboardType: TextInputType.number,
    );
  }

  // 查询结果（自定义列表视图）
  Widget _buildResultItem(CheckResult result) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30.0),
      ),
      elevation: 1.0,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            RichText(
              text: TextSpan(
                text: 'X: ',
                style: const TextStyle(color: Colors.black), // 默认颜色
                children: <TextSpan>[
                  TextSpan(
                    text: '${result.positionX}',
                    style: const TextStyle(fontWeight: FontWeight.bold), // 加粗值
                  ),
                ],
              ),
            ),
            RichText(
              text: TextSpan(
                text: 'Y: ',
                style: const TextStyle(color: Colors.black), // 默认颜色
                children: <TextSpan>[
                  TextSpan(
                    text: '${result.positionY}',
                    style: const TextStyle(fontWeight: FontWeight.bold), // 加粗值
                  ),
                ],
              ),
            ),
            RichText(
              text: TextSpan(
                text: 'Database ID: ',
                style: const TextStyle(color: Colors.black), // 默认颜色
                children: <TextSpan>[
                  TextSpan(
                    text: '${result.databaseId}',
                    style: const TextStyle(fontWeight: FontWeight.bold), // 加粗值
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  //查询函数，异步进行
  void _submitQuery() async {
    if (!_validateInputs()) return;

    // 创建ValueNotifier来跟踪进度
    final progressNotifier = ValueNotifier<double>(0.0);

    // 显示自定义的进度对话框
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('正在查询...'),
          content: Row(
            children: [
              Expanded(
                child: ValueListenableBuilder<double>(
                  valueListenable: progressNotifier,
                  builder: (context, progress, child) {
                    return LinearProgressIndicator(
                      value: progress,
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              ValueListenableBuilder<double>(
                valueListenable: progressNotifier,
                builder: (context, progress, child) {
                  return Text('${(progress * 100).toInt()}%');
                },
              ),
            ],
          ),
        );
      },
    );

    Timer? timer;
    bool isEncrypt = encrypt == '加密';
    final startTime = DateTime.now();
    const maxProgress = 1.00;

    try {
      // 启动定时器以更新进度条
      timer = Timer.periodic(const Duration(milliseconds: 5), (t) {
        final elapsed = DateTime.now().difference(startTime).inMilliseconds;
        double progress;

        if (isEncrypt) {
          if (elapsed < 15000) {
            // 前15秒增长到85%
            progress = (elapsed / 15000) * 0.85;
          } else if (elapsed < 30000) {
            // 15-25秒增长到95%
            progress = 0.85 + ((elapsed - 15000) / 10000) * 0.10;
          } else {
            // 30秒后增长到99%
            progress = 0.95 + ((elapsed - 25000) / 10000) * 0.04;
            if (progress > 0.99) {
              progress = 0.99;
              t.cancel(); // 停止定时器
            }
          }
        } else {
          // 非加密情况，快速增长到85%
          if (elapsed < 1000) {
            progress = (elapsed / 1000) * 0.85;
          } else if (elapsed < 3000) {
            // 1-3秒增长到95%
            progress = 0.85 + ((elapsed - 1000) / 2000) * 0.10;
          } else if (elapsed < 10000) {
            // 3-10秒增长到99%
            progress = 0.95 + ((elapsed - 3000) / 7000) * 0.04;
          } else {
            progress = 0.99;
            t.cancel(); // 停止定时器
          }
        }

        // 确保进度不超过设定的最大值
        if (progress > maxProgress) {
          progress = maxProgress;
          t.cancel(); // 停止定时器
        }

        progressNotifier.value = progress.clamp(0.0, maxProgress);
      });

      // 执行异步 gRPC 查询
      final channel = ClientChannel(
        '127.0.0.1',
        port: 50051,
        options: ChannelOptions(
          credentials: const ChannelCredentials.insecure(),
          codecRegistry:
              CodecRegistry(codecs: const [GzipCodec(), IdentityCodec()]),
          idleTimeout: const Duration(minutes: 2),
        ),
      );

      final stub = FederationServiceClient(channel,
          options: CallOptions(timeout: const Duration(seconds: 60)));

      int queryNumInt = 20;
      if(queryType=='Nearest'){
        queryNumInt = int.parse(queryNum);
      }
      final request = CheckRequest()
        ..queryType =
            queryType == 'Nearest' ? QueryType.Nearest : QueryType.AntiNearest
        ..positionX = int.parse(xController.text)
        ..positionY = int.parse(yController.text)
        ..queryNum = queryNumInt
        ..encrypt = isEncrypt;

      final response = await stub.checkData(request);
      setState(() {
        results = response.results;
      });

      await channel.shutdown();

      // 取消定时器
      timer.cancel();

      timer = null;

      // 创建一个Completer来控制异步操作
      final completer = Completer();

      // 启动定时器以更新进度条
      Timer timer2 = Timer.periodic(const Duration(milliseconds: 3), (t) {
        double progress = progressNotifier.value;

        if ((!isEncrypt)&&queryType=='Nearest') {
          progress += 0.03;
        } else {
          progress += 0.001;
        }

        // 确保进度不超过设定的最大值
        if (progress >= maxProgress) {
          progress = maxProgress;
          progressNotifier.value = 1.0;
          t.cancel(); // 停止定时器

          // 当进度达到100%时，延迟0.1秒后完成Completer
          Future.delayed(const Duration(milliseconds: 100), () {
            completer.complete();
          });
        }

        progressNotifier.value = progress.clamp(0.0, maxProgress);
      });

      // 等待Completer完成
      await completer.future;

      Navigator.of(context).pop();
      timer2.cancel();

      // 显示成功的 Toast
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('查询成功')),
      );
    } catch (e) {
      // 出现错误时，取消定时器并关闭进度对话框
      timer?.cancel();
      Navigator.of(context).pop();

      // 显示错误对话框
      _showErrorDialog('查询错误: $e');
    } finally {
      // 取消定时器并释放资源
      timer?.cancel();
      progressNotifier.dispose();
    }
  }

  bool _validateInputs() {
    if (xController.text.isEmpty || yController.text.isEmpty) {
      _showErrorDialog('请输入x和y坐标');
      return false;
    }
    if (int.tryParse(xController.text) == null ||
        int.tryParse(yController.text) == null) {
      _showErrorDialog('x和y坐标必须为整数');
      return false;
    }
    if (queryType == 'AntiNearest' && encrypt == '加密') {
      _showErrorDialog('反向最近邻查询不支持加密');
      return false;
    }
    return true;
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('错误'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('确定'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key, required this.title});

  final String title;

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // 居中对齐
          children: <Widget>[
            ElevatedButton(
              onPressed: () {
                // 导航到新页面
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HomePage(),
                  ),
                );
              },
              child: const Text('开始查询'),
            ),
          ],
        ),
      ),
    );
  }
}
