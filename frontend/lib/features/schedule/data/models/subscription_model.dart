class CutoffTimeModel {
  final int hour;
  final int minute;

  const CutoffTimeModel({
    required this.hour,
    required this.minute,
  });

  factory CutoffTimeModel.fromJson(Map<String, dynamic> json) {
    return CutoffTimeModel(
      hour: json['hour'] ?? 20,
      minute: json['minute'] ?? 30,
    );
  }

  Map<String, dynamic> toJson() => {
        'hour': hour,
        'minute': minute,
      };

  String get formattedTime {
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final displayMin = minute.toString().padLeft(2, '0');
    return '$displayHour:$displayMin $period';
  }
}

class SubscriptionModel {
  final String id;
  final String name;
  final String status; // 'active' | 'paused'
  final CutoffTimeModel cutoffTime;

  const SubscriptionModel({
    required this.id,
    required this.name,
    required this.status,
    required this.cutoffTime,
  });

  bool get isPaused => status.toLowerCase() == 'paused';
  bool get isActive => status.toLowerCase() == 'active';

  SubscriptionModel copyWith({
    String? id,
    String? name,
    String? status,
    CutoffTimeModel? cutoffTime,
  }) {
    return SubscriptionModel(
      id: id ?? this.id,
      name: name ?? this.name,
      status: status ?? this.status,
      cutoffTime: cutoffTime ?? this.cutoffTime,
    );
  }

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionModel(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? 'Healthy Plan • 6 Days',
      status: json['status'] ?? 'active',
      cutoffTime: json['cutoffTime'] != null
          ? CutoffTimeModel.fromJson(json['cutoffTime'])
          : const CutoffTimeModel(hour: 20, minute: 30),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'status': status,
        'cutoffTime': cutoffTime.toJson(),
      };
}
