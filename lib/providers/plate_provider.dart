import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/plate.dart';
import '../models/activity.dart';
import '../models/fallen_item.dart';
import '../services/supabase_service.dart';

class PlateProvider extends ChangeNotifier {
  Plate? _plate;
  bool _loading = true;
  String? _error;
  String? _userId;
  RealtimeChannel? _channel;

  Plate? get plate => _plate;
  bool get loading => _loading;
  String? get error => _error;
  String? get userId => _userId;

  PlateProvider() {
    _init();
  }

  Future<void> _init() async {
    try {
      _userId = await SupabaseService.getOrCreateUserId();
      final prefs = await SharedPreferences.getInstance();
      final savedId = prefs.getString('current_plate_id');

      if (savedId != null) {
        _plate = await SupabaseService.getPlateById(savedId);
      }

      if (_plate == null) {
        _plate = await SupabaseService.createPlate(userId: _userId!);
        await prefs.setString('current_plate_id', _plate!.id);
      }

      _subscribeToRealtime();
    } catch (e) {
      _error = e.toString();
    }
    _loading = false;
    notifyListeners();
  }

  void _subscribeToRealtime() {
    if (_plate == null) return;
    _channel?.unsubscribe();
    _channel = SupabaseService.subscribeToPlate(_plate!.id, _onRemoteUpdate);
  }

  Future<void> _onRemoteUpdate() async {
    if (_plate == null) return;
    final fresh = await SupabaseService.getPlateById(_plate!.id);
    if (fresh != null) {
      _plate = fresh;
      notifyListeners();
    }
  }

  Future<void> reload() async {
    if (_plate == null) return;
    final fresh = await SupabaseService.getPlateById(_plate!.id);
    if (fresh != null) {
      _plate = fresh;
      notifyListeners();
    }
  }

  // ─── Plate metadata ───────────────────────────────────────────────────────

  Future<void> updateName(String name) async {
    if (_plate == null) return;
    _plate = _plate!.copyWith(name: name);
    notifyListeners();
    await SupabaseService.updatePlateMeta(_plate!);
  }

  Future<void> updateDesign(String designId) async {
    if (_plate == null) return;
    _plate = _plate!.copyWith(designId: designId);
    notifyListeners();
    await SupabaseService.updatePlateMeta(_plate!);
  }

  // ─── Activities ───────────────────────────────────────────────────────────

  Future<void> addActivity({
    required String name,
    required double percentage,
    required String colorHex,
  }) async {
    if (_plate == null) return;
    final activity = await SupabaseService.addActivity(
      plateId: _plate!.id,
      name: name,
      percentage: percentage,
      colorHex: colorHex,
      sortOrder: _plate!.activities.length,
    );
    _plate = _plate!.copyWith(
      activities: [..._plate!.activities, activity],
    );
    notifyListeners();
  }

  Future<void> updateActivity(Activity activity) async {
    if (_plate == null) return;
    await SupabaseService.updateActivity(activity);
    _plate = _plate!.copyWith(
      activities: _plate!.activities.map((a) => a.id == activity.id ? activity : a).toList(),
    );
    notifyListeners();
  }

  Future<void> deleteActivity(String id) async {
    if (_plate == null) return;
    await SupabaseService.deleteActivity(id);
    _plate = _plate!.copyWith(
      activities: _plate!.activities.where((a) => a.id != id).toList(),
    );
    notifyListeners();
  }

  // ─── Fallen items ─────────────────────────────────────────────────────────

  Future<void> addFallenItem({
    required String name,
    required String emoji,
    required double offsetX,
    required double offsetY,
  }) async {
    if (_plate == null) return;
    final item = await SupabaseService.addFallenItem(
      plateId: _plate!.id,
      name: name,
      emoji: emoji,
      offsetX: offsetX,
      offsetY: offsetY,
    );
    _plate = _plate!.copyWith(
      fallenItems: [..._plate!.fallenItems, item],
    );
    notifyListeners();
  }

  Future<void> deleteFallenItem(String id) async {
    if (_plate == null) return;
    await SupabaseService.deleteFallenItem(id);
    _plate = _plate!.copyWith(
      fallenItems: _plate!.fallenItems.where((f) => f.id != id).toList(),
    );
    notifyListeners();
  }

  // ─── Plate switching ──────────────────────────────────────────────────────

  Future<Plate> createNewPlate({String name = 'My Plate'}) async {
    final newPlate = await SupabaseService.createPlate(
      userId: _userId!,
      name: name,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_plate_id', newPlate.id);
    _plate = newPlate;
    _subscribeToRealtime();
    notifyListeners();
    return newPlate;
  }

  Future<void> switchToPlate(String plateId) async {
    final plate = await SupabaseService.getPlateById(plateId);
    if (plate == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_plate_id', plateId);
    _plate = plate;
    _subscribeToRealtime();
    notifyListeners();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }
}
