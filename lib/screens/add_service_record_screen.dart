import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/service_record.dart';
import '../models/vehicle.dart';
import '../services/storage_service.dart';

class AddServiceRecordScreen extends StatefulWidget {
  final Vehicle vehicle;
  final double lastOdometer;
  final ServiceRecord? existingRecord;

  const AddServiceRecordScreen({
    super.key,
    required this.vehicle,
    required this.lastOdometer,
    this.existingRecord,
  });

  @override
  State<AddServiceRecordScreen> createState() => _AddServiceRecordScreenState();
}

class _AddServiceRecordScreenState extends State<AddServiceRecordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _storageService = StorageService();

  late ServiceType _selectedType;
  late DateTime _selectedDate;
  final _odoController = TextEditingController();
  final _descController = TextEditingController();
  final _costController = TextEditingController();
  
  final _nextDueKmController = TextEditingController();
  DateTime? _nextDueDate;

  @override
  void initState() {
    super.initState();
    if (widget.existingRecord != null) {
      _selectedType = widget.existingRecord!.type;
      _selectedDate = widget.existingRecord!.date;
      _odoController.text = widget.existingRecord!.odometerKm.toStringAsFixed(0);
      _descController.text = widget.existingRecord!.description;
      _costController.text = widget.existingRecord!.cost?.toString() ?? '';
      _nextDueKmController.text = widget.existingRecord!.nextDueKm?.toString() ?? '';
      _nextDueDate = widget.existingRecord!.nextDueDate;
    } else {
      _selectedType = ServiceType.uleiMotor;
      _selectedDate = DateTime.now();
      _odoController.text = widget.lastOdometer.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _odoController.dispose();
    _descController.dispose();
    _costController.dispose();
    _nextDueKmController.dispose();
    super.dispose();
  }

  final Map<ServiceType, String> _typeLabels = {
    ServiceType.uleiMotor: "Ulei motor",
    ServiceType.uleiCutie: "Ulei cutie viteze",
    ServiceType.filtruUlei: "Filtru ulei",
    ServiceType.filtruAer: "Filtru aer",
    ServiceType.filtruCombustibil: "Filtru combustibil",
    ServiceType.anvelope: "Anvelope",
    ServiceType.frane: "Frâne",
    ServiceType.baterie: "Baterie",
    ServiceType.revizieTehnica: "Revizie tehnică (T.O.)",
    ServiceType.reparatie: "Reparație",
    ServiceType.altul: "Altul",
  };

  Future<void> _selectDate(BuildContext context, bool isNextDue) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isNextDue ? (_nextDueDate ?? DateTime.now().add(const Duration(days: 365))) : _selectedDate,
      firstDate: isNextDue ? DateTime.now() : DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isNextDue) {
          _nextDueDate = picked;
        } else {
          _selectedDate = picked;
        }
      });
    }
  }

  void _save() async {
    if (_formKey.currentState!.validate()) {
      final record = ServiceRecord(
        id: widget.existingRecord?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        vehicleId: widget.vehicle.id,
        date: _selectedDate,
        odometerKm: double.parse(_odoController.text),
        type: _selectedType,
        description: _descController.text.trim(),
        cost: double.tryParse(_costController.text),
        nextDueKm: double.tryParse(_nextDueKmController.text),
        nextDueDate: _nextDueDate,
      );

      if (widget.existingRecord != null) {
        // Update logic: we need a way to update in StorageService.
        // For simplicity, let's just delete the old one and add the new one, 
        // or add an updateMethod to StorageService.
        await _storageService.deleteServiceRecord(widget.existingRecord!.id);
      }
      await _storageService.addServiceRecord(record);
      
      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adaugă Service'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type Dropdown
              DropdownButtonFormField<ServiceType>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Tip intervenție',
                  border: OutlineInputBorder(),
                ),
                items: ServiceType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(_typeLabels[type]!),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedType = val!;
                    // Auto-calculate nextDueKm for oil changes
                    if (val == ServiceType.uleiMotor) {
                      final currentKm = double.tryParse(_odoController.text) ?? 0;
                      _nextDueKmController.text = (currentKm + widget.vehicle.oilEngineIntervalKm).toStringAsFixed(0);
                    } else if (val == ServiceType.uleiCutie && widget.vehicle.oilGearboxIntervalKm != null) {
                      final currentKm = double.tryParse(_odoController.text) ?? 0;
                      _nextDueKmController.text = (currentKm + widget.vehicle.oilGearboxIntervalKm!).toStringAsFixed(0);
                    }
                  });
                },
              ),
              const SizedBox(height: 16),

              // Date Picker
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Data intervenției'),
                subtitle: Text(DateFormat('dd.MM.yyyy').format(_selectedDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(context, false),
                shape: RoundedRectangleBorder(
                  side: const BorderSide(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 16),

              // Odometer
              TextFormField(
                controller: _odoController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Kilometraj (km)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.speed),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Necesar';
                  final n = double.tryParse(value);
                  if (n == null) return 'Număr invalid';
                  if (n < widget.lastOdometer) {
                    return 'Minim ${widget.lastOdometer.toStringAsFixed(0)} km';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Descriere / Detalii',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),

              // Cost
              TextFormField(
                controller: _costController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Cost (opțional, MDL)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.payments),
                ),
              ),
              const SizedBox(height: 24),

              // Reminder Section
              Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  title: const Text('Setează reamintire', style: TextStyle(fontWeight: FontWeight.bold)),
                  leading: const Icon(Icons.notifications_active, color: Colors.blue),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _nextDueKmController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Următoarea la km',
                              border: OutlineInputBorder(),
                              helperText: 'Ex: peste 10.000 km',
                            ),
                          ),
                          const SizedBox(height: 16),
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                            title: const Text('Următoarea la data'),
                            subtitle: Text(_nextDueDate == null 
                                ? 'Neselectat' 
                                : DateFormat('dd.MM.yyyy').format(_nextDueDate!)),
                            trailing: _nextDueDate != null 
                                ? IconButton(
                                    icon: const Icon(Icons.clear), 
                                    onPressed: () => setState(() => _nextDueDate = null))
                                : const Icon(Icons.calendar_month),
                            onTap: () => _selectDate(context, true),
                            shape: RoundedRectangleBorder(
                              side: BorderSide(color: Colors.grey.shade400),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _save,
                  child: const Text('Salvează înregistrarea'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
