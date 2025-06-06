// Dart imports
import 'dart:async';

// Flutter imports
import 'package:flutter/foundation.dart';

// Package imports
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Project imports
import 'package:ottr/models/user_model.dart';
import 'package:ottr/utils/constants.dart';

/// Service responsible for handling authentication operations
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  
  // Current user
  User? get currentUser => _auth.currentUser;

  /// Sign in with Google
  Future<UserCredential> signInWithGoogle() async {
    try {
      // Begin interactive sign-in process
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        throw 'Google sign-in was canceled';
      }
      
      // Obtain auth details from request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      // Create credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      // Sign in with credential
      return await _auth.signInWithCredential(credential);
    } catch (e, stackTrace) {
      debugPrint('Error during Google sign-in: $e');
      debugPrintStack(stackTrace: stackTrace);
      throw 'Failed to sign in with Google. Please try again.';
    }
  }
  
  /// Check if a username is available
  Future<bool> isUsernameAvailable(String username) async {
    try {
      final String lowercaseUsername = username.toLowerCase();
      final usersSnapshot = await _firestore
          .collection(USERS_COLLECTION)
          .where('username', isEqualTo: lowercaseUsername)
          .get();
          
      return usersSnapshot.docs.isEmpty;
    } catch (e, stackTrace) {
      debugPrint('Error checking username availability: $e');
      debugPrintStack(stackTrace: stackTrace);
      throw 'Failed to check username availability. Please try again.';
    }
  }
  
  /// Create new user profile in Firestore
  Future<UserModel> createUserProfile({
    required String uid,
    required String username,
    required String displayName,
    required String email,
    required String photoUrl,
    String? fcmToken,
  }) async {
    try {
      final now = DateTime.now();
      final lowercaseUsername = username.toLowerCase();
      
      final userModel = UserModel(
        uid: uid,
        username: lowercaseUsername,
        displayName: displayName,
        email: email,
        photoUrl: photoUrl,
        fcmToken: fcmToken,
        createdAt: now,
        lastSeen: now,
        isOnline: true,
      );
      
      // Save to Firestore
      await _firestore
          .collection(USERS_COLLECTION)
          .doc(uid)
          .set(userModel.toFirestore());
          
      // Save username to shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(PREF_USER_ID, uid);
      await prefs.setString(PREF_USERNAME, lowercaseUsername);
      
      return userModel;
    } catch (e, stackTrace) {
      debugPrint('Error creating user profile: $e');
      debugPrintStack(stackTrace: stackTrace);
      throw 'Failed to create user profile. Please try again.';
    }
  }
  
  /// Get user by ID
  Future<UserModel?> getUserById(String uid) async {
    try {
      final docSnapshot = await _firestore
          .collection(USERS_COLLECTION)
          .doc(uid)
          .get();
          
      if (docSnapshot.exists && docSnapshot.data() != null) {
        return UserModel.fromFirestore(docSnapshot);
      }
      
      return null;
    } catch (e, stackTrace) {
      debugPrint('Error getting user by ID: $e');
      debugPrintStack(stackTrace: stackTrace);
      return null;
    }
  }
  
  /// Get user by username
  Future<UserModel?> getUserByUsername(String username) async {
    try {
      final lowercaseUsername = username.toLowerCase();
      
      final querySnapshot = await _firestore
          .collection(USERS_COLLECTION)
          .where('username', isEqualTo: lowercaseUsername)
          .limit(1)
          .get();
          
      if (querySnapshot.docs.isNotEmpty) {
        return UserModel.fromFirestore(querySnapshot.docs.first);
      }
      
      return null;
    } catch (e, stackTrace) {
      debugPrint('Error getting user by username: $e');
      debugPrintStack(stackTrace: stackTrace);
      return null;
    }
  }
  
  /// Update FCM token
  Future<void> updateFcmToken(String uid, String token) async {
    try {
      await _firestore
          .collection(USERS_COLLECTION)
          .doc(uid)
          .update({'fcmToken': token});
    } catch (e, stackTrace) {
      debugPrint('Error updating FCM token: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }
  
  /// Update user online status
  Future<void> updateOnlineStatus(String uid, bool isOnline) async {
    try {
      await _firestore
          .collection(USERS_COLLECTION)
          .doc(uid)
          .update({
            'isOnline': isOnline,
            'lastSeen': Timestamp.now(),
          });
    } catch (e, stackTrace) {
      debugPrint('Error updating online status: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }
  
  /// Sign out
  Future<void> signOut() async {
    try {
      final currentUid = currentUser?.uid;
      
      if (currentUid != null) {
        // Update online status
        await updateOnlineStatus(currentUid, false);
      }
      
      // Sign out from Firebase
      await _auth.signOut();
      
      // Sign out from Google
      await _googleSignIn.signOut();
    } catch (e, stackTrace) {
      debugPrint('Error during sign out: $e');
      debugPrintStack(stackTrace: stackTrace);
      throw 'Failed to sign out. Please try again.';
    }
  }
  
  /// Delete account
  Future<void> deleteAccount() async {
    try {
      final currentUid = currentUser?.uid;
      
      if (currentUid != null) {
        // Delete user data from Firestore
        await _firestore
            .collection(USERS_COLLECTION)
            .doc(currentUid)
            .delete();
      }
      
      // Delete Firebase account
      await currentUser?.delete();
      
      // Sign out from Google
      await _googleSignIn.signOut();
      
      // Clear shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e, stackTrace) {
      debugPrint('Error deleting account: $e');
      debugPrintStack(stackTrace: stackTrace);
      throw 'Failed to delete account. Please try again.';
    }
  }
}
