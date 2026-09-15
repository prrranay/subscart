class UserModel {
  final String id;
  final String name;
  final String timezone;

  const UserModel({
    required this.id,
    required this.name,
    required this.timezone,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? '',
      timezone: json['timezone'] ?? 'Asia/Kolkata',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'timezone': timezone,
      };
}
