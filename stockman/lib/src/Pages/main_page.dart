import 'package:flutter/material.dart';
import 'package:stockman/src/Pages/Activities/activities_page.dart';
import 'package:stockman/src/Pages/Changeslog/changeslog_page.dart';
import 'package:stockman/src/Pages/Home/home_page.dart';
import 'package:stockman/src/Pages/Profile/profile_page.dart';
import 'package:stockman/src/Pages/Statistics/statistics_page.dart';
import 'package:stockman/src/widgets/navigation_bar.dart';
import 'package:stockman/src/providers/cattle_db_service.dart';
import 'package:stockman/src/providers/farmer_db_service.dart';
import 'package:stockman/src/models/cattle_profile.dart';
import 'package:stockman/src/models/farmer_profile.dart';
import 'package:stockman/src/config/constants.dart';

class MainPage extends StatefulWidget {
  final String farmerUID;

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
  final CattleDbService _cattleDbService = CattleDbService();
  final FarmerDbService _farmerDbService = FarmerDbService();

  late Future<Map<String, Cattle>> _cattleFuture;
  Farmer? _farmer;
  String? _currentFarmId;
  String? _currentCampId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      // Fetch farmer data to get farms and camps
      final farmer = await _farmerDbService.getFarmer(widget.farmerUID);

      setState(() {
        _farmer = farmer;

        // Get the first farm and camp, or create default if none exist
        if (farmer.farms.isNotEmpty) {
          _currentFarmId = farmer.farms.first.id;
          if (farmer.farms.first.camps.isNotEmpty) {
            _currentCampId = farmer.farms.first.camps.first.id;
          }
        }

        _isLoading = false;
      });

      // Load cattle data if we have valid IDs
      if (_currentFarmId != null && _currentCampId != null) {
        _cattleFuture = _loadCattle();
      } else {
        // No farms/camps exist, return empty cattle map
        _cattleFuture = Future.value({});
        dlog('No farms or camps found for farmer: ${widget.farmerUID}');
      }
    } catch (e) {
      dlog('Error initializing MainPage data: $e');
      setState(() {
        _isLoading = false;
      });
      _cattleFuture = Future.value({});
    }
  }

  Future<Map<String, Cattle>> _loadCattle() async {
    if (_currentFarmId == null || _currentCampId == null) {
      return {};
    }

    try {
      final cattleList = await _cattleDbService.getCattle(
        farmId: _currentFarmId!,
        campId: _currentCampId!,
      );
      return {for (var cattle in cattleList) cattle.id: cattle};
    } catch (e) {
      dlog('Error loading cattle: $e');
      return {};
    }
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
      _cattleFuture = _loadCattle();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: [
          // Home page - show overlay if no farms/camps exist
          _currentFarmId == null || _currentCampId == null
              ? _buildNoFarmsOverlay()
              : HomePage(
                  farmerId: widget.farmerUID,
                  farmId: _currentFarmId!,
                  campId: _currentCampId!,
                  cattleDataFuture: _cattleFuture,
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

  Widget _buildNoFarmsOverlay() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.agriculture, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No Farms or Camps Found',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please create a farm and camp in your profile to start adding cattle.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to profile page (index 4)
                _onItemTapped(4);
              },
              icon: const Icon(Icons.person),
              label: const Text('Go to Profile'),
            ),
          ],
        ),
      ),
    );
  }
}
