import 'package:flutter/material.dart';
import 'package:stockman/src/config/app_theme.dart';
import 'package:stockman/src/config/text_theme.dart';
import 'package:stockman/src/models/farmer_profile.dart';
import 'package:stockman/src/Pages/Camp/camp_form_page.dart';
import 'package:stockman/src/providers/camp_db_service.dart';

class CampManagementPage extends StatefulWidget {
  final String farmId;
  final String farmName;

  const CampManagementPage({
    super.key,
    required this.farmId,
    required this.farmName,
  });

  @override
  State<CampManagementPage> createState() => _CampManagementPageState();
}

class _CampManagementPageState extends State<CampManagementPage> {
  List<Camp> _camps = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCamps();
  }

  Future<void> _loadCamps() async {
    setState(() => _loading = true);
    try {
      final camps = await CampDbService().getCamps(widget.farmId);
      setState(() {
        _camps = camps;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading camps: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _deleteCamp(Camp camp) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Camp',
          style: TextColorTheme.heading.copyWith(color: darkGreen),
        ),
        content: Text(
          'Are you sure you want to delete "${camp.name}"? Any cattle in this camp will need to be reassigned.',
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
        await CampDbService().deleteCamp(camp.id);
        _loadCamps();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${camp.name} deleted successfully'),
              backgroundColor: darkGreen,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting camp: $e'),
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Camps',
              style: TextColorTheme.heading,
            ),
            Text(
              widget.farmName,
              style: TextColorTheme.inAppText.copyWith(
                fontSize: 12,
                color: darkGreen.withOpacity(0.7),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: darkGreen),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CampFormPage(
                    farmId: widget.farmId,
                  ),
                ),
              );
              if (result == true) {
                _loadCamps();
              }
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _camps.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _camps.length,
                  itemBuilder: (context, index) {
                    final camp = _camps[index];
                    return _buildCampCard(camp);
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CampFormPage(
                farmId: widget.farmId,
              ),
            ),
          );
          if (result == true) {
            _loadCamps();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Camp'),
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
                Icons.fence,
                size: 80,
                color: darkGreen.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Camps Yet',
              style: TextColorTheme.heading.copyWith(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: darkGreen,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Create camps to organize different areas of your farm for better cattle management.',
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
                    builder: (context) => CampFormPage(
                      farmId: widget.farmId,
                    ),
                  ),
                );
                if (result == true) {
                  _loadCamps();
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Create First Camp'),
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

  Widget _buildCampCard(Camp camp) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: darkGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.fence,
                  color: darkGreen,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      camp.name,
                      style: TextColorTheme.heading.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: darkGreen,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.square_foot,
                          size: 16,
                          color: darkGreen.withOpacity(0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${camp.size} hectares',
                          style: TextColorTheme.inAppText.copyWith(
                            fontSize: 14,
                            color: darkGreen.withOpacity(0.7),
                          ),
                        ),
                      ],
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
                      await Future.delayed(const Duration(milliseconds: 100));
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CampFormPage(
                            farmId: widget.farmId,
                            camp: camp,
                          ),
                        ),
                      );
                      if (result == true) {
                        _loadCamps();
                      }
                    },
                  ),
                  PopupMenuItem(
                    child: Row(
                      children: const [
                        Icon(Icons.delete, size: 20, color: Colors.red),
                        SizedBox(width: 12),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                    onTap: () => _deleteCamp(camp),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
