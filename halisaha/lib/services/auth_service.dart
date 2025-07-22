import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Giriş yapmış kullanıcıyı al
  User? get currentUser => _auth.currentUser;

  // Stream olarak auth durumunu dinle
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // E-posta/Şifre ile kayıt
  Future<UserCredential> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String facilityName,
    required String facilityAddress,
  }) async {
    try {
      // Firebase Auth ile kullanıcı oluştur
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Firestore'a kullanıcı bilgilerini kaydet
      await _firestore.collection('owners').doc(userCredential.user!.uid).set({
        'name': name,
        'email': email,
        'phone': phone,
        'facilityName': facilityName,
        'facilityAddress': facilityAddress,
        'createdAt': FieldValue.serverTimestamp(),
        'role': 'owner',
      });

      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  // E-posta/Şifre ile giriş
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Çıkış yap
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Kullanıcı bilgilerini getir
  Future<Map<String, dynamic>?> getUserData() async {
    if (currentUser == null) return null;
    
    DocumentSnapshot doc = await _firestore
        .collection('owners')
        .doc(currentUser!.uid)
        .get();
    
    return doc.data() as Map<String, dynamic>?;
  }

  // Sporcu kaydı
  Future<UserCredential> registerAthlete({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    try {
      // Firebase Auth ile kullanıcı oluştur
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Firestore'a kullanıcı bilgilerini kaydet
      await _firestore.collection('athletes').doc(userCredential.user!.uid).set({
        'name': name,
        'email': email,
        'phone': phone,
        'createdAt': FieldValue.serverTimestamp(),
        'role': 'athlete',
      });

      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  // Sporcu bilgilerini getir
  Future<Map<String, dynamic>?> getAthleteData() async {
    if (currentUser == null) return null;
    
    DocumentSnapshot doc = await _firestore
        .collection('athletes')
        .doc(currentUser!.uid)
        .get();
    
    return doc.data() as Map<String, dynamic>?;
  }
} 