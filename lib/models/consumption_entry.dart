class ConsumptionEntry {
  final String id;
  final String vehicleId;
  final DateTime date;
  final double odometerKm;
  final double fuelLiters;
  final double result; // L/100km
  final double fuelPricePerLiter;
  final double totalCost;

  ConsumptionEntry({
    required this.id,
    required this.vehicleId,
    required this.date,
    required this.odometerKm,
    required this.fuelLiters,
    required this.result,
    required this.fuelPricePerLiter,
    required this.totalCost,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'vehicleId': vehicleId,
        'date': date.toIso8601String(),
        'odometerKm': odometerKm,
        'fuelLiters': fuelLiters,
        'result': result,
        'fuelPricePerLiter': fuelPricePerLiter,
        'totalCost': totalCost,
      };

  factory ConsumptionEntry.fromJson(Map<String, dynamic> json) => ConsumptionEntry(
        id: json['id'],
        vehicleId: json['vehicleId'],
        date: DateTime.parse(json['date']),
        odometerKm: (json['odometerKm'] as num).toDouble(),
        fuelLiters: (json['fuelLiters'] as num).toDouble(),
        result: (json['result'] as num).toDouble(),
        fuelPricePerLiter: (json['fuelPricePerLiter'] as num? ?? 0.0).toDouble(),
        totalCost: (json['totalCost'] as num? ?? 0.0).toDouble(),
      );
}
