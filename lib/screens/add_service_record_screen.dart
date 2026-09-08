import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/service_record.dart';
import '../models/vehicle.dart';
import '../services/storage_service.dart';
import '../services/ai_ocr_service.dart';

class AddServiceRecordScreen extends StatefulWidget {

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
  final _aiService = AiOcrService();
  final _picker = ImagePicker();

  late ServiceType _selectedType;
  late DateTime _selectedDate;
  final _odoController = TextEditingController();
  final _descController = TextEditingController();
  final _costController = TextEditingController();
  
  final _nextDueKmController = TextEditingController();
  DateTime? _nextDueDate;
  String? _receiptPhotoPath;
  bool _isScanning = false;

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
      _receiptPhotoPath = widget.existingRecord!.receiptPhotoPath;
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
    ServiceType.asigurareRCA: "Asigurare RCA",
    ServiceType.reparatie: "Reparație",
    ServiceType.altul: "Altul",
  };

  bool get _isExpiryType => 
    _selectedType == ServiceType.revizieTehnica || _selectedType == ServiceType.asigurareRCA;

  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'receipt_${DateTime.now().millisecondsSinceEpoch}${p.extension(pickedFile.path)}';
      final savedImage = await File(pickedFile.path).copy('${appDir.path}/$fileName');
      setState(() {
        _receiptPhotoPath = savedImage.path;
      });
    }
  }

  Future<void> _scanReceipt() async {
    if (_receiptPhotoPath == null) return;

    setState(() => _isScanning = true);

    try {
      final data = await _aiService.scanImage(File(_receiptPhotoPath!), AiScanContext.serviceReceipt);
      if (data != null) {
        setState(() {
          if (data['cost'] != null) _costController.text = data['cost'].toString();
          if (data['description'] != null) _descController.text = data['description'].toString();
          if (data['date'] != null) {
            try {
              _selectedDate = DateTime.parse(data['date']);
            } catch (_) {}
          }
          if (data['validUntilDate'] != null) {
            try {
              _nextDueDate = DateTime.parse(data['validUntilDate']);
            } catch (_) {}
          }
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Date extrase cu AI (${data['confidence']})')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Eroare la scanare: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isScanning = false);
    }
  }

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
      if (_isExpiryType && _nextDueDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Te rugăm să selectezi data de expirare (Valabil până la).')),
        );
        return;
      }

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
        receiptPhotoPath: _receiptPhotoPath,
      );

      // Save record
      if (widget.existingRecord != null) {
        await _storageService.deleteServiceRecord(widget.existingRecord!.id);
      }
      await _storageService.addServiceRecord(record);

      // Update Vehicle status if it's T.O. or RCA
      if (_isExpiryType) {
        final vehicles = await _storageService.getVehicles();
        final idx = vehicles.indexWhere((v) => v.id == widget.vehicle.id);
        if (idx != -1) {
          final v = vehicles[idx];
          vehicles[idx] = Vehicle(
            id: v.id,
            name: v.name,
            initialOdometer: v.initialOdometer,
            fuelType: v.fuelType,
            oilEngineIntervalKm: v.oilEngineIntervalKm,
            oilGearboxIntervalKm: v.oilGearboxIntervalKm,
            technicalInspectionExpiryDate: _selectedType == ServiceType.revizieTehnica 
                ? _nextDueDate 
                : v.technicalInspectionExpiryDate,
            rcaExpiryDate: _selectedType == ServiceType.asigurareRCA 
                ? _nextDueDate 
                : v.rcaExpiryDate,
            photoPath: v.photoPath,
          );
          await _storageService.saveVehicles(vehicles);
        }
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
        title: Text(widget.existingRecord == null ? 'Adaugă Service' : 'Editează Service'),
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

              TextFormField(
                controller: _costController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Cost (opțional, MDL)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.payments),
                ),
              ),
              const SizedBox(height: 16),

              // Photo section
              const Text('Poză bon/document', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (_receiptPhotoPath != null)
                Column(
                  children: [
                    Stack(
                      children: [
                        Image.file(File(_receiptPhotoPath!), height: 150, width: double.infinity, fit: BoxFit.cover),
                        Positioned(
                          right: 8, top: 8,
                          child: CircleAvatar(
                            backgroundColor: Colors.red,
                            child: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.white),
                              onPressed: () => setState(() => _receiptPhotoPath = null),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_isScanning)
                      const LinearProgressIndicator()
                    else
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _scanReceipt,
                          icon: const Icon(Icons.auto_awesome),
                          label: const Text('Scanează cu AI (Cost, Dată, Descriere)'),
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.blue),
                        ),
                      ),
                  ],
                )
              else
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Cameră'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Galerie'),
                    ),
                  ],
                ),
              const SizedBox(height: 24),

              Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  initiallyExpanded: _isExpiryType,
                  title: Text(
                    _isExpiryType ? 'Valabilitate document' : 'Setează reamintire', 
                    style: const TextStyle(fontWeight: FontWeight.bold)
                  ),
                  leading: Icon(
                    _isExpiryType ? Icons.verified_user : Icons.notifications_active, 
                    color: _isExpiryType ? Colors.green : Colors.blue
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Column(
                        children: [
                          if (!_isExpiryType) ...[
                            TextFormField(
                              controller: _nextDueKmController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Următoarea la km',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                            title: Text(_isExpiryType ? 'Valabil până la (Data)' : 'Următoarea la data'),
                            subtitle: Text(_nextDueDate == null 
                                ? 'Neselectat' 
                                : DateFormat('dd.MM.yyyy').format(_nextDueDate!)),
                            trailing: (_nextDueDate != null && !_isExpiryType)
                                ? IconButton(
                                    icon: const Icon(Icons.clear), 
                                    onPressed: () => setState(() => _nextDueDate = null))
                                : const Icon(Icons.calendar_month),
                            onTap: () => _selectDate(context, true),
                            shape: RoundedRectangleBorder(
                              side: BorderSide(
                                color: (_isExpiryType && _nextDueDate == null) ? Colors.red : Colors.grey.shade400
                              ),
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

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _save,
                  child: Text(widget.existingRecord == null ? 'Salvează înregistrarea' : 'Actualizează înregistrarea'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
