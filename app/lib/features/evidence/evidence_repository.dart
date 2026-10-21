import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/firebase_bootstrap.dart';
import '../auth/auth_service.dart';
import '../home_profile/home_profile.dart';

enum EvidenceType { photo, note, symptom, check, letter }

class EvidenceItem {
  const EvidenceItem({
    required this.id,
    required this.type,
    required this.text,
    required this.deleted,
    this.storagePath,
    this.sha256,
    this.serverTime,
    this.createdAt,
    this.checkId,
    this.letterId,
  });

  final String id;
  final EvidenceType type;
  final String text;
  final bool deleted;
  final String? storagePath;

  /// Set ONLY by the onEvidenceCreated Cloud Function (security rules block
  /// clients from writing them). Present = "verified".
  final String? sha256;
  final DateTime? serverTime;
  final DateTime? createdAt;
  final String? checkId;
  final String? letterId;

  bool get verified => sha256 != null && serverTime != null;

  static EvidenceItem fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    return EvidenceItem(
      id: doc.id,
      type: EvidenceType.values.firstWhere((t) => t.name == d['type'], orElse: () => EvidenceType.note),
      text: d['text'] as String? ?? '',
      deleted: d['deleted'] == true,
      storagePath: d['storagePath'] as String?,
      sha256: d['sha256'] as String?,
      serverTime: (d['serverTime'] as Timestamp?)?.toDate(),
      // While a write is pending offline, the server timestamp is null; use
      // the local estimate so the timeline order stays sensible.
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ??
          (doc.metadata.hasPendingWrites ? DateTime.now() : null),
      checkId: d['checkId'] as String?,
      letterId: d['letterId'] as String?,
    );
  }
}

class NotSignedInException implements Exception {}

class EvidenceRepository {
  EvidenceRepository(this._ref);
  final Ref _ref;

  ({String uid, String homeId}) _owner() {
    final user = _ref.read(currentUserProvider);
    if (user == null || !_ref.read(firebaseAvailableProvider)) throw NotSignedInException();
    return (uid: user.uid, homeId: _ref.read(homeProfileProvider).id);
  }

  CollectionReference<Map<String, dynamic>> _collection(String uid, String homeId) =>
      FirebaseFirestore.instance.collection('users/$uid/homes/$homeId/evidence');

  Stream<List<EvidenceItem>> watch() {
    final o = _owner();
    return _collection(o.uid, o.homeId)
        .orderBy('createdAt', descending: true)
        .snapshots(includeMetadataChanges: true)
        .map((s) => [for (final d in s.docs) EvidenceItem.fromDoc(d)].where((e) => !e.deleted).toList());
  }

  /// Notes and symptoms. Works offline (queued by Firestore).
  Future<String> addText(EvidenceType type, String text, {String? checkId}) async {
    assert(type != EvidenceType.photo && type != EvidenceType.letter); // Letters: server only.
    final o = _owner();
    final doc = _collection(o.uid, o.homeId).doc();
    await _ensureHome(o.uid, o.homeId);
    await doc.set({
      'type': type.name,
      'text': text,
      'checkId': ?checkId,
      'deleted': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  /// Uploads the photo to the user's private Storage path FIRST, then creates
  /// the evidence document, so the hashing function always finds the file.
  Future<String> addPhoto(XFile photo, {String caption = ''}) async {
    final o = _owner();
    await _ensureHome(o.uid, o.homeId);
    final doc = _collection(o.uid, o.homeId).doc();
    final path = 'users/${o.uid}/homes/${o.homeId}/evidence/${doc.id}/photo.jpg';
    final bytes = await photo.readAsBytes();
    await FirebaseStorage.instance.ref(path).putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    await doc.set({
      'type': EvidenceType.photo.name,
      'text': caption,
      'storagePath': path,
      'deleted': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  /// Evidence is never edited. "Delete" only hides it (rules enforce this).
  Future<void> markDeleted(String itemId) async {
    final o = _owner();
    await _collection(o.uid, o.homeId).doc(itemId).update({
      'deleted': true,
      'deletedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Photos are read through Storage security rules (no public download URLs).
  Future<Uint8List?> photoBytes(String storagePath) =>
      FirebaseStorage.instance.ref(storagePath).getData(15 * 1024 * 1024);

  /// The home document must exist before children are written so that
  /// reports and exports find it.
  Future<void> _ensureHome(String uid, String homeId) async {
    final profile = _ref.read(homeProfileProvider);
    await FirebaseFirestore.instance
        .doc('users/$uid/homes/$homeId')
        .set(profile.toFirestore(), SetOptions(merge: true));
  }
}

final evidenceRepositoryProvider = Provider<EvidenceRepository>(EvidenceRepository.new);

final evidenceStreamProvider = StreamProvider.autoDispose<List<EvidenceItem>>((ref) {
  ref.watch(currentUserProvider);
  ref.watch(homeProfileProvider.select((p) => p.id));
  return ref.watch(evidenceRepositoryProvider).watch();
});
