import 'package:flutter/material.dart';
import 'package:stockman/src/Pages/Activities/activities_page.dart';
import 'package:stockman/src/Pages/Changeslog/changeslog_page.dart';
import 'package:stockman/src/Pages/Home/home_page.dart';
import 'package:stockman/src/Pages/Profile/profile_page.dart';
import 'package:stockman/src/Pages/Statistics/statistics_page.dart';
import 'package:stockman/src/models/cattle_profile.dart';
import 'package:stockman/src/providers/cattle_db_service.dart';
import 'package:stockman/src/widgets/navigation_bar.dart';

class MainPage extends StatefulWidget {
  final String farmerId;
  final String? farmId;
  final String? campId;
  const MainPage({super.key, required this.farmerId, this.farmId, this.campId});
  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();
  final CattleDbService _dbService = CattleDbService();

  late Future<List<Cattle>> _cattleDataFuture;

  @override
  void initState() {
    super.initState();
    _cattleDataFuture = _dbService.getCattle(
      farmerId: widget.farmerId,
      farmId: widget.farmId ?? 'farm_001',
      campId: widget.campId ?? 'camp_001001',
    );
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
      _cattleDataFuture = _dbService.getCattle(
        farmerId: widget.farmerId,
        farmId: widget.farmId ?? 'farm_001',
        campId: widget.campId ?? 'camp_001001',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: [
          HomePage(
            farmerId: widget.farmerId,
            farmId: widget.farmId ?? 'farm_001',
            campId: widget.campId ?? 'camp_001001',
            cattleDataFuture: _cattleDataFuture,
            refreshCattleData: _refreshCattleData,
          ),
          ActivitiesPage(),
          const ChangeslogPage(),
          const StatisticsPage(),
          ProfilePage(farmerId: widget.farmerId),
        ],
      ),
      bottomNavigationBar: NavigationBarStockman(
        _selectedIndex,
        _onItemTapped,
      ),
    );
  }
}
