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
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                flex: 3, // 上部分占3
                child: Container(
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/background.jpg'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 1, // 下部分占1
                child: Container(
                  color: const Color(0xFFD2B48C), // 浅棕色背景
                  child:  Row(
                    children: [
                      const Expanded(
                        flex: 2, // 左侧占2
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(32, 32, 22, 32),
                          child: Align(
                            alignment: Alignment.center,
                            child: Text(
                              '科研课堂的大作业，基于gRPC通信实现的具有一定加密功能的联邦数据库，可以对指定数据进行最近邻查询。',
                              style: TextStyle(fontSize: 19),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1, // 右侧占1
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(0, 32, 8, 32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceAround, // 设置主轴方向的对齐方式
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  _showDialog(context, '项目简介', 'FederatedDatabase 是一个分布式数据库管理系统，旨在提升数据查询和可视化的效率与安全性。该系统采用后端使用 Python 开发，前端使用 Flutter 框架在 Windows 平台下进行构建，前后端之间通过 gRPC 进行高效的数据传输。FederatedDatabase 主要支持多种类型的数据查询及数据可视化功能，满足用户在信息检索和数据分析方面的需求。');
                                },
                                child: const Text('项目简介'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  _showDialog(context, '开发人员', '张恒鑫');
                                },
                                child: const Text('开发人员'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  _showDialog(context, '阿巴阿巴', '没想好写啥');
                                },
                                child: const Text('阿巴阿巴'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            top: 60, // 距离顶部有间距
            left: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Federated Database based on gRPC',
                  style: TextStyle(fontSize: 24),
                ),
                const SizedBox(height: 20),
                const Text(
                  '- Developed by Zhang Hengxin',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
          Positioned(
            right: 40,
            bottom: MediaQuery.of(context).size.height * 0.5, // 下方较为中心位置（页面下方比例分配为3:1）
            child: Container(
              width: 80, // 固定宽度
              height: 80, // 固定高度
              decoration: BoxDecoration(
                shape: BoxShape.circle, // 设置形状为圆形
                color: Theme.of(context).primaryColor, // 设置背景颜色
              ),
              child: FloatingActionButton(
                onPressed: () {
                  // 导航到新页面
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HomePage(),
                    ),
                  );
                },
                // backgroundColor: Colors.transparent, // 使 FloatingActionButton 背景透明
                // elevation: 0, // 去掉阴影
                child: const Icon(Icons.search), // 查询图标
              ),
            ),
          ),

        ],
      ),
    );
  }

  void _showDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              child: const Text('关闭'),
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

