import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'dart:convert';
import 'package:sivani_transport/models/app_user.dart';
import 'package:sivani_transport/models/driver.dart';
import 'package:sivani_transport/models/vehicle.dart';
import 'package:sivani_transport/models/trip.dart';
import 'package:sivani_transport/models/transporter.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Auth stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in
  Future<UserCredential?> signIn(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      rethrow;
    }
  }

  // Register User directly in Firestore
  Future<void> registerUser(AppUser user) async {
    try {
      // Use the provided ID or generate a custom one if empty
      String userId = user.id.isEmpty 
          ? 'USR-${DateTime.now().millisecondsSinceEpoch}' 
          : user.id;
      
      final newUser = user.copyWith(id: userId);

      // Save everything to Firestore (including password)
      await _firestore.collection('users').doc(newUser.id).set({
        ...newUser.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Simple login check against Firestore
  Future<AppUser?> login(String email, String password) async {
    try {
      final query = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .where('password', isEqualTo: password)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return AppUser.fromMap(query.docs.first.data());
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Get Users
  Stream<List<AppUser>> getUsers() {
    return _firestore
        .collection('users')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => AppUser.fromMap(doc.data())).toList());
  }

  // Delete User
  Future<void> deleteUser(String id) async {
    try {
      await _firestore.collection('users').doc(id).delete();
    } catch (e) {
      rethrow;
    }
  }

  // Update User Profile
  Future<void> updateUserProfile(AppUser user) async {
    try {
      await _firestore.collection('users').doc(user.id).set({
        ...user.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      rethrow;
    }
  }

  // --- DRIVER METHODS ---

  // Get Drivers (Filtered by role)
  Stream<List<Driver>> getDrivers() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'Driver')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Driver.fromMap(doc.data())).toList());
  }

  // Save/Update Driver
  Future<void> saveDriver(Driver driver) async {
    try {
      // 1. Generate/Verify ID
      String driverId = driver.id.isEmpty 
          ? 'DRV-${DateTime.now().millisecondsSinceEpoch}' 
          : driver.id;
      
      String? imageBase64 = driver.image;

      // 2. Convert Image to Base64 if a new one was picked
      if (driver.pickedImage != null) {
        imageBase64 = await _convertImageToBase64(driver.pickedImage!.path);
      }

      final newDriver = driver.copyWith(
        id: driverId,
        image: imageBase64,
      );

      // 3. Save to Firestore
      await _firestore.collection('users').doc(newDriver.id).set({
        ...newDriver.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Internal helper to convert image file to Base64 string
  Future<String> _convertImageToBase64(String filePath) async {
    try {
      final bytes = await File(filePath).readAsBytes();
      return base64Encode(bytes);
    } catch (e) {
      rethrow;
    }
  }

  // Delete Driver
  Future<void> deleteDriver(String id) async {
    try {
      await deleteUser(id);
    } catch (e) {
      rethrow;
    }
  }

  // --- VEHICLE METHODS ---

  Stream<List<Vehicle>> getVehicles() {
    return _firestore
        .collection('vehicles')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Vehicle.fromMap(doc.data())).toList());
  }

  Future<void> saveVehicle(Vehicle vehicle) async {
    try {
      String vehicleId = vehicle.id.isEmpty 
          ? 'VEH-${DateTime.now().millisecondsSinceEpoch}' 
          : vehicle.id;
      
      String? imageBase64 = vehicle.image;

      if (vehicle.pickedImage != null) {
        imageBase64 = await _convertImageToBase64(vehicle.pickedImage!.path);
      }

      final newVehicle = vehicle.copyWith(
        id: vehicleId,
        image: imageBase64,
      );

      await _firestore.collection('vehicles').doc(newVehicle.id).set({
        ...newVehicle.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteVehicle(String id) async {
    try {
      await _firestore.collection('vehicles').doc(id).delete();
    } catch (e) {
      rethrow;
    }
  }

  // --- TRANSPORTER METHODS ---

  Stream<List<Transporter>> getTransporters() {
    return _firestore
        .collection('transporters')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Transporter.fromMap(doc.data())).toList());
  }

  Future<void> saveTransporter(Transporter transporter) async {
    try {
      String transporterId = transporter.id.isEmpty 
          ? 'TRN-${DateTime.now().millisecondsSinceEpoch}' 
          : transporter.id;
      
      String? imageBase64 = transporter.image;

      if (transporter.pickedImage != null) {
        imageBase64 = await _convertImageToBase64(transporter.pickedImage!.path);
      }

      final newTransporter = transporter.copyWith(
        id: transporterId,
        image: imageBase64,
      );

      await _firestore.collection('transporters').doc(newTransporter.id).set({
        ...newTransporter.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteTransporter(String id) async {
    try {
      await _firestore.collection('transporters').doc(id).delete();
    } catch (e) {
      rethrow;
    }
  }

  // --- TRIP METHODS ---

  Stream<List<Trip>> getTrips() {
    return _firestore
        .collection('trips')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Trip.fromMap(doc.data())).toList());
  }

  Future<void> saveTrip(Trip trip) async {
    try {
      String tripId = trip.id.isEmpty 
          ? 'TRP-${DateTime.now().millisecondsSinceEpoch}' 
          : trip.id;
      
      final newTrip = trip.copyWith(id: tripId);

      await _firestore.collection('trips').doc(newTrip.id).set({
        ...newTrip.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteTrip(String id) async {
    try {
      await _firestore.collection('trips').doc(id).delete();
    } catch (e) {
      rethrow;
    }
  }
}
