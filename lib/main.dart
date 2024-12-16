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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
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

class _MainPageState extends State<MainPage> with SingleTickerProviderStateMixin {

  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, -0.5), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FadeTransition(
            opacity: _opacityAnimation,
            child: Column(
              children: [
                Expanded(
                  flex: 3,
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
                  flex: 1,
                  child: Container(
                    color: const Color(0xFFD2B48C),
                    child: FadeTransition(
                      opacity: CurvedAnimation(
                        parent: _controller,
                        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
                      ),
                      child: Row(
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
                ),
              ],
            ),
          ),
          Positioned(
            top: 60,
            left: 16,
            child: SlideTransition(
              position: _slideAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
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
            ),
          ),
          Positioned(
            right: 40,
            bottom: MediaQuery.of(context).size.height * 0.5,
            child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(
                CurvedAnimation(
                  parent: _controller,
                  curve: const Interval(0.0, 1.0, curve: Curves.easeOut),
                ),
              ),
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).primaryColor,
                ),
                child: FloatingActionButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HomePage(),
                      ),
                    );
                  },
                  child: const Icon(Icons.search),
                ),
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

