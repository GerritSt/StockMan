import 'package:flutter/material.dart';
import 'package:stockman/src/config/app_theme.dart';
import 'package:stockman/src/config/text_theme.dart';
import 'package:stockman/src/Pages/Profile/edit_profile_page.dart';
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
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _farmer == null
              ? const Center(child: Text('No profile data found.'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Profile Photo Section
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
                          child: Icon(
                            Icons.person,
                            size: 60,
                            color: darkGreen,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // User Name
                      Text(
                        _farmer!.name,
                        style: TextColorTheme.heading.copyWith(
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Email
                      Text(
                        _farmer!.email,
                        style: TextColorTheme.inAppText.copyWith(
                          fontSize: 16,
                          color: darkGreen.withOpacity(0.7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Phone
                      _buildInfoCard(
                        icon: Icons.phone,
                        title: 'Phone',
                        value: _farmer!.phone,
                      ),
                      const SizedBox(height: 16),
                      // Location
                      _buildInfoCard(
                        icon: Icons.location_on,
                        title: 'Location',
                        value: _farmer!.location.toString(),
                      ),
                      const SizedBox(height: 32),
                      // Farms
                      if (_farmer!.farms.isNotEmpty)
                        ..._farmer!.farms.map((farm) => Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildInfoCard(
                                  icon: Icons.agriculture,
                                  title: 'Farm Name',
                                  value: farm.name,
                                ),
                                _buildInfoCard(
                                  icon: Icons.category,
                                  title: 'Type',
                                  value: farm.type,
                                ),
                                _buildInfoCard(
                                  icon: Icons.square_foot,
                                  title: 'Size',
                                  value: farm.size.toString(),
                                ),
                                // Camps
                                if (farm.camps.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        left: 16.0, top: 8.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text('Camps:',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold)),
                                        ...farm.camps
                                            .map((camp) => _buildInfoCard(
                                                  icon: Icons.fence,
                                                  title: camp.name,
                                                  value: 'Size:  {camp.size}',
                                                )),
                                      ],
                                    ),
                                  ),
                                const SizedBox(height: 24),
                              ],
                            )),
                      // Edit Profile Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    EditProfilePage(farmer: _farmer!),
                              ),
                            );
                            _fetchFarmer(); // Refresh after edit
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
                          child: const Text(
                            'Edit Profile',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Settings Button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            // TODO: Navigate to settings page
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: darkGreen,
                            side: const BorderSide(color: darkGreen, width: 2),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Settings',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
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
