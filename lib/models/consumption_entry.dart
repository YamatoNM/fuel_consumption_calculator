class ConsumptionEntry {
  final String id;
  final String vehicleId;
  final DateTime date;
  final double distanceKm;
  final double fuelLiters;
  final double result;

  ConsumptionEntry({
    required this.id,
    required this.vehicleId,
    required this.date,
    required this.distanceKm,
    required this.fuelLiters,
    required this.result,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'vehicleId': vehicleId,
        'date': date.toIso8601String(),
        'distanceKm': distanceKm,
        'fuelLiters': fuelLiters,
        'result': result,
      };

  factory ConsumptionEntry.fromJson(Map<String, dynamic> json) => ConsumptionEntry(
        id: json['id'],
        vehicleId: json['vehicleId'],
        date: DateTime.parse(json['date']),
        distanceKm: json['distanceKm'],
        fuelLiters: json['fuelLiters'],
        result: json['result'],
      );
}
