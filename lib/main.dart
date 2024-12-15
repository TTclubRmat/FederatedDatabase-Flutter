import 'package:federateddatabaseflutter/HomePage.dart';
import 'package:flutter/material.dart';

// protoc文件编译命令
// protoc --dart_out=grpc:lib/generated -Iprotos protos/federation.proto

// flutter windows app编译命令
// flutter build windows

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
