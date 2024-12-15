import 'package:federateddatabaseflutter/DataBasePage.dart';
import 'package:federateddatabaseflutter/SearchPageTabsVer.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const DataBasePage(title: '数据库'),
    const SearchPageTabsVer(title: '数据查询'),
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
        selectedItemColor: Colors.brown,
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