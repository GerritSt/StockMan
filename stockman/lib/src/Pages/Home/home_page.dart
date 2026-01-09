import 'package:flutter/material.dart';
import 'package:stockman/src/Pages/Home/add_cattle_page.dart';
import 'package:stockman/src/Pages/Home/cattle_info_page.dart';
import 'package:stockman/src/config/constants.dart';
import 'package:stockman/src/config/text_theme.dart';
import 'package:stockman/src/models/cattle_profile.dart';
import 'package:stockman/src/providers/cattle_db_service.dart';

class HomePage extends StatefulWidget {
  final String farmerId;
  final String farmId;
  final String campId;
  const HomePage({
    super.key,
    required this.farmerId,
    required this.farmId,
    required this.campId,
    required this.cattleDataFuture,
    required this.refreshCattleData,
  });

  final Future<Map<String, Cattle>> cattleDataFuture;
  final VoidCallback refreshCattleData;

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // _selectedCattle is a set of selected cattle entries
  final Set<Cattle> _selectedCattle = {};
  // if true selection mode is enabled
  bool _selectionMode = false;
  // Dedicated ScrollController for ListView and Scrollbar
  final ScrollController _scrollController = ScrollController();
  final CattleDbService _cattleDbService = CattleDbService();

  void _toggleSelection(Cattle cattleEntry) {
    setState(() {
      if (_selectedCattle.contains(cattleEntry)) {
        _selectedCattle.remove(cattleEntry);
        if (_selectedCattle.isEmpty) {
          _selectionMode = false;
        }
      } else {
        _selectedCattle.add(cattleEntry);
        _selectionMode = true;
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Delete selected cattle
  // Firstly show popup asking if user is sure
  void _deleteSelectedCattle() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Cattle'),
          content: Text(
            'Are you sure you want to delete ${_selectedCattle.length} selected cattle?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      await _performDeletion();
      setState(() {
        _selectedCattle.clear();
        _selectionMode = false;
      });
      widget.refreshCattleData(); // Refresh data from Firestore or wherever
    }
  }

  Future<void> _performDeletion() async {
    for (final cattle in _selectedCattle) {
      try {
        await _cattleDbService.deleteCattle(
          cattleId: cattle.id,
        );
      } catch (e) {
        dlog('Failed to delete cattle ${cattle.id}: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'StockMan',
          style: TextColorTheme.heading,
        ),
        actions: [
          if (_selectionMode)
            IconButton(
              onPressed: _deleteSelectedCattle,
              icon: const Icon(Icons.delete),
            ),
          IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          widget.refreshCattleData();
          setState(() {});
        },
        // List of all the cattle
        child: FutureBuilder<Map<String, Cattle>>(
          future: widget.cattleDataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting ||
                snapshot.connectionState == ConnectionState.active) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (snapshot.connectionState == ConnectionState.done) {
              // dlog('Connection is done, get cattle from snapshot.data: ${snapshot.data}');
              final cattleMap = snapshot.data;
              // First check if data exists or is empty
              if (cattleMap == null || cattleMap.isEmpty) {
                dlog('cattleMap is null or empty: ${cattleMap.toString()}');
                return const Center(child: Text('No cattle found!'));
              }
              final cattleList = cattleMap.values.toList();
              // Show the list
              return Scrollbar(
                controller: _scrollController,
                thumbVisibility: true,
                trackVisibility: true,
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  controller: _scrollController,
                  itemCount: cattleList.length,
                  itemBuilder: (context, index) {
                    final listEntry = cattleList[index];
                    return ListEntryFormat(
                      cattleEntry: listEntry,
                      isSelected: _selectedCattle.contains(listEntry),
                      onSelected: _toggleSelection,
                      selectionMode: _selectionMode,
                      refreshCattleData: widget.refreshCattleData,
                    );
                  },
                ),
              );
            }
            return const Center(child: Text('An error occurred'));
          },
        ),
      ),
      // Add cattle button
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => AddCattlePage(
                    farmerId: widget.farmerId,
                    farmId: widget.farmId,
                    campId: widget.campId,
                    refreshCattleData: widget.refreshCattleData)),
          );
        },
        icon: Icon(Icons.add),
        tooltip: 'Add Cattle',
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        label: Text('Add cattle'),
      ),
    );
  }
}

// this is the format of each entry in the list(this is the card and everything in it)
class ListEntryFormat extends StatelessWidget {
  const ListEntryFormat({
    super.key,
    required this.cattleEntry,
    required this.isSelected,
    required this.onSelected,
    required this.selectionMode,
    required this.refreshCattleData,
  });

  // Format: { "name": "Cow 1", "breed": "Holstein", "age": 5 }
  final Cattle cattleEntry;
  final bool isSelected;
  final ValueChanged<Cattle> onSelected;
  final bool selectionMode;
  final VoidCallback refreshCattleData;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(left: 7, right: 7, top: 5),
      child: ListTile(
        title: Row(
          children: [
            Text(cattleEntry.tagNumber),
            if (cattleEntry.tagColour != null) ...[
              SizedBox(width: 8),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _getColorFromString(cattleEntry.tagColour!),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
        subtitle: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Show status instead of sex
            Text(cattleEntry.status),
            // Show birth date or group name instead of weight
            Text(cattleEntry.groupName ??
                (cattleEntry.birthDate != null
                    ? 'Born: ${cattleEntry.birthDate!.year}'
                    : 'No info')),
          ],
        ),
        leading: Icon(Icons.pets),
        trailing: selectionMode
            ? (isSelected
                ? Icon(Icons.check_box)
                : Icon(Icons.check_box_outline_blank))
            : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        visualDensity: VisualDensity.comfortable,
        onTap: () {
          if (selectionMode) {
            onSelected(cattleEntry);
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CattleInfoPage(
                  cattle: cattleEntry,
                  refreshCattleData: refreshCattleData,
                ),
              ),
            );
          }
        },
        onLongPress: () => onSelected(cattleEntry),
        selected: isSelected,
      ),
    );
  }

  // Helper method to convert color string to Color
  Color _getColorFromString(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'red':
        return Colors.red;
      case 'yellow':
        return Colors.yellow;
      case 'blue':
        return Colors.blue;
      case 'green':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
