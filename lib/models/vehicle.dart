class Vehicle {
  final String id;
  final String name;
  final double initialOdometer;
  final String fuelType; // "Motorină" or "Benzină"
  final double oilEngineIntervalKm;
  final double? oilGearboxIntervalKm;
  final DateTime? technicalInspectionExpiryDate;
  final DateTime? rcaExpiryDate;
  final String? photoPath;

  Vehicle({
    required this.id,
    required this.name,
    required this.initialOdometer,
    required this.fuelType,
    this.oilEngineIntervalKm = 10000,
    this.oilGearboxIntervalKm,
    this.technicalInspectionExpiryDate,
    this.rcaExpiryDate,
    this.photoPath,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'initialOdometer': initialOdometer,
        'fuelType': fuelType,
        'oilEngineIntervalKm': oilEngineIntervalKm,
        'oilGearboxIntervalKm': oilGearboxIntervalKm,
        'technicalInspectionExpiryDate': technicalInspectionExpiryDate?.toIso8601String(),
        'rcaExpiryDate': rcaExpiryDate?.toIso8601String(),
        'photoPath': photoPath,
      };

  factory Vehicle.fromJson(Map<String, dynamic> json) => Vehicle(
        id: json['id'],
        name: json['name'],
        initialOdometer: (json['initialOdometer'] as num? ?? 0.0).toDouble(),
        fuelType: json['fuelType'] ?? 'Motorină',
        oilEngineIntervalKm: (json['oilEngineIntervalKm'] as num? ?? 10000.0).toDouble(),
        oilGearboxIntervalKm: json['oilGearboxIntervalKm'] != null 
            ? (json['oilGearboxIntervalKm'] as num).toDouble() 
            : null,
        technicalInspectionExpiryDate: json['technicalInspectionExpiryDate'] != null 
            ? DateTime.parse(json['technicalInspectionExpiryDate']) 
            : null,
        rcaExpiryDate: json['rcaExpiryDate'] != null 
            ? DateTime.parse(json['rcaExpiryDate']) 
            : null,
        photoPath: json['photoPath'],
      );
}
