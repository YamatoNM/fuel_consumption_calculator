import 'package:flutter/material.dart';
import '../models/vehicle.dart';
import '../services/storage_service.dart';

class VehicleSettingsScreen extends StatefulWidget {
  final Vehicle vehicle;
  const VehicleSettingsScreen({super.key, required this.vehicle});

  @override
  State<VehicleSettingsScreen> createState() => _VehicleSettingsScreenState();
}

class _VehicleSettingsScreenState extends State<VehicleSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _storageService = StorageService();
  
  late TextEditingController _engineOilController;
  late TextEditingController _gearboxOilController;

  @override
  void initState() {
    super.initState();
    _engineOilController = TextEditingController(
      text: widget.vehicle.oilEngineIntervalKm.toStringAsFixed(0)
    );
    _gearboxOilController = TextEditingController(
      text: widget.vehicle.oilGearboxIntervalKm?.toStringAsFixed(0) ?? ''
    );
  }

  @override
  void dispose() {
    _engineOilController.dispose();
    _gearboxOilController.dispose();
    super.dispose();
  }

  void _save() async {
    if (_formKey.currentState!.validate()) {
      final updatedVehicle = Vehicle(
        id: widget.vehicle.id,
        name: widget.vehicle.name,
        initialOdometer: widget.vehicle.initialOdometer,
        fuelType: widget.vehicle.fuelType,
        oilEngineIntervalKm: double.parse(_engineOilController.text),
        oilGearboxIntervalKm: _gearboxOilController.text.isNotEmpty 
            ? double.parse(_gearboxOilController.text) 
            : null,
      );

      // We need an update method in StorageService. 
      // Since addVehicle adds to the list, we should ideally have a method that replaces.
      // Reusing saveVehicles logic via get and map.
      final vehicles = await _storageService.getVehicles();
      final index = vehicles.indexWhere((v) => v.id == widget.vehicle.id);
      if (index != -1) {
        vehicles[index] = updatedVehicle;
        await _storageService.saveVehicles(vehicles);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setări automobil'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Intervale schimb ulei',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _engineOilController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Interval ulei motor (km)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.oil_barrel),
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Introdu un interval' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _gearboxOilController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Interval ulei cutie (km, opțional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.settings_input_component),
                  helperText: 'Lasă gol dacă nu este cazul',
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _save,
                  child: const Text('Salvează modificările'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
