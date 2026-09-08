class Vehicle {
  final String id;
  final String name;
  final double initialOdometer;
  final String fuelType; // "Motorină" or "Benzină"

  Vehicle({
    required this.id,
    required this.name,
    required this.initialOdometer,
    required this.fuelType,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'initialOdometer': initialOdometer,
        'fuelType': fuelType,
      };

  factory Vehicle.fromJson(Map<String, dynamic> json) => Vehicle(
        id: json['id'],
        name: json['name'],
        initialOdometer: (json['initialOdometer'] as num? ?? 0.0).toDouble(),
        fuelType: json['fuelType'] ?? 'Motorină',
      );
}
