import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/vehicle.dart';
import '../models/consumption_entry.dart';

class StorageService {
  static const String _vehiclesKey = 'vehicles';
  static const String _entriesKey = 'entries';

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
    // Also delete all entries for this vehicle
    await deleteAllEntriesForVehicle(id);
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
}
