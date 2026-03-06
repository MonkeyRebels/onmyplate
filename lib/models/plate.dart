import 'activity.dart';
import 'fallen_item.dart';
import 'plate_design.dart';

class Plate {
  final String id;
  final String? userId;
  final String name;
  final String designId;
  final String shareId;
  final List<Activity> activities;
  final List<FallenItem> fallenItems;
  final DateTime createdAt;

  const Plate({
    required this.id,
    this.userId,
    required this.name,
    required this.designId,
    required this.shareId,
    this.activities = const [],
    this.fallenItems = const [],
    required this.createdAt,
  });

  PlateDesign get design => PlateDesign.findById(designId);

  double get totalPercentage =>
      activities.fold(0.0, (sum, a) => sum + a.percentage);

  bool get isOverflowing => totalPercentage > 100;

  double get overflowAmount => (totalPercentage - 100).clamp(0.0, double.infinity);

  int get overflowLevel {
    if (!isOverflowing) return 0;
    if (overflowAmount < 20) return 1;
    if (overflowAmount < 50) return 2;
    return 3;
  }

  Plate copyWith({
    String? id,
    String? userId,
    String? name,
    String? designId,
    String? shareId,
    List<Activity>? activities,
    List<FallenItem>? fallenItems,
    DateTime? createdAt,
  }) =>
      Plate(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        name: name ?? this.name,
        designId: designId ?? this.designId,
        shareId: shareId ?? this.shareId,
        activities: activities ?? this.activities,
        fallenItems: fallenItems ?? this.fallenItems,
        createdAt: createdAt ?? this.createdAt,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'name': name,
        'design_id': designId,
        'share_id': shareId,
      };

  factory Plate.fromMap(
    Map<String, dynamic> map, {
    List<Activity> activities = const [],
    List<FallenItem> fallenItems = const [],
  }) =>
      Plate(
        id: map['id'] as String,
        userId: map['user_id'] as String?,
        name: map['name'] as String,
        designId: map['design_id'] as String? ?? 'classic',
        shareId: map['share_id'] as String,
        activities: activities,
        fallenItems: fallenItems,
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}
