import 'dart:async';

import 'package:federateddatabaseflutter/PlotChartApis.dart';
import 'package:federateddatabaseflutter/generated/federation.pb.dart';
import 'package:federateddatabaseflutter/generated/federation.pbgrpc.dart';
import 'package:flutter/material.dart';
import 'package:grpc/grpc.dart';

class SearchPageTabsVer extends StatefulWidget {
  const SearchPageTabsVer({super.key, required this.title});

  final String title;

  @override
  State<SearchPageTabsVer> createState() => _SearchPageStateTab();
}

class _SearchPageStateTab extends State<SearchPageTabsVer>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: '数据查询'),
              Tab(text: '查询结果'),
              Tab(text: '数据图表'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                DataQueryPage(
                  title: '数据查询',
                  tabController: _tabController,
                ),
                QueryResultsTab(),
                DataChartTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 下拉框
Widget _buildDropdownField(
    String hint, String value, List<String> items, Function(String?) onChanged,
    {bool enabled = true}) {
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
      borderRadius: BorderRadius.circular(1.0),
    ),
    elevation: 2,
    margin: const EdgeInsets.symmetric(vertical: 4),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          RichText(
            text: TextSpan(
              text: 'X  ',
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
              text: 'Y  ',
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
              text: 'Database ID  ',
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

String queryType = 'Nearest';
TextEditingController xController = TextEditingController();
TextEditingController yController = TextEditingController();
String queryNum = '10';
String encrypt = '不加密';
List<CheckResult> results = [];

class DataQueryPage extends StatefulWidget {
  const DataQueryPage(
      {super.key, required this.title, required this.tabController});
  final String title;
  final TabController tabController;

  @override
  State<DataQueryPage> createState() => _DataQueryPageState();
}

class _DataQueryPageState extends State<DataQueryPage> {
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
        double progress = progressNotifier.value;

        if (isEncrypt) {
          if (elapsed < 15000) {
            // 前15秒增长到85%
            progress = (elapsed / 15000) * 0.85;
          } else if (elapsed < 25000) {
            // 15-25秒增长到95%
            progress = 0.85 + ((elapsed - 15000) / 10000) * 0.10;
            print("progress1: $progress");
          } else {
            // 25秒后增长到99%
            if (progress >= 0.99) {
              progress = 0.99;
              t.cancel(); // 停止定时器
            } else {
              progress = 0.95 + ((elapsed - 25000) / 15000) * 0.04;
              // print("progress2: $progress");
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
          }
        }

        // 确保进度不超过设定的最大值
        if (progress >= 0.99) {
          progress = 0.99;
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
          options: CallOptions(timeout: const Duration(seconds: 120)));

      int queryNumInt = 20;
      if (queryType == 'Nearest') {
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

        if ((!isEncrypt) && queryType == 'Nearest') {
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

      //切换到查询结果界面
      widget.tabController.animateTo(1);

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

  // 校验输入框内容
  bool _validateInputs() {
    if (xController.text.isEmpty || yController.text.isEmpty) {
      _showErrorDialog('请输入x和y坐标');
      return false;
    }
    int? x = int.tryParse(xController.text);
    int? y = int.tryParse(yController.text);

    if (x == null || y == null || x < 0 || x > 200 || y < 0 || y > 200) {
      _showErrorDialog('x和y坐标必须在0至200之间');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            _buildDropdownField('查询类型', queryType, ['Nearest', 'AntiNearest'],
                (value) {
              setState(() {
                queryType = value!;
                if (queryType == 'AntiNearest') {
                  queryNum = '自动';
                  encrypt = '不加密';
                } else {
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
            _buildDropdownField(
              '是否加密',
              encrypt,
              queryType == 'Nearest' ? ['不加密', '加密'] : ['不加密'],
              (value) {
                if (queryType == 'Nearest') {
                  setState(() => encrypt = value!);
                }
              },
              enabled: queryType == 'Nearest',
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end, // 将按钮放在行的右侧
              children: [
                ElevatedButton(
                  onPressed: _submitQuery,
                  child: const Text('提交查询', style: TextStyle(fontSize: 14)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class QueryResultsTab extends StatelessWidget {
  const QueryResultsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(32, 16, 32, 42),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            ...results.map((result) => Padding(
                  padding: const EdgeInsets.only(bottom: 4), // 增加底部间距，可以根据需要调整
                  child: _buildResultItem(result),
                )),
          ],
        ),
      ),
    );
  }
}

class DataChartTab extends StatelessWidget {
  const DataChartTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(35, 16, 35, 16),
              // 左、上、右、下各16像素的边距
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
}
