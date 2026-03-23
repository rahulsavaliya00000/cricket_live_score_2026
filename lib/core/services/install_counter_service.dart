import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InstallCounterService {
  final SharedPreferences _prefs;
  final FirebaseFirestore _firestore;

  static const String _hasIncrementedKey = 'has_incremented_install';

  InstallCounterService(this._prefs, this._firestore);

  /// Increments the global install counter in Firestore once per install.
  Future<void> logInstallOnce() async {
    if (_prefs.getBool(_hasIncrementedKey) ?? false) {
      debugPrint('ℹ️ InstallCounter: Already incremented for this device.');
      return;
    }

    try {
      debugPrint('🚀 InstallCounter: Incrementing install count in Firestore...');
      
      // Using set with merge: true to ensure the document exists
      await _firestore.collection('install').doc('total').set({
        'current_install_two': FieldValue.increment(1),
      }, SetOptions(merge: true));

      await _prefs.setBool(_hasIncrementedKey, true);
      debugPrint('✅ InstallCounter: Install count successfully incremented.');
    } catch (e) {
      debugPrint('❌ InstallCounter: Failed to increment install count: $e');
    }
  }
}
