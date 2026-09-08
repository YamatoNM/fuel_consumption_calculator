import 'package:flutter/material.dart';
import '../models/vehicle.dart';
import '../services/storage_service.dart';

class AddVehicleScreen extends StatefulWidget {
  const AddVehicleScreen({super.key});

  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _odoController = TextEditingController();
  String _fuelType = 'Motorină';
  final _storageService = StorageService();

  @override
  void dispose() {
    _nameController.dispose();
    _odoController.dispose();
    super.dispose();
  }

  void _save() async {
    if (_formKey.currentState!.validate()) {
      final newVehicle = Vehicle(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        initialOdometer: double.parse(_odoController.text),
        fuelType: _fuelType,
      );
      await _storageService.addVehicle(newVehicle);
      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adaugă Automobil'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nume / Poreclă automobil',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.directions_car),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Numele nu poate fi gol.';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _odoController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Kilometraj inițial (km)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.speed),
                  helperText: 'Valoarea curentă din bord',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Introdu kilometrajul.';
                  if (double.tryParse(value) == null) return 'Introdu un număr valid.';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              const Text('Tip combustibil:', style: TextStyle(fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Radio<String>(
                    value: 'Motorină',
                    groupValue: _fuelType,
                    onChanged: (v) => setState(() => _fuelType = v!),
                  ),
                  const Text('Motorină'),
                  const SizedBox(width: 20),
                  Radio<String>(
                    value: 'Benzină',
                    groupValue: _fuelType,
                    onChanged: (v) => setState(() => _fuelType = v!),
                  ),
                  const Text('Benzină'),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _save,
                  child: const Text('Salvează'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
