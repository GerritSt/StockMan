import 'package:flutter/material.dart';
import 'package:stockman/src/config/app_theme.dart';
import 'package:stockman/src/config/text_theme.dart';
import 'package:stockman/src/Pages/Profile/edit_profile_page.dart';
import 'package:stockman/src/Pages/Profile/farm_management_page.dart';
import 'package:stockman/src/providers/farmer_db_service.dart';
import 'package:stockman/src/models/farmer_profile.dart';

class ProfilePage extends StatefulWidget {
  final String farmerId;
  const ProfilePage({super.key, required this.farmerId});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Farmer? _farmer;
  bool _loading = true;
  // Remove the hardcoded farmerId

  @override
  void initState() {
    super.initState();
    _fetchFarmer();
  }

  Future<void> _fetchFarmer() async {
    setState(() => _loading = true);
    final farmer = await FarmerDbService().getFarmer(widget.farmerId);
    setState(() {
      _farmer = farmer;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextColorTheme.heading,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: darkGreen),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditProfilePage(farmer: _farmer!),
                ),
              );
              _fetchFarmer(); // Refresh after edit
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _farmer == null
              ? const Center(child: Text('No profile data found.'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Profile Photo and Basic Info Section
                      _buildProfileHeader(),
                      const SizedBox(height: 24),

                      // Statistics Cards
                      _buildStatisticsSection(),
                      const SizedBox(height: 24),

                      // Personal Information Section
                      _buildSectionHeader('Personal Information'),
                      const SizedBox(height: 12),
                      _buildInfoCard(
                        icon: Icons.phone,
                        title: 'Phone',
                        value: _farmer!.phone,
                      ),
                      const SizedBox(height: 24),

                      // Farms Section
                      if (_farmer!.farms.isNotEmpty) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildSectionHeader('My Farms'),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => FarmManagementPage(
                                      farmerId: widget.farmerId,
                                    ),
                                  ),
                                );
                              },
                              child: Text(
                                'View All',
                                style: TextColorTheme.inAppText.copyWith(
                                  color: darkGreen,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ..._buildFarmsSection(),
                      ] else ...[
                        _buildSectionHeader('My Farms'),
                        const SizedBox(height: 12),
                        _buildNoFarmsCard(),
                      ],

                      const SizedBox(height: 24),
                      // Action Buttons
                      _buildActionButtons(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: darkGreen,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: darkGreen.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 55,
            backgroundColor: darkGreen.withOpacity(0.1),
            backgroundImage: _farmer!.profileImageUrl != null
                ? NetworkImage(_farmer!.profileImageUrl!)
                : null,
            child: _farmer!.profileImageUrl == null
                ? Icon(
                    Icons.person,
                    size: 60,
                    color: darkGreen,
                  )
                : null,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '${_farmer!.name} ${_farmer!.surname}',
          style: TextColorTheme.heading.copyWith(
            fontSize: 26,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: darkGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.email,
                size: 16,
                color: darkGreen.withOpacity(0.7),
              ),
              const SizedBox(width: 6),
              Text(
                _farmer!.email,
                style: TextColorTheme.inAppText.copyWith(
                  fontSize: 14,
                  color: darkGreen.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsSection() {
    final totalFarms = _farmer!.farms.length;
    final totalCamps = _farmer!.farms.fold<int>(
      0,
      (sum, farm) => sum + farm.camps.length,
    );
    final totalCattle = _farmer!.farms.fold<int>(
      0,
      (sum, farm) => sum + farm.cattle.length,
    );

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.agriculture,
            title: 'Farms',
            value: totalFarms.toString(),
            color: darkGreen,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.fence,
            title: 'Camps',
            value: totalCamps.toString(),
            color: darkGreen,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.pets,
            title: 'Cattle',
            value: totalCattle.toString(),
            color: darkGreen,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextColorTheme.heading.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextColorTheme.inAppText.copyWith(
              fontSize: 12,
              color: color.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: darkGreen,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextColorTheme.heading.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: darkGreen,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildFarmsSection() {
    return _farmer!.farms.map((farm) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: darkGreen.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: darkGreen.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: darkGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.agriculture,
                      color: darkGreen,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          farm.name,
                          style: TextColorTheme.heading.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: darkGreen,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${farm.type} • ${farm.size} ha',
                          style: TextColorTheme.inAppText.copyWith(
                            fontSize: 14,
                            color: darkGreen.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: darkGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${farm.cattle.length} cattle',
                      style: TextColorTheme.inAppText.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: darkGreen,
                      ),
                    ),
                  ),
                ],
              ),
              if (farm.camps.isNotEmpty) ...[
                const SizedBox(height: 12),
                Divider(color: darkGreen.withOpacity(0.2)),
                const SizedBox(height: 8),
                Text(
                  'Camps (${farm.camps.length})',
                  style: TextColorTheme.inAppText.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: darkGreen.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: farm.camps.map((camp) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: darkGreen.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: darkGreen.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.fence,
                            size: 16,
                            color: darkGreen.withOpacity(0.7),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${camp.name} (${camp.size} ha)',
                            style: TextColorTheme.inAppText.copyWith(
                              fontSize: 12,
                              color: darkGreen.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditProfilePage(farmer: _farmer!),
                ),
              );
              _fetchFarmer();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: darkGreen,
              foregroundColor: baige,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.edit, size: 20),
                SizedBox(width: 8),
                Text(
                  'Edit Profile',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FarmManagementPage(
                    farmerId: widget.farmerId,
                  ),
                ),
              ).then((_) => _fetchFarmer());
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: darkGreen,
              side: const BorderSide(color: darkGreen, width: 2),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.agriculture, size: 20),
                SizedBox(width: 8),
                Text(
                  'Manage Farms',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoFarmsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: darkGreen.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: darkGreen.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.agriculture,
            size: 48,
            color: darkGreen.withOpacity(0.5),
          ),
          const SizedBox(height: 12),
          Text(
            'No Farms Yet',
            style: TextColorTheme.heading.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: darkGreen,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first farm to start managing cattle',
            textAlign: TextAlign.center,
            style: TextColorTheme.inAppText.copyWith(
              fontSize: 14,
              color: darkGreen.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FarmManagementPage(
                    farmerId: widget.farmerId,
                  ),
                ),
              ).then((_) => _fetchFarmer());
            },
            icon: const Icon(Icons.add, size: 20),
            label: const Text('Add Farm'),
            style: ElevatedButton.styleFrom(
              backgroundColor: darkGreen,
              foregroundColor: baige,
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: darkGreen.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: darkGreen.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: darkGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: darkGreen,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextColorTheme.inAppText.copyWith(
                    fontSize: 14,
                    color: darkGreen.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextColorTheme.inAppText.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: darkGreen,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
