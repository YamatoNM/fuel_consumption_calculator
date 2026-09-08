enum ServiceType {
  uleiMotor,
  uleiCutie,
  filtruUlei,
  filtruAer,
  filtruCombustibil,
  anvelope,
  frane,
  baterie,
  revizieTehnica,
  reparatie,
  altul,
}

class ServiceRecord {
  final String id;
  final String vehicleId;
  final DateTime date;
  final double odometerKm;
  final ServiceType type;
  final String description;
  final double? cost;
  final double? nextDueKm;
  final DateTime? nextDueDate;

  ServiceRecord({
    required this.id,
    required this.vehicleId,
    required this.date,
    required this.odometerKm,
    required this.type,
    required this.description,
    this.cost,
    this.nextDueKm,
    this.nextDueDate,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'vehicleId': vehicleId,
        'date': date.toIso8601String(),
        'odometerKm': odometerKm,
        'type': type.name,
        'description': description,
        'cost': cost,
        'nextDueKm': nextDueKm,
        'nextDueDate': nextDueDate?.toIso8601String(),
      };

  factory ServiceRecord.fromJson(Map<String, dynamic> json) => ServiceRecord(
        id: json['id'],
        vehicleId: json['vehicleId'],
        date: DateTime.parse(json['date']),
        odometerKm: (json['odometerKm'] as num).toDouble(),
        type: ServiceType.values.byName(json['type']),
        description: json['description'],
        cost: json['cost'] != null ? (json['cost'] as num).toDouble() : null,
        nextDueKm: json['nextDueKm'] != null ? (json['nextDueKm'] as num).toDouble() : null,
        nextDueDate: json['nextDueDate'] != null ? DateTime.parse(json['nextDueDate']) : null,
      );
}
