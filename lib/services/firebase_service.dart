import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'dart:convert';
import 'package:sivani_transport/models/app_user.dart';
import 'package:sivani_transport/models/driver.dart';
import 'package:sivani_transport/models/vehicle.dart';
import 'package:sivani_transport/models/trip.dart';
import 'package:sivani_transport/models/transporter.dart';
import 'package:sivani_transport/models/app_notification.dart';

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

  // Get user by email
  Future<AppUser?> getUserByEmail(String email) async {
    try {
      final query = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
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
      final isUpdate = driver.id.isNotEmpty;
      await _firestore.collection('users').doc(newDriver.id).set({
        ...newDriver.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 4. Create Notification
      await createNotification(AppNotification(
        id: '', title: isUpdate ? 'Driver Updated' : 'New Driver Added',
        message: 'Driver ${newDriver.name} has been ${isUpdate ? 'updated' : 'added'} by Admin.',
        timestamp: DateTime.now(), type: isUpdate ? 'driver_updated' : 'driver_added',
        role: 'Admin',
      ));
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
  Future<void> deleteDriver(String id, String name) async {
    try {
      // 1. Delete user record
      await deleteUser(id);

      // 2. Unassign driver from all their trips
      final tripSnap = await _firestore
          .collection('trips')
          .where('driverId', isEqualTo: id)
          .get();

      final batch = _firestore.batch();
      for (var doc in tripSnap.docs) {
        batch.update(doc.reference, {
          'driverId': '',
          'driver': '',
        });
      }
      await batch.commit();

      // 3. Notify Admin
      await createNotification(AppNotification(
        id: '', title: 'Driver Deleted',
        message: 'Driver $name has been removed by Admin.',
        timestamp: DateTime.now(), type: 'driver_deleted',
        role: 'Admin',
      ));
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

      final isUpdate = vehicle.id.isNotEmpty;
      await _firestore.collection('vehicles').doc(newVehicle.id).set({
        ...newVehicle.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await createNotification(AppNotification(
        id: '', title: isUpdate ? 'Vehicle Updated' : 'New Vehicle Added',
        message: 'Vehicle ${newVehicle.regNumber} has been ${isUpdate ? 'updated' : 'added'} by Admin.',
        timestamp: DateTime.now(), type: isUpdate ? 'vehicle_updated' : 'vehicle_added',
        role: 'Admin',
      ));
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteVehicle(String id, String regNumber) async {
    try {
      await _firestore.collection('vehicles').doc(id).delete();
      await createNotification(AppNotification(
        id: '', title: 'Vehicle Deleted',
        message: 'Vehicle $regNumber has been removed by Admin.',
        timestamp: DateTime.now(), type: 'vehicle_deleted',
        role: 'Admin',
      ));
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

      final isUpdate = transporter.id.isNotEmpty;
      await _firestore.collection('transporters').doc(newTransporter.id).set({
        ...newTransporter.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await createNotification(AppNotification(
        id: '', title: isUpdate ? 'Transporter Updated' : 'New Transporter Added',
        message: 'Transporter ${newTransporter.name} has been ${isUpdate ? 'updated' : 'added'} by Admin.',
        timestamp: DateTime.now(), type: isUpdate ? 'transporter_updated' : 'transporter_added',
        role: 'Admin',
      ));
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteTransporter(String id, String name) async {
    try {
      await _firestore.collection('transporters').doc(id).delete();
      await createNotification(AppNotification(
        id: '', title: 'Transporter Deleted',
        message: 'Transporter $name has been removed by Admin.',
        timestamp: DateTime.now(), type: 'transporter_deleted',
        role: 'Admin',
      ));
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

      final isUpdate = trip.id.isNotEmpty;
      await _firestore.collection('trips').doc(newTrip.id).set({
        ...newTrip.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Admin notification
      await createNotification(AppNotification(
        id: '', title: isUpdate ? 'Trip Updated' : 'New Trip Added',
        message: 'Trip from ${newTrip.from} to ${newTrip.to} has been ${isUpdate ? 'updated' : 'added'}.',
        timestamp: DateTime.now(), type: isUpdate ? 'trip_updated' : 'trip_added',
        role: 'Admin',
      ));

      // Driver notification if assigned
      if (newTrip.driverId != null) {
        await createNotification(AppNotification(
          id: '', title: isUpdate ? 'Assigned Trip Updated' : 'New Trip Assigned',
          message: isUpdate 
            ? 'Your trip to ${newTrip.to} has been updated by Admin.' 
            : 'You have been assigned a new trip to ${newTrip.to}.',
          timestamp: DateTime.now(), type: isUpdate ? 'assigned_trip_updated' : 'trip_assigned',
          role: 'Driver',
          targetUserId: newTrip.driverId,
        ));
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteTrip(String id, String route) async {
    try {
      await _firestore.collection('trips').doc(id).delete();
      await createNotification(AppNotification(
        id: '', title: 'Trip Deleted',
        message: 'Trip ($route) has been removed by Admin.',
        timestamp: DateTime.now(), type: 'trip_deleted',
        role: 'Admin',
      ));
    } catch (e) {
      rethrow;
    }
  }

  // --- NOTIFICATION METHODS ---

  Stream<List<AppNotification>> getNotifications(String role, String? userId) {
    Query query = _firestore.collection('notifications');
    
    if (role == 'Admin') {
      query = query.where('role', isEqualTo: 'Admin').limit(20);
    } else {
      query = query.where('targetUserId', isEqualTo: userId).limit(20);
    }

    return query.snapshots().map((snap) {
      final list = snap.docs.map((doc) => AppNotification.fromMap(doc.data() as Map<String, dynamic>)).toList();
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return list;
    });
  }

  Future<void> createNotification(AppNotification notification) async {
    final doc = _firestore.collection('notifications').doc();
    final newNotif = notification.copyWith(id: doc.id);
    await doc.set(newNotif.toMap());
  }

  Future<void> markAsRead(String id) async {
    await _firestore.collection('notifications').doc(id).update({'isRead': true});
  }

  Future<void> markAllAsRead(String role, String? userId) async {
    final query = (role == 'Admin')
        ? _firestore.collection('notifications').where('role', isEqualTo: 'Admin')
        : _firestore.collection('notifications').where('targetUserId', isEqualTo: userId);
    
    final snap = await query.get();
    final batch = _firestore.batch();
    for (var doc in snap.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  Future<void> clearNotifications(String role, String? userId) async {
    final query = (role == 'Admin')
        ? _firestore.collection('notifications').where('role', isEqualTo: 'Admin')
        : _firestore.collection('notifications').where('targetUserId', isEqualTo: userId);
    
    final snap = await query.get();
    final batch = _firestore.batch();
    for (var doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  Future<void> deleteNotification(String id) async {
    await _firestore.collection('notifications').doc(id).delete();
  }
}
