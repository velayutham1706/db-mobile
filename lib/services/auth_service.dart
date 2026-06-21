import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'player_service.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GoogleSignIn _google = GoogleSignIn();

  User? _user;
  bool _initialising = true; // true until first authStateChanges event
  bool _syncing = false;
  String? _error;

  // Holds the Firestore live-sync subscription so we can cancel it on sign-out
  StreamSubscription<DocumentSnapshot>? _userDocSub;

  User? get user => _user;
  bool get initialising => _initialising;
  bool get syncing => _syncing;
  String? get error => _error;
  bool get isSignedIn => _user != null;

  AuthService() {
    _auth.authStateChanges().listen((u) {
      _user = u;
      _initialising = false;

      // Cancel previous live-sync if user signs out or switches accounts
      if (u == null) {
        _userDocSub?.cancel();
        _userDocSub = null;
      }

      notifyListeners();
    });
  }

  Future<void> signInEmail(String email, String pass) async {
    _error = null;
    _syncing = true;
    notifyListeners();
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: pass);
      // AuthGate reacts to authStateChanges — no manual navigation needed
    } on FirebaseAuthException catch (e) {
      _error = _friendly(e.code);
    } finally {
      _syncing = false;
      notifyListeners();
    }
  }

  Future<void> registerEmail(String email, String pass, String name) async {
    _error = null;
    _syncing = true;
    notifyListeners();
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
          email: email, password: pass);
      await cred.user?.updateDisplayName(name);
    } on FirebaseAuthException catch (e) {
      _error = _friendly(e.code);
    } finally {
      _syncing = false;
      notifyListeners();
    }
  }

  Future<void> signInGoogle() async {
    _error = null;
    _syncing = true;
    notifyListeners();
    try {
      final gUser = await _google.signIn();
      if (gUser == null) {
        _syncing = false;
        notifyListeners();
        return;
      }
      final gAuth = await gUser.authentication;
      final cred = GoogleAuthProvider.credential(
        accessToken: gAuth.accessToken,
        idToken: gAuth.idToken,
      );
      await _auth.signInWithCredential(cred);
    } catch (e) {
      _error = 'Google sign-in failed. Try again.';
    } finally {
      _syncing = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    _userDocSub?.cancel();
    _userDocSub = null;
    await _auth.signOut();
    await _google.signOut();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Called by AuthGate once after sign-in.
  // Sets up one-time load + attaches live-sync listener (cancels old one first).
  Future<void> loadUserData(PlayerService player) async {
    if (_user == null) return;
    _syncing = true;
    notifyListeners();

    try {
      final ref = _db.collection('users').doc(_user!.uid);
      final snap = await ref.get();

      if (!snap.exists) {
        await ref.set({'likedIds': [], 'playlists': []});
      } else {
        _applyUserDoc(snap.data()!, player);
      }

      // Cancel any existing listener before attaching a new one
      await _userDocSub?.cancel();
      _userDocSub = ref.snapshots().listen((s) {
        if (!s.exists) return;
        _applyUserDoc(s.data()!, player);
      });
    } catch (e) {
      debugPrint('AuthService: loadUserData failed — $e');
    } finally {
      _syncing = false;
      notifyListeners();
    }
  }

  void _applyUserDoc(Map<String, dynamic> data, PlayerService player) {
    final likedIds = List<int>.from(data['likedIds'] ?? []);
    final pls = (data['playlists'] as List? ?? [])
        .map((p) => PlaylistModel.fromMap(Map<String, dynamic>.from(p)))
        .toList();
    player.syncLiked(likedIds);
    player.setPlaylists(pls);
  }

  Future<void> saveUserData(PlayerService player) async {
    if (_user == null) return;
    final likedIds =
        player.tracks.where((t) => t.liked).map((t) => t.id).toList();
    final pls = player.playlists.map((p) => p.toMap()).toList();
    await _db.collection('users').doc(_user!.uid).set(
      {'likedIds': likedIds, 'playlists': pls},
      SetOptions(merge: true),
    );
  }

  String _friendly(String code) {
    const map = {
      'user-not-found': 'No account found with this email.',
      'wrong-password': 'Incorrect password.',
      'invalid-credential': 'Incorrect email or password.',
      'email-already-in-use': 'An account with this email already exists.',
      'weak-password': 'Password should be at least 6 characters.',
      'invalid-email': 'Please enter a valid email address.',
      'too-many-requests': 'Too many attempts. Try again later.',
    };
    return map[code] ?? 'Something went wrong. Please try again.';
  }

  @override
  void dispose() {
    _userDocSub?.cancel();
    super.dispose();
  }
}