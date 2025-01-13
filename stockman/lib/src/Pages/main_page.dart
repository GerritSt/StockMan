import 'package:flutter/material.dart';
import 'package:stockman/src/Pages/Activities/activities_page.dart';
import 'package:stockman/src/Pages/Changeslog/changeslog_page.dart';
import 'package:stockman/src/Pages/Home/home_page.dart';
import 'package:stockman/src/Pages/Profile/profile_page.dart';
import 'package:stockman/src/Pages/Statistics/statistics_page.dart';
import 'package:stockman/src/providers/cattle_db_service.dart';
import 'package:stockman/src/widgets/navigation_bar.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});
  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();
  
  final CattleDbService _dbService = CattleDbService();
  late Future<List<Map<String, dynamic>>> _cattleDataFuture;

  @override
  void initState() {
    super.initState();
    _cattleDataFuture = _dbService.getCattle();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: Durations.medium1,
      curve: Curves.easeInOut,
    );
  }

  void _onPageChanged(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _refreshCattleData() {
    setState(() {
      _cattleDataFuture = _dbService.getCattle();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: [
          HomePage(cattleDataFuture: _cattleDataFuture, refreshCattleData: _refreshCattleData),
          ActivitiesPage(),
          const ChangeslogPage(),
          const StatisticsPage(),
          const ProfilePage(),
        ],
      ),
      bottomNavigationBar: NavigationBarStockman(
        _selectedIndex,
        _onItemTapped,
      ),
    );
  }
}
