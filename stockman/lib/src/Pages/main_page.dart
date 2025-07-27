import 'package:flutter/material.dart';
import 'package:stockman/src/Pages/Activities/activities_page.dart';
import 'package:stockman/src/Pages/Changeslog/changeslog_page.dart';
import 'package:stockman/src/Pages/Home/home_page.dart';
import 'package:stockman/src/Pages/Profile/profile_page.dart';
import 'package:stockman/src/Pages/Statistics/statistics_page.dart';
import 'package:stockman/src/models/cattle_profile.dart';
import 'package:stockman/src/models/farmer_profile.dart';
import 'package:stockman/src/providers/cattle_db_service.dart';
import 'package:stockman/src/providers/farmer_db_service.dart';
import 'package:stockman/src/widgets/navigation_bar.dart';

const String defaultFarmID = 'farm_001';
const String defaultCampID = 'camp_001001';

class MainPage extends StatefulWidget {
  final String farmerUID;
  final String farmID = defaultFarmID;
  final String campID = defaultCampID;
  const MainPage({
    super.key,
    required this.farmerUID,
  });
  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();
  // Database services
  final FarmerDbService _farmerDBService = FarmerDbService();
  final CattleDbService _cattleDBService = CattleDbService();
  // Futures used as variables
  late Future<Farmer> _farmerFuture;
  late Future<List<Cattle>> _cattleDataFuture;

  @override
  void initState() {
    super.initState();
    // Get all of the information of the Farmer from firebase
    _cattleDataFuture = _cattleDBService.getCattle(
      farmerId: widget.farmerUID,
      farmId: widget.farmID,
      campId: widget.campID,
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
      _cattleDataFuture = _cattleDBService.getCattle(
        farmerId: widget.farmerUID,
        farmId: widget.farmID,
        campId: widget.campID,
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
            farmerId: widget.farmerUID,
            farmId: widget.farmID,
            campId: widget.campID,
            cattleDataFuture: _cattleDataFuture,
            refreshCattleData: _refreshCattleData,
          ),
          ActivitiesPage(),
          const ChangeslogPage(),
          const StatisticsPage(),
          ProfilePage(farmerId: widget.farmerUID),
        ],
      ),
      bottomNavigationBar: NavigationBarStockman(
        _selectedIndex,
        _onItemTapped,
      ),
    );
  }
}
