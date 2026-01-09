import 'package:flutter/material.dart';
import 'package:stockman/src/config/app_theme.dart';
import 'package:stockman/src/config/text_theme.dart';
import 'package:stockman/src/models/farmer_profile.dart';
import 'package:stockman/src/Pages/Profile/farm_form_page.dart';
import 'package:stockman/src/Pages/Camp/camp_management_page.dart';
import 'package:stockman/src/providers/farm_db_service.dart';

class FarmManagementPage extends StatefulWidget {
  final String farmerId;

  const FarmManagementPage({super.key, required this.farmerId});

  @override
  State<FarmManagementPage> createState() => _FarmManagementPageState();
}

class _FarmManagementPageState extends State<FarmManagementPage> {
  List<Farm> _farms = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFarms();
  }

  Future<void> _loadFarms() async {
    setState(() => _loading = true);
    try {
      final farms = await FarmDbService().getFarms(widget.farmerId);
      setState(() {
        _farms = farms;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading farms: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _deleteFarm(Farm farm) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Farm',
          style: TextColorTheme.heading.copyWith(color: darkGreen),
        ),
        content: Text(
          'Are you sure you want to delete "${farm.name}"? This will also delete all camps and cattle associated with this farm.',
          style: TextColorTheme.inAppText,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FarmDbService().deleteFarm(farm.id);
        _loadFarms();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${farm.name} deleted successfully'),
              backgroundColor: darkGreen,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting farm: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Farms',
          style: TextColorTheme.heading,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: darkGreen),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FarmFormPage(
                    farmerId: widget.farmerId,
                  ),
                ),
              );
              if (result == true) {
                _loadFarms();
              }
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _farms.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _farms.length,
                  itemBuilder: (context, index) {
                    final farm = _farms[index];
                    return _buildFarmCard(farm);
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FarmFormPage(
                farmerId: widget.farmerId,
              ),
            ),
          );
          if (result == true) {
            _loadFarms();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Farm'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: darkGreen.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.agriculture,
                size: 80,
                color: darkGreen.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Farms Yet',
              style: TextColorTheme.heading.copyWith(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: darkGreen,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Create your first farm to start managing your cattle and camps.',
              textAlign: TextAlign.center,
              style: TextColorTheme.inAppText.copyWith(
                fontSize: 16,
                color: darkGreen.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FarmFormPage(
                      farmerId: widget.farmerId,
                    ),
                  ),
                );
                if (result == true) {
                  _loadFarms();
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Create First Farm'),
              style: ElevatedButton.styleFrom(
                backgroundColor: darkGreen,
                foregroundColor: baige,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFarmCard(Farm farm) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: () {
            // Navigate to farm details or camp management
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CampManagementPage(
                  farmId: farm.id,
                  farmName: farm.name,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: darkGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.agriculture,
                        color: darkGreen,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            farm.name,
                            style: TextColorTheme.heading.copyWith(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: darkGreen,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${farm.type} • ${farm.size} hectares',
                            style: TextColorTheme.inAppText.copyWith(
                              fontSize: 14,
                              color: darkGreen.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton(
                      icon: Icon(
                        Icons.more_vert,
                        color: darkGreen.withOpacity(0.7),
                      ),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          child: Row(
                            children: const [
                              Icon(Icons.edit, size: 20),
                              SizedBox(width: 12),
                              Text('Edit'),
                            ],
                          ),
                          onTap: () async {
                            // Small delay to allow menu to close
                            await Future.delayed(
                                const Duration(milliseconds: 100));
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FarmFormPage(
                                  farmerId: widget.farmerId,
                                  farm: farm,
                                ),
                              ),
                            );
                            if (result == true) {
                              _loadFarms();
                            }
                          },
                        ),
                        PopupMenuItem(
                          child: Row(
                            children: const [
                              Icon(Icons.delete, size: 20, color: Colors.red),
                              SizedBox(width: 12),
                              Text('Delete',
                                  style: TextStyle(color: Colors.red)),
                            ],
                          ),
                          onTap: () => _deleteFarm(farm),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(color: darkGreen.withOpacity(0.2)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        Icons.fence,
                        'Camps',
                        farm.camps.length.toString(),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: darkGreen.withOpacity(0.2),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        Icons.pets,
                        'Cattle',
                        farm.cattle.length.toString(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 20,
          color: darkGreen.withOpacity(0.7),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextColorTheme.heading.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: darkGreen,
              ),
            ),
            Text(
              label,
              style: TextColorTheme.inAppText.copyWith(
                fontSize: 12,
                color: darkGreen.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
