import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/plate.dart';
import '../models/activity.dart';
import '../models/fallen_item.dart';

class SupabaseService {
  static SupabaseClient get _db => Supabase.instance.client;
  static const _uuid = Uuid();

  // ─── Auth ─────────────────────────────────────────────────────────────────

  static Future<String> getOrCreateUserId() async {
    final session = _db.auth.currentSession;
    if (session != null) return session.user.id;
    final response = await _db.auth.signInAnonymously();
    return response.user!.id;
  }

  // ─── Plates ───────────────────────────────────────────────────────────────

  static Future<Plate> createPlate({
    required String userId,
    String name = 'My Plate',
    String designId = 'classic',
  }) async {
    final id = _uuid.v4();
    final shareId = _uuid.v4().replaceAll('-', '').substring(0, 10);

    final data = await _db
        .from('plates')
        .insert({
          'id': id,
          'user_id': userId,
          'name': name,
          'design_id': designId,
          'share_id': shareId,
        })
        .select()
        .single();

    return Plate.fromMap(data);
  }

  static Future<Plate?> getPlateById(String id) async {
    try {
      final plateData =
          await _db.from('plates').select().eq('id', id).single();

      final activitiesData = await _db
          .from('activities')
          .select()
          .eq('plate_id', id)
          .order('sort_order', ascending: true);

      final fallenData = await _db
          .from('fallen_items')
          .select()
          .eq('plate_id', id)
          .order('created_at', ascending: true);

      return Plate.fromMap(
        plateData,
        activities: (activitiesData as List).map((a) => Activity.fromMap(a)).toList(),
        fallenItems: (fallenData as List).map((f) => FallenItem.fromMap(f)).toList(),
      );
    } catch (_) {
      return null;
    }
  }

  static Future<Plate?> getPlateByShareId(String shareId) async {
    try {
      final plateData =
          await _db.from('plates').select().eq('share_id', shareId).single();

      final plateId = plateData['id'] as String;

      final activitiesData = await _db
          .from('activities')
          .select()
          .eq('plate_id', plateId)
          .order('sort_order', ascending: true);

      final fallenData = await _db
          .from('fallen_items')
          .select()
          .eq('plate_id', plateId)
          .order('created_at', ascending: true);

      return Plate.fromMap(
        plateData,
        activities: (activitiesData as List).map((a) => Activity.fromMap(a)).toList(),
        fallenItems: (fallenData as List).map((f) => FallenItem.fromMap(f)).toList(),
      );
    } catch (_) {
      return null;
    }
  }

  static Future<List<Plate>> getPlatesForUser(String userId) async {
    final rows = await _db
        .from('plates')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    final plates = <Plate>[];
    for (final row in rows as List) {
      final plate = await getPlateById(row['id'] as String);
      if (plate != null) plates.add(plate);
    }
    return plates;
  }

  static Future<void> updatePlateMeta(Plate plate) async {
    await _db.from('plates').update({
      'name': plate.name,
      'design_id': plate.designId,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', plate.id);
  }

  static Future<void> deletePlate(String id) async {
    await _db.from('plates').delete().eq('id', id);
  }

  // ─── Activities ───────────────────────────────────────────────────────────

  static Future<Activity> addActivity({
    required String plateId,
    required String name,
    required double percentage,
    required String colorHex,
    int sortOrder = 0,
  }) async {
    final id = _uuid.v4();
    final data = await _db
        .from('activities')
        .insert({
          'id': id,
          'plate_id': plateId,
          'name': name,
          'percentage': percentage,
          'color': colorHex,
          'sort_order': sortOrder,
        })
        .select()
        .single();
    return Activity.fromMap(data);
  }

  static Future<void> updateActivity(Activity activity) async {
    await _db.from('activities').update({
      'name': activity.name,
      'percentage': activity.percentage,
      'color': activity.colorHex,
      'sort_order': activity.sortOrder,
    }).eq('id', activity.id);
  }

  static Future<void> deleteActivity(String id) async {
    await _db.from('activities').delete().eq('id', id);
  }

  // ─── Fallen Items ─────────────────────────────────────────────────────────

  static Future<FallenItem> addFallenItem({
    required String plateId,
    required String name,
    required String emoji,
    required double offsetX,
    required double offsetY,
  }) async {
    final id = _uuid.v4();
    final data = await _db
        .from('fallen_items')
        .insert({
          'id': id,
          'plate_id': plateId,
          'name': name,
          'emoji': emoji,
          'offset_x': offsetX,
          'offset_y': offsetY,
        })
        .select()
        .single();
    return FallenItem.fromMap(data);
  }

  static Future<void> deleteFallenItem(String id) async {
    await _db.from('fallen_items').delete().eq('id', id);
  }

  // ─── Realtime ─────────────────────────────────────────────────────────────

  static RealtimeChannel subscribeToPlate(
    String plateId,
    void Function() onUpdate,
  ) {
    return _db
        .channel('plate-$plateId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'activities',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'plate_id',
            value: plateId,
          ),
          callback: (_) => onUpdate(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'fallen_items',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'plate_id',
            value: plateId,
          ),
          callback: (_) => onUpdate(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'plates',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: plateId,
          ),
          callback: (_) => onUpdate(),
        )
        .subscribe();
  }
}
