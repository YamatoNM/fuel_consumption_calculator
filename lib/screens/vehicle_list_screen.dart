import 'package:flutter/material.dart';
import '../models/vehicle.dart';
import '../services/storage_service.dart';
import 'add_vehicle_screen.dart';
import 'vehicle_detail_screen.dart';

class VehicleListScreen extends StatefulWidget {
  const VehicleListScreen({super.key});

  @override
  State<VehicleListScreen> createState() => _VehicleListScreenState();
}

class _VehicleListScreenState extends State<VehicleListScreen> {
  final StorageService _storageService = StorageService();
  List<Vehicle> _vehicles = [];
  Map<String, int> _entryCounts = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final vehicles = await _storageService.getVehicles();
    final Map<String, int> counts = {};
    for (var v in vehicles) {
      final entries = await _storageService.getEntriesForVehicle(v.id);
      counts[v.id] = entries.length;
    }
    setState(() {
      _vehicles = vehicles;
      _entryCounts = counts;
      _isLoading = false;
    });
  }

  void _deleteVehicle(Vehicle vehicle) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Șterge automobil'),
        content: Text('Ștergi acest automobil (${vehicle.name}) și tot istoricul lui?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Anulează'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Șterge', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _storageService.deleteVehicle(vehicle.id);
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fuel Consumption Calculator'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _vehicles.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.directions_car, size: 80, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      const Text(
                        'Adaugă primul tău automobil',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _vehicles.length,
                  itemBuilder: (context, index) {
                    final vehicle = _vehicles[index];
                    final count = _entryCounts[vehicle.id] ?? 0;
                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.directions_car)),
                        title: Text(vehicle.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('$count înregistrări'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => _deleteVehicle(vehicle),
                        ),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => VehicleDetailScreen(vehicle: vehicle),
                            ),
                          );
                          _loadData();
                        },
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddVehicleScreen()),
          );
          if (result == true) _loadData();
        },
        label: const Text('Adaugă automobil'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
