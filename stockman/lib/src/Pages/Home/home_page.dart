import 'package:flutter/material.dart';
import 'package:stockman/src/Pages/add_cattle_page.dart';
import 'package:stockman/src/config/text_theme.dart';
import 'package:stockman/src/models/cattle_profile.dart';

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

  final Future<List<Cattle>> cattleDataFuture;
  final VoidCallback refreshCattleData;

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // _selectedCattle is a set of selected cattle entries
  final Set<Cattle> _selectedCattle = {};
  // if true selection mode is enabled
  bool _selectionMode = false;

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

  void _deleteSelectedCattle() {
    // Implement the deletion logic here
    setState(() {
      _selectedCattle.clear();
      _selectionMode = false;
    });
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
      body: FutureBuilder<List<Cattle>>(
          future: widget.cattleDataFuture,
          builder: (context, snapshot) {
            // Handle loading state
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            // Handle error state
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            // If data is available
            if (snapshot.hasData && snapshot.data != null) {
              final cattle = snapshot.data!; // List of cattle documents

              if (cattle.isEmpty) {
                return const Center(child: Text('No cattle found!'));
              }
              // if not empty:
              return Scrollbar(
                thumbVisibility: true,
                trackVisibility: true,
                child: ListView.builder(
                  itemCount: cattle.length,
                  itemBuilder: (context, index) {
                    final listEntry = cattle[index];
                    return ListEntryFormat(
                      cattleEntry: listEntry,
                      isSelected: _selectedCattle.contains(listEntry),
                      onSelected: _toggleSelection,
                      selectionMode: _selectionMode,
                    );
                  },
                ),
              );
            }
            return const Center(child: Text('An error occured'));
          }),
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

// this is the format of each entry in the list(this is the card and everything
// in it)
class ListEntryFormat extends StatelessWidget {
  const ListEntryFormat({
    super.key,
    required this.cattleEntry,
    required this.isSelected,
    required this.onSelected,
    required this.selectionMode,
  });

  // Format: { "name": "Cow 1", "breed": "Holstein", "age": 5 }
  final Cattle cattleEntry;
  final bool isSelected;
  final ValueChanged<Cattle> onSelected;
  final bool selectionMode;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(left: 7, right: 7, top: 5),
      child: ListTile(
        title: Row(
          children: [Text(cattleEntry.tag)],
        ),
        subtitle: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(cattleEntry.sex),
            Text(cattleEntry.weight.toString()),
          ],
        ),
        leading: Icon(Icons.pets),
        trailing: selectionMode
            ? (isSelected ? Icon(Icons.check_box) : Icon(Icons.check_box_outline_blank))
            : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        visualDensity: VisualDensity.comfortable,
        onTap: () {
          if (selectionMode) {
            onSelected(cattleEntry);
          } else {
            print('Tile tapped!');
          }
        },
        onLongPress: () => onSelected(cattleEntry),
        selected: isSelected,
      ),
    );
  }
}
