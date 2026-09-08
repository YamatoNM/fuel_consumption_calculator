import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/vehicle.dart';
import '../models/consumption_entry.dart';
import '../models/service_record.dart';

class StorageService {
  static const String _vehiclesKey = 'vehicles';
  static const String _entriesKey = 'entries';
  static const String _serviceRecordsKey = 'service_records';

  // --- Vehicle Methods ---

  Future<List<Vehicle>> getVehicles() async {
    final prefs = await SharedPreferences.getInstance();
    final String? vehiclesJson = prefs.getString(_vehiclesKey);
    if (vehiclesJson == null) return [];

    final List<dynamic> decoded = jsonDecode(vehiclesJson);
    return decoded.map((item) => Vehicle.fromJson(item)).toList();
  }

  Future<void> saveVehicles(List<Vehicle> vehicles) async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(vehicles.map((v) => v.toJson()).toList());
    await prefs.setString(_vehiclesKey, encoded);
  }

  Future<void> addVehicle(Vehicle vehicle) async {
    final vehicles = await getVehicles();
    vehicles.add(vehicle);
    await saveVehicles(vehicles);
  }

  Future<void> deleteVehicle(String id) async {
    final vehicles = await getVehicles();
    vehicles.removeWhere((v) => v.id == id);
    await saveVehicles(vehicles);
    // Also delete all entries and service records for this vehicle
    await deleteAllEntriesForVehicle(id);
    await deleteAllServiceRecordsForVehicle(id);
  }

  // --- Consumption Entry Methods ---

  Future<List<ConsumptionEntry>> getEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final String? entriesJson = prefs.getString(_entriesKey);
    if (entriesJson == null) return [];

    final List<dynamic> decoded = jsonDecode(entriesJson);
    return decoded.map((item) => ConsumptionEntry.fromJson(item)).toList();
  }

  Future<List<ConsumptionEntry>> getEntriesForVehicle(String vehicleId) async {
    final entries = await getEntries();
    return entries.where((e) => e.vehicleId == vehicleId).toList();
  }

  Future<void> saveEntries(List<ConsumptionEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(entries.map((e) => e.toJson()).toList());
    await prefs.setString(_entriesKey, encoded);
  }

  Future<void> addEntry(ConsumptionEntry entry) async {
    final entries = await getEntries();
    entries.add(entry);
    await saveEntries(entries);
  }

  Future<void> deleteEntry(String id) async {
    final entries = await getEntries();
    entries.removeWhere((e) => e.id == id);
    await saveEntries(entries);
  }

  Future<void> deleteAllEntriesForVehicle(String vehicleId) async {
    final entries = await getEntries();
    entries.removeWhere((e) => e.vehicleId == vehicleId);
    await saveEntries(entries);
  }

  // --- Service Record Methods ---

  Future<List<ServiceRecord>> getAllServiceRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final String? recordsJson = prefs.getString(_serviceRecordsKey);
    if (recordsJson == null) return [];

    final List<dynamic> decoded = jsonDecode(recordsJson);
    return decoded.map((item) => ServiceRecord.fromJson(item)).toList();
  }

  Future<List<ServiceRecord>> getServiceRecords(String vehicleId) async {
    final records = await getAllServiceRecords();
    return records.where((r) => r.vehicleId == vehicleId).toList();
  }

  Future<void> saveServiceRecords(List<ServiceRecord> records) async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(records.map((r) => r.toJson()).toList());
    await prefs.setString(_serviceRecordsKey, encoded);
  }

  Future<void> addServiceRecord(ServiceRecord record) async {
    final records = await getAllServiceRecords();
    records.add(record);
    await saveServiceRecords(records);
  }

  Future<void> deleteServiceRecord(String id) async {
    final records = await getAllServiceRecords();
    records.removeWhere((r) => r.id == id);
    await saveServiceRecords(records);
  }

  Future<void> deleteAllServiceRecordsForVehicle(String vehicleId) async {
    final records = await getAllServiceRecords();
    records.removeWhere((r) => r.vehicleId == vehicleId);
    await saveServiceRecords(records);
  }
}
