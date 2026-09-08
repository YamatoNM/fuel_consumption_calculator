import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/vehicle.dart';
import '../models/consumption_entry.dart';
import '../services/storage_service.dart';

class VehicleDetailScreen extends StatefulWidget {
  final Vehicle vehicle;
  const VehicleDetailScreen({super.key, required this.vehicle});

  @override
  State<VehicleDetailScreen> createState() => _VehicleDetailScreenState();
}

class _VehicleDetailScreenState extends State<VehicleDetailScreen> {
  final StorageService _storageService = StorageService();
  final _formKey = GlobalKey<FormState>();
  final _distanceController = TextEditingController();
  final _fuelController = TextEditingController();

  List<ConsumptionEntry> _entries = [];
  bool _isLoading = true;
  String _currentResult = '';

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  @override
  void dispose() {
    _distanceController.dispose();
    _fuelController.dispose();
    super.dispose();
  }

  Future<void> _loadEntries() async {
    setState(() => _isLoading = true);
    final entries = await _storageService.getEntriesForVehicle(widget.vehicle.id);
    // Sort most recent first
    entries.sort((a, b) => b.date.compareTo(a.date));
    setState(() {
      _entries = entries;
      _isLoading = false;
    });
  }

  void _calculateAndSave() async {
    if (_formKey.currentState!.validate()) {
      final double distance = double.parse(_distanceController.text);
      final double fuel = double.parse(_fuelController.text);
      final double result = (fuel / distance) * 100;

      final newEntry = ConsumptionEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        vehicleId: widget.vehicle.id,
        date: DateTime.now(),
        distanceKm: distance,
        fuelLiters: fuel,
        result: result,
      );

      await _storageService.addEntry(newEntry);
      
      setState(() {
        _currentResult = 'Consum mediu: ${result.toStringAsFixed(2)} L/100km';
        _distanceController.clear();
        _fuelController.clear();
      });
      
      _loadEntries();
    }
  }

  void _resetFields() {
    setState(() {
      _distanceController.clear();
      _fuelController.clear();
      _currentResult = '';
    });
  }

  void _deleteEntry(ConsumptionEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Șterge înregistrarea'),
        content: const Text('Sigur dorești să ștergi această înregistrare?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Nu')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Da')),
        ],
      ),
    );

    if (confirmed == true) {
      await _storageService.deleteEntry(entry.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Înregistrare ștearsă')),
        );
      }
      _loadEntries();
    }
  }

  void _clearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Șterge tot istoricul'),
        content: const Text('Sigur dorești să ștergi TOATE înregistrările pentru acest automobil?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Anulează')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Șterge tot', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      await _storageService.deleteAllEntriesForVehicle(widget.vehicle.id);
      _loadEntries();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.vehicle.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetFields,
            tooltip: 'Resetează câmpurile',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Calculator Section
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _distanceController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Distanța parcursă (km)',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.route),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Completează câmpul.';
                                final n = double.tryParse(value);
                                if (n == null) return 'Introdu un număr.';
                                if (n <= 0) return 'Trebuie să fie > 0.';
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _fuelController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Combustibil consumat (litri)',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.local_gas_station),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Completează câmpul.';
                                final n = double.tryParse(value);
                                if (n == null) return 'Introdu un număr.';
                                if (n < 0) return 'Nu poate fi negativ.';
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _calculateAndSave,
                                child: const Text('Calculează și salvează'),
                              ),
                            ),
                            if (_currentResult.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Text(
                                _currentResult,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
                              ),
                            ]
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                
                // History Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Istoric consum', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      if (_entries.isNotEmpty)
                        TextButton.icon(
                          onPressed: _clearHistory,
                          icon: const Icon(Icons.delete_sweep, size: 20),
                          label: const Text('Șterge tot'),
                          style: TextButton.styleFrom(foregroundColor: Colors.red),
                        ),
                    ],
                  ),
                ),

                // History List
                Expanded(
                  child: _entries.isEmpty
                      ? const Center(child: Text('Nicio înregistrare încă', style: TextStyle(color: Colors.grey)))
                      : ListView.builder(
                          itemCount: _entries.length,
                          itemBuilder: (context, index) {
                            final entry = _entries[index];
                            final dateStr = DateFormat('dd.MM.yyyy HH:mm').format(entry.date);
                            return Dismissible(
                              key: Key(entry.id),
                              background: Container(color: Colors.red, alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), child: const Icon(Icons.delete, color: Colors.white)),
                              direction: DismissDirection.endToStart,
                              confirmDismiss: (dir) async {
                                final bool? res = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Șterge înregistrarea'),
                                    content: const Text('Sigur dorești să ștergi această înregistrare?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Nu')),
                                      TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Da')),
                                    ],
                                  ),
                                );
                                return res;
                              },
                              onDismissed: (dir) async {
                                await _storageService.deleteEntry(entry.id);
                                _loadEntries();
                              },
                              child: ListTile(
                                leading: const Icon(Icons.history),
                                title: Text('$dateStr'),
                                subtitle: Text('${entry.distanceKm} km, ${entry.fuelLiters}L → ${entry.result.toStringAsFixed(2)} L/100km'),
                                trailing: const Icon(Icons.chevron_left, color: Colors.grey, size: 16),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
