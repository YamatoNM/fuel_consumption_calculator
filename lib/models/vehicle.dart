class Vehicle {
  final String id;
  final String name;

  Vehicle({
    required this.id,
    required this.name,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
      };

  factory Vehicle.fromJson(Map<String, dynamic> json) => Vehicle(
        id: json['id'],
        name: json['name'],
      );
}
