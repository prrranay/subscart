import 'user_model.dart';
import 'subscription_model.dart';
import 'scheduled_order_model.dart';

class CutoffConfigModel {
  final int hour;
  final int minute;
  final String timezone;

  const CutoffConfigModel({
    required this.hour,
    required this.minute,
    required this.timezone,
  });

  factory CutoffConfigModel.fromJson(Map<String, dynamic> json) {
    return CutoffConfigModel(
      hour: json['hour'] ?? 20,
      minute: json['minute'] ?? 30,
      timezone: json['timezone'] ?? 'Asia/Kolkata',
    );
  }
}

class ScheduleResponseModel {
  final UserModel user;
  final SubscriptionModel subscription;
  final CutoffConfigModel cutoffConfig;
  final List<ScheduledOrderModel> orders;

  const ScheduleResponseModel({
    required this.user,
    required this.subscription,
    required this.cutoffConfig,
    required this.orders,
  });

  factory ScheduleResponseModel.fromJson(Map<String, dynamic> json) {
    return ScheduleResponseModel(
      user: UserModel.fromJson(json['user'] ?? {}),
      subscription: SubscriptionModel.fromJson(json['subscription'] ?? {}),
      cutoffConfig: CutoffConfigModel.fromJson(json['cutoffConfig'] ?? {}),
      orders: (json['orders'] as List<dynamic>?)
              ?.map((e) => ScheduledOrderModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
