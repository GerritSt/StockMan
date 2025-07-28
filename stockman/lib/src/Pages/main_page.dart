import 'package:flutter/material.dart';
import 'package:stockman/src/Pages/Activities/activities_page.dart';
import 'package:stockman/src/Pages/Changeslog/changeslog_page.dart';
import 'package:stockman/src/Pages/Home/home_page.dart';
import 'package:stockman/src/Pages/Profile/profile_page.dart';
import 'package:stockman/src/Pages/Statistics/statistics_page.dart';
import 'package:stockman/src/models/full_farmer_model.dart';
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

  // This is the full model
  late FullFarmerModel _farmerModel;

  @override
  void initState() {
    super.initState();
    _farmerModel = FullFarmerModel(uid: widget.farmerUID);
    _farmerModel.initialize().then((_) {
      setState(() {
        // Data is loaded, you can now use _farmerModel.getFarmsMap(), etc.
      });
    });
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
      _farmerModel.refreshCattle();
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
            cattleDataFuture: _farmerModel.getCattle(),
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
