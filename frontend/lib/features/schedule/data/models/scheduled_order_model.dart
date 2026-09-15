import '../../domain/enums/meal_slot.dart';
import '../../domain/enums/order_status.dart';
import 'meal_model.dart';

class ScheduledOrderModel {
  final String id;
  final String userId;
  final String subscriptionId;
  final String deliveryDate; // YYYY-MM-DD
  final MealModel? meal;
  final String? rawMealId;
  final MealSlot slot;
  final OrderStatus status;
  final String? previousMealId;
  final String? previousDate;
  final MealSlot? previousSlot;
  final OrderStatus? previousStatus;
  final String? cutoffAtUtc;
  final bool isCutoffPassed;
  final int remainingCutoffMs;
  final int version;

  const ScheduledOrderModel({
    required this.id,
    required this.userId,
    required this.subscriptionId,
    required this.deliveryDate,
    this.meal,
    this.rawMealId,
    required this.slot,
    required this.status,
    this.previousMealId,
    this.previousDate,
    this.previousSlot,
    this.previousStatus,
    this.cutoffAtUtc,
    this.isCutoffPassed = false,
    this.remainingCutoffMs = 0,
    this.version = 1,
  });

  bool get isSkipped => status == OrderStatus.skipped;
  bool get isSwapped => status == OrderStatus.swapped;
  bool get isMoved => status == OrderStatus.moved;
  bool get isRescheduled => status == OrderStatus.rescheduled;

  ScheduledOrderModel copyWith({
    String? id,
    String? userId,
    String? subscriptionId,
    String? deliveryDate,
    MealModel? meal,
    String? rawMealId,
    MealSlot? slot,
    OrderStatus? status,
    String? previousMealId,
    String? previousDate,
    MealSlot? previousSlot,
    OrderStatus? previousStatus,
    String? cutoffAtUtc,
    bool? isCutoffPassed,
    int? remainingCutoffMs,
    int? version,
  }) {
    return ScheduledOrderModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      subscriptionId: subscriptionId ?? this.subscriptionId,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      meal: meal ?? this.meal,
      rawMealId: rawMealId ?? this.rawMealId,
      slot: slot ?? this.slot,
      status: status ?? this.status,
      previousMealId: previousMealId ?? this.previousMealId,
      previousDate: previousDate ?? this.previousDate,
      previousSlot: previousSlot ?? this.previousSlot,
      previousStatus: previousStatus ?? this.previousStatus,
      cutoffAtUtc: cutoffAtUtc ?? this.cutoffAtUtc,
      isCutoffPassed: isCutoffPassed ?? this.isCutoffPassed,
      remainingCutoffMs: remainingCutoffMs ?? this.remainingCutoffMs,
      version: version ?? this.version,
    );
  }

  factory ScheduledOrderModel.fromJson(Map<String, dynamic> json) {
    MealModel? mealObj;
    String? rawMealId;

    if (json['mealId'] != null) {
      if (json['mealId'] is Map<String, dynamic>) {
        mealObj = MealModel.fromJson(json['mealId']);
        rawMealId = mealObj.id;
      } else {
        rawMealId = json['mealId'].toString();
      }
    }

    return ScheduledOrderModel(
      id: json['id'] ?? json['_id'] ?? '',
      userId: json['userId']?.toString() ?? '',
      subscriptionId: json['subscriptionId']?.toString() ?? '',
      deliveryDate: json['deliveryDate'] ?? '',
      meal: mealObj,
      rawMealId: rawMealId,
      slot: MealSlot.fromString(json['slot'] ?? 'lunch'),
      status: OrderStatus.fromString(json['status'] ?? 'scheduled'),
      previousMealId: json['previousMealId']?.toString(),
      previousDate: json['previousDate']?.toString(),
      previousSlot: json['previousSlot'] != null
          ? MealSlot.fromString(json['previousSlot'])
          : null,
      previousStatus: json['previousStatus'] != null
          ? OrderStatus.fromString(json['previousStatus'])
          : null,
      cutoffAtUtc: json['cutoffAtUtc']?.toString(),
      isCutoffPassed: json['isCutoffPassed'] ?? false,
      remainingCutoffMs: json['remainingCutoffMs'] ?? 0,
      version: json['version'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'subscriptionId': subscriptionId,
        'deliveryDate': deliveryDate,
        'mealId': meal?.toJson() ?? rawMealId,
        'slot': slot.toJson(),
        'status': status.toJson(),
        'previousMealId': previousMealId,
        'previousDate': previousDate,
        'previousSlot': previousSlot?.toJson(),
        'previousStatus': previousStatus?.toJson(),
        'cutoffAtUtc': cutoffAtUtc,
        'isCutoffPassed': isCutoffPassed,
        'remainingCutoffMs': remainingCutoffMs,
        'version': version,
      };
}
