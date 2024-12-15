import 'dart:async';
import 'package:federateddatabaseflutter/dbutils.dart';
import 'package:flutter/material.dart';
import 'package:federateddatabaseflutter/generated/federation.pb.dart';
import 'package:federateddatabaseflutter/generated/federation.pbgrpc.dart';
import 'package:grpc/grpc.dart';

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