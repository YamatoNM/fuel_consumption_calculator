import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../models/vehicle.dart';
import '../models/consumption_entry.dart';
import '../models/service_record.dart';
import '../services/storage_service.dart';
import '../services/price_service.dart';
import '../services/ai_ocr_service.dart';
import 'add_service_record_screen.dart';
import 'vehicle_settings_screen.dart';

class VehicleDetailScreen extends StatefulWidget {
  final Vehicle vehicle;
  const VehicleDetailScreen({super.key, required this.vehicle});

  @override
  State<VehicleDetailScreen> createState() => _VehicleDetailScreenState();
}

class _VehicleDetailScreenState extends State<VehicleDetailScreen> {
  final StorageService _storageService = StorageService();
  final PriceService _priceService = PriceService();
  final AiOcrService _aiService = AiOcrService();
  final ImagePicker _picker = ImagePicker();

  final _formKey = GlobalKey<FormState>();
  final _odoController = TextEditingController();
  final _fuelController = TextEditingController();
  final _priceController = TextEditingController();

  late Vehicle _currentVehicle;
  List<ConsumptionEntry> _entries = [];
  List<ServiceRecord> _serviceRecords = [];
  bool _isLoading = true;
  bool _isProcessingAi = false;
  bool _isManualMode = true;
  String _currentResult = '';
  double? _livePrice;

  @override
  void initState() {
    super.initState();
    _currentVehicle = widget.vehicle;
    _loadData();
  }

  @override
  void dispose() {
    _odoController.dispose();
    _fuelController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    // Fetch latest vehicle state (might have changed expiry dates)
    final vehicles = await _storageService.getVehicles();
    final updatedV = vehicles.firstWhere((v) => v.id == widget.vehicle.id);

    // Fetch fuel entries
    final entries = await _storageService.getEntriesForVehicle(widget.vehicle.id);
    entries.sort((a, b) => b.date.compareTo(a.date));

    // Fetch service records
    final services = await _storageService.getServiceRecords(widget.vehicle.id);
    services.sort((a, b) => b.date.compareTo(a.date));

    // Fetch live price
    final price = await _priceService.getLivePrice(updatedV.fuelType);
    
    setState(() {
      _currentVehicle = updatedV;
      _entries = entries;
      _serviceRecords = services;
      _livePrice = price;
      if (price != null) {
        _priceController.text = price.toStringAsFixed(2);
      }
      _isLoading = false;
    });
  }

  Future<void> _captureAndScan(bool isOdometer) async {
    final XFile? photo = await showModalBottomSheet<XFile?>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Cameră'),
              onTap: () async => Navigator.pop(context, await _picker.pickImage(source: ImageSource.camera)),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galerie'),
              onTap: () async => Navigator.pop(context, await _picker.pickImage(source: ImageSource.gallery)),
            ),
          ],
        ),
      ),
    );

    if (photo == null) return;

    setState(() => _isProcessingAi = true);

    try {
      final data = await _aiService.scanImage(File(photo.path), isOdometer);
      if (data != null) {
        if (isOdometer && data['odometer_km'] != null) {
          _odoController.text = data['odometer_km'].toString();
        } else if (!isOdometer) {
          if (data['fuel_liters'] != null) _fuelController.text = data['fuel_liters'].toString();
          if (data['price_per_liter'] != null) _priceController.text = data['price_per_liter'].toString();
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Date extrase cu încredere: ${data['confidence']}')),
          );
        }
      } else {
        throw Exception('Nu s-au putut extrage datele.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Eroare AI: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isProcessingAi = false);
    }
  }

  void _calculateAndSave() async {
    if (_formKey.currentState!.validate()) {
      final double currentOdo = double.parse(_odoController.text);
      final double fuel = double.parse(_fuelController.text);
      final double pricePerLiter = double.tryParse(_priceController.text) ?? _livePrice ?? 0.0;

      // Get last odometer
      double lastOdo = _entries.isNotEmpty ? _entries.first.odometerKm : _currentVehicle.initialOdometer;

      if (currentOdo <= lastOdo) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kilometrajul introdus e mai mic decât ultima înregistrare'), backgroundColor: Colors.red),
        );
        return;
      }

      final double distance = currentOdo - lastOdo;
      final double result = (fuel / distance) * 100;
      final double totalCost = fuel * pricePerLiter;

      final newEntry = ConsumptionEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        vehicleId: _currentVehicle.id,
        date: DateTime.now(),
        odometerKm: currentOdo,
        fuelLiters: fuel,
        result: result,
        fuelPricePerLiter: pricePerLiter,
        totalCost: totalCost,
      );

      await _storageService.addEntry(newEntry);
      
      setState(() {
        _currentResult = 'Consum: ${result.toStringAsFixed(2)} L/100km | Cost: ${totalCost.toStringAsFixed(2)} MDL';
        _odoController.clear();
        _fuelController.clear();
      });
      
      _loadData();
    }
  }

  void _deleteServiceRecord(ServiceRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Șterge intervenție'),
        content: const Text('Sigur dorești să ștergi această înregistrare de service?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Nu')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Șterge', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _storageService.deleteServiceRecord(record.id);
      _loadData();
    }
  }

  void _editServiceRecord(ServiceRecord record) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddServiceRecordScreen(
          vehicle: _currentVehicle,
          lastOdometer: _entries.isNotEmpty ? _entries.first.odometerKm : _currentVehicle.initialOdometer,
          existingRecord: record,
        ),
      ),
    );
    if (result == true) {
      _loadData();
    }
  }

  final Map<ServiceType, IconData> _serviceIcons = {
    ServiceType.uleiMotor: Icons.oil_barrel,
    ServiceType.uleiCutie: Icons.settings_input_component,
    ServiceType.filtruUlei: Icons.filter_alt,
    ServiceType.filtruAer: Icons.air,
    ServiceType.filtruCombustibil: Icons.gas_meter,
    ServiceType.anvelope: Icons.tire_repair,
    ServiceType.frane: Icons.settings_backup_restore,
    ServiceType.baterie: Icons.battery_charging_full,
    ServiceType.revizieTehnica: Icons.assignment,
    ServiceType.asigurareRCA: Icons.verified_user,
    ServiceType.reparatie: Icons.build,
    ServiceType.altul: Icons.more_horiz,
  };

  final Map<ServiceType, String> _serviceLabels = {
    ServiceType.uleiMotor: "Ulei motor",
    ServiceType.uleiCutie: "Ulei cutie viteze",
    ServiceType.filtruUlei: "Filtru ulei",
    ServiceType.filtruAer: "Filtru aer",
    ServiceType.filtruCombustibil: "Filtru combustibil",
    ServiceType.anvelope: "Anvelope",
    ServiceType.frane: "Frâne",
    ServiceType.baterie: "Baterie",
    ServiceType.revizieTehnica: "Revizie tehnică",
    ServiceType.asigurareRCA: "Asigurare RCA",
    ServiceType.reparatie: "Reparație",
    ServiceType.altul: "Altul",
  };

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_currentVehicle.name),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VehicleSettingsScreen(vehicle: _currentVehicle),
                  ),
                );
                if (result == true) {
                  _loadData();
                }
              },
              tooltip: 'Setări automobil',
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => setState(() {
                _odoController.clear();
                _fuelController.clear();
                _currentResult = '';
              }),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Prezentare', icon: Icon(Icons.info_outline)),
              Tab(text: 'Consum', icon: Icon(Icons.local_gas_station)),
              Tab(text: 'Service', icon: Icon(Icons.build)),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildOverviewTab(),
                  _buildFuelTab(),
                  _buildServiceTab(),
                ],
              ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildStatusCard(),
          const SizedBox(height: 20),
          // Quick stats can go here later
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text('Status Documente', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(height: 30),
            _buildStatusRow(
              title: 'Revizie Tehnică (T.O.)',
              date: _currentVehicle.technicalInspectionExpiryDate,
              icon: Icons.assignment_turned_in,
            ),
            const SizedBox(height: 20),
            _buildStatusRow(
              title: 'Asigurare RCA',
              date: _currentVehicle.rcaExpiryDate,
              icon: Icons.verified_user,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow({required String title, required DateTime? date, required IconData icon}) {
    Color statusColor = Colors.grey;
    String statusText = 'Neconfigurat';
    
    if (date != null) {
      final daysLeft = date.difference(DateTime.now()).inDays;
      statusText = DateFormat('dd.MM.yyyy').format(date);
      
      if (daysLeft < 0) {
        statusColor = Colors.red;
        statusText += ' (Expirat)';
      } else if (daysLeft <= 30) {
        statusColor = Colors.orange;
        statusText += ' (Expiră curând)';
      } else {
        statusColor = Colors.green;
      }
    }

    return Row(
      children: [
        Icon(icon, color: statusColor, size: 32),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
              Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFuelTab() {
    return Column(
      children: [
        // Input Mode Toggle
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('Manual'), icon: Icon(Icons.edit)),
              ButtonSegment(value: false, label: Text('Scanare AI'), icon: Icon(Icons.auto_awesome)),
            ],
            selected: {_isManualMode},
            onSelectionChanged: (val) => setState(() => _isManualMode = val.first),
          ),
        ),

        // Form Section
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
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _odoController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Odometer (km)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.speed)),
                            validator: (v) => (v == null || v.isEmpty) ? 'Necesar' : null,
                          ),
                        ),
                        if (!_isManualMode)
                          IconButton(
                            icon: const Icon(Icons.camera_alt, color: Colors.blue),
                            onPressed: _isProcessingAi ? null : () => _captureAndScan(true),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _fuelController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Combustibil (litri)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.local_gas_station)),
                            validator: (v) => (v == null || v.isEmpty) ? 'Necesar' : null,
                          ),
                        ),
                        if (!_isManualMode)
                          IconButton(
                            icon: const Icon(Icons.receipt_long, color: Colors.green),
                            onPressed: _isProcessingAi ? null : () => _captureAndScan(false),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _priceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Preț per litru (MDL)',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.payments),
                        suffixText: _livePrice != null ? '(Live ANRE)' : '',
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_isProcessingAi)
                      const LinearProgressIndicator()
                    else
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _calculateAndSave,
                          child: const Text('Calculează și salvează'),
                        ),
                      ),
                    if (_currentResult.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(_currentResult, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue)),
                    ]
                  ],
                ),
              ),
            ),
          ),
        ),

        // History Header
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Align(alignment: Alignment.centerLeft, child: Text('Istoric înregistrări', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
        ),

        // History List
        Expanded(
          child: _entries.isEmpty
              ? const Center(child: Text('Nicio înregistrare încă'))
              : ListView.builder(
                  itemCount: _entries.length,
                  itemBuilder: (context, index) {
                    final entry = _entries[index];
                    final dateStr = DateFormat('dd.MM.yyyy').format(entry.date);
                    // Calc distance for display
                    double prevOdo = (index + 1 < _entries.length) 
                        ? _entries[index + 1].odometerKm 
                        : _currentVehicle.initialOdometer;
                    double dist = entry.odometerKm - prevOdo;

                    return ListTile(
                      leading: const Icon(Icons.history),
                      title: Text('$dateStr — Odo: ${entry.odometerKm} km'),
                      subtitle: Text('${dist.toStringAsFixed(1)} km, ${entry.fuelLiters}L → ${entry.result.toStringAsFixed(2)} L/100km\nCost: ${entry.totalCost.toStringAsFixed(2)} MDL'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, size: 20),
                        onPressed: () async {
                          await _storageService.deleteEntry(entry.id);
                          _loadData();
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildServiceTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddServiceRecordScreen(
                      vehicle: _currentVehicle,
                      lastOdometer: _entries.isNotEmpty ? _entries.first.odometerKm : _currentVehicle.initialOdometer,
                    ),
                  ),
                );
                if (result == true) {
                  _loadData();
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Adaugă intervenție'),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('Istoric service', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ),
        Expanded(
          child: _serviceRecords.isEmpty
              ? const Center(child: Text('Nicio intervenție înregistrată'))
              : ListView.builder(
                  itemCount: _serviceRecords.length,
                  itemBuilder: (context, index) {
                    final record = _serviceRecords[index];
                    final dateStr = DateFormat('dd.MM.yyyy').format(record.date);
                    return ListTile(
                      leading: CircleAvatar(
                        child: Icon(_serviceIcons[record.type] ?? Icons.build),
                      ),
                      title: Text('${_serviceLabels[record.type]} — $dateStr'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Km: ${record.odometerKm.toStringAsFixed(0)}'),
                          if (record.description.isNotEmpty)
                            Text(record.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                          if (record.cost != null)
                            Text('Cost: ${record.cost!.toStringAsFixed(2)} MDL', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      isThreeLine: true,
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => _deleteServiceRecord(record),
                      ),
                      onTap: () => _editServiceRecord(record),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
