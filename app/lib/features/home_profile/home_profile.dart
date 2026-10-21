import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/firebase_bootstrap.dart';
import '../../core/settings.dart';
import '../auth/auth_service.dart';

/// Values are stored as stable ids (never translated text) so that rules,
/// Firestore and analytics stay language independent.
class HomeProfile {
  const HomeProfile({
    required this.id,
    this.role,
    this.district,
    this.buildingAgeBand,
    this.heatingType,
    this.heaterLocation,
    this.hasCoAlarm,
    this.hasWrittenContract,
  });

  final String id;
  final String? role; // renter | owner
  final String? district; // binagadi | ... | other
  final String? buildingAgeBand; // before_1960 | 1960_1990 | 1991_2010 | after_2010
  final String? heatingType; // individual_gas_heater | gas_boiler | central_heating | electric | other
  final String? heaterLocation; // bathroom | kitchen | other | none
  final String? hasCoAlarm; // yes | no | not_sure
  final bool? hasWrittenContract; // renters only

  static const districts = [
    'binagadi', 'garadagh', 'khatai', 'khazar', 'narimanov', 'nasimi', 'nizami',
    'pirallahi', 'sabail', 'sabunchu', 'surakhani', 'yasamal', 'other',
  ];

  bool get isComplete =>
      role != null && district != null && buildingAgeBand != null && heatingType != null &&
      heaterLocation != null && hasCoAlarm != null && (role != 'renter' || hasWrittenContract != null);

  /// Answers the rules engine can read directly (field names match rules).
  Map<String, Object?> toRuleAnswers() => {
        'heating_type': ?heatingType,
        'heater_location': ?heaterLocation,
        'has_co_alarm': ?hasCoAlarm,
        'building_age_band': ?buildingAgeBand,
      };

  Map<String, Object?> toFirestore() => {
        'district': district,
        'buildingAgeBand': buildingAgeBand,
        'heatingType': heatingType,
        'heaterLocation': heaterLocation,
        'hasCoAlarm': hasCoAlarm,
        'hasWrittenContract': hasWrittenContract,
      };

  Map<String, Object?> toJson() => {'id': id, 'role': role, ...toFirestore()};

  static HomeProfile fromJson(Map<String, Object?> j, {String? id, String? role}) => HomeProfile(
        id: id ?? j['id'] as String,
        role: role ?? j['role'] as String?,
        district: j['district'] as String?,
        buildingAgeBand: j['buildingAgeBand'] as String?,
        heatingType: j['heatingType'] as String?,
        heaterLocation: j['heaterLocation'] as String?,
        hasCoAlarm: j['hasCoAlarm'] as String?,
        hasWrittenContract: j['hasWrittenContract'] as bool?,
      );

  HomeProfile copyWith({
    String? role,
    String? district,
    String? buildingAgeBand,
    String? heatingType,
    String? heaterLocation,
    String? hasCoAlarm,
    bool? hasWrittenContract,
  }) =>
      HomeProfile(
        id: id,
        role: role ?? this.role,
        district: district ?? this.district,
        buildingAgeBand: buildingAgeBand ?? this.buildingAgeBand,
        heatingType: heatingType ?? this.heatingType,
        heaterLocation: heaterLocation ?? this.heaterLocation,
        hasCoAlarm: hasCoAlarm ?? this.hasCoAlarm,
        hasWrittenContract: hasWrittenContract ?? this.hasWrittenContract,
      );
}

String newId() {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  final rnd = Random.secure();
  return List.generate(20, (_) => chars[rnd.nextInt(chars.length)]).join();
}

/// The current home. Saved locally (works for guests and offline) and, when
/// signed in, mirrored to users/{uid}/homes/{homeId}.
class HomeProfileController extends Notifier<HomeProfile> {
  static const _key = 'home.profile';

  @override
  HomeProfile build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final raw = prefs.getString(_key);
    final local = raw == null ? null : HomeProfile.fromJson(jsonDecode(raw) as Map<String, Object?>);

    // When a user signs in on a fresh install, pull their home from Firestore.
    // Deferred with a microtask because state cannot change during build().
    ref.listen(currentUserProvider, (prev, user) {
      if (user != null && prev?.uid != user.uid) Future.microtask(() => _syncFromCloud(user.uid));
    }, fireImmediately: true);

    if (local != null) return local;
    final fresh = HomeProfile(id: newId());
    prefs.setString(_key, jsonEncode(fresh.toJson()));
    return fresh;
  }

  Future<void> save(HomeProfile profile) async {
    state = profile;
    await ref.read(sharedPreferencesProvider).setString(_key, jsonEncode(profile.toJson()));
    final user = ref.read(currentUserProvider);
    if (user == null || !ref.read(firebaseAvailableProvider)) return;
    final db = FirebaseFirestore.instance;
    try {
      // Writes are queued offline by Firestore and sent when back online.
      await db.doc('users/${user.uid}/homes/${profile.id}').set(profile.toFirestore(), SetOptions(merge: true));
      if (profile.role != null) await db.doc('users/${user.uid}').update({'role': profile.role});
    } catch (e) {
      debugPrint('profile sync failed (will retry when online): $e');
    }
  }

  Future<void> _syncFromCloud(String uid) async {
    if (state.isComplete || !ref.read(firebaseAvailableProvider)) {
      if (state.isComplete) await save(state); // Upload a guest profile after sign-in.
      return;
    }
    try {
      final db = FirebaseFirestore.instance;
      final homes = await db.collection('users/$uid/homes').limit(1).get();
      if (homes.docs.isEmpty) return;
      final user = await db.doc('users/$uid').get();
      final home = homes.docs.first;
      state = HomeProfile.fromJson(home.data(), id: home.id, role: user.data()?['role'] as String?);
      await ref.read(sharedPreferencesProvider).setString(_key, jsonEncode(state.toJson()));
    } catch (e) {
      debugPrint('profile download failed: $e');
    }
  }

  /// Used after "delete my account".
  Future<void> clearLocal() async {
    await ref.read(sharedPreferencesProvider).remove(_key);
    ref.invalidateSelf();
  }
}

final homeProfileProvider = NotifierProvider<HomeProfileController, HomeProfile>(HomeProfileController.new);
