import 'dart:async';

import 'package:federateddatabaseflutter/PlotChartApis.dart';
import 'package:federateddatabaseflutter/generated/federation.pb.dart';
import 'package:federateddatabaseflutter/generated/federation.pbgrpc.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:grpc/grpc.dart';

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
            Row(
              mainAxisAlignment: MainAxisAlignment.end, // 将按钮放在行的右侧
              children: [
                // ElevatedButton(
                //   onPressed: _plotChart, // 另一个按钮的功能
                //   child: const Text('图表展示'),
                // ),
                // const SizedBox(width: 8), // 添加间距
                ElevatedButton(
                  onPressed: _submitQuery,
                  child: const Text('提交查询'),
                ),

              ],
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
      elevation: 0.5,
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