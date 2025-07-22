import 'package:cloud_firestore/cloud_firestore.dart';

class ReservationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Saha araması yapma
  Future<List<Map<String, dynamic>>> searchFacilities(String query) async {
    QuerySnapshot querySnapshot = await _firestore
        .collection('owners')
        .where('facilityName', isGreaterThanOrEqualTo: query)
        .where('facilityName', isLessThanOrEqualTo: query + '\uf8ff')
        .get();

    return querySnapshot.docs
        .map((doc) => {
              'id': doc.id,
              ...doc.data() as Map<String, dynamic>,
            })
        .toList();
  }

  // Belirli bir saatin müsait olup olmadığını kontrol etme
  Future<bool> isTimeSlotAvailable(String facilityId, DateTime date, String timeSlot) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    QuerySnapshot existingReservations = await _firestore
        .collection('reservations')
        .where('facilityId', isEqualTo: facilityId)
        .where('date', isEqualTo: Timestamp.fromDate(startOfDay))
        .where('timeSlot', isEqualTo: timeSlot)
        .where('status', isEqualTo: 'active')
        .get();

    return existingReservations.docs.isEmpty;
  }

  // Rezervasyon oluşturma
  Future<Map<String, dynamic>> createReservation({
    required String facilityId,
    required String athleteId,
    required DateTime date,
    required String timeSlot,
    required String athleteName,
    required String facilityName,
  }) async {
    // Önce saatin müsait olup olmadığını kontrol et
    bool isAvailable = await isTimeSlotAvailable(facilityId, date, timeSlot);
    if (!isAvailable) {
      throw FirebaseException(
        plugin: 'reservation',
        code: 'time-slot-taken',
        message: 'Bu saat dilimi zaten rezerve edilmiş.',
      );
    }

    // Rezervasyonu oluştur
    DocumentReference reservationRef = await _firestore.collection('reservations').add({
      'facilityId': facilityId,
      'athleteId': athleteId,
      'date': Timestamp.fromDate(DateTime(date.year, date.month, date.day)),
      'timeSlot': timeSlot,
      'athleteName': athleteName,
      'facilityName': facilityName,
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Oluşturulan rezervasyonu getir
    DocumentSnapshot reservationDoc = await reservationRef.get();
    return {
      'id': reservationDoc.id,
      ...reservationDoc.data() as Map<String, dynamic>,
    };
  }

  // Belirli bir gün için rezervasyonları gerçek zamanlı dinleme
  Stream<List<Map<String, dynamic>>> streamReservationsForDay(
      String facilityId, DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _firestore
        .collection('reservations')
        .where('facilityId', isEqualTo: facilityId)
        .where('date', isEqualTo: Timestamp.fromDate(startOfDay))
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => {
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              }).toList();
        });
  }

  // Belirli bir gün için rezervasyonları getirme
  Future<List<Map<String, dynamic>>> getReservationsForDay(
      String facilityId, DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);

    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('reservations')
          .where('facilityId', isEqualTo: facilityId)
          .where('date', isEqualTo: Timestamp.fromDate(startOfDay))
          .where('status', isEqualTo: 'active')
          .get();

      return querySnapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              })
          .toList();
    } catch (e) {
      print('Rezervasyon getirme hatası: $e');
      return [];
    }
  }

  // Sporcunun rezervasyonlarını getirme
  Future<List<Map<String, dynamic>>> getAthleteReservations(String athleteId) async {
    QuerySnapshot querySnapshot = await _firestore
        .collection('reservations')
        .where('athleteId', isEqualTo: athleteId)
        .where('status', isEqualTo: 'active')
        .get();

    final now = DateTime.now();
    
    return querySnapshot.docs
        .map((doc) => {
              'id': doc.id,
              ...doc.data() as Map<String, dynamic>,
            })
        .where((reservation) {
          final reservationDate = (reservation['date'] as Timestamp).toDate();
          return reservationDate.isAfter(now);
        })
        .toList()
        ..sort((a, b) {
          final dateA = (a['date'] as Timestamp).toDate();
          final dateB = (b['date'] as Timestamp).toDate();
          return dateA.compareTo(dateB);
        });
  }

  // Rezervasyon iptal etme
  Future<void> cancelReservation(String reservationId) async {
    await _firestore
        .collection('reservations')
        .doc(reservationId)
        .update({'status': 'cancelled'});
  }

  // Müsait saat dilimlerini getirme
  Future<List<String>> getAvailableTimeSlots(String facilityId, DateTime date) async {
    // Tüm saat dilimleri
    final allTimeSlots = [
      '09:00', '10:00', '11:00', '12:00', '13:00', '14:00',
      '15:00', '16:00', '17:00', '18:00', '19:00', '20:00',
      '21:00', '22:00', '23:00'
    ];

    // O gün için mevcut rezervasyonları getir
    final reservations = await getReservationsForDay(facilityId, date);
    
    // Rezerve edilmiş saatleri çıkar
    final reservedSlots = reservations.map((r) => r['timeSlot'] as String).toSet();
    
    // Müsait saatleri döndür
    return allTimeSlots.where((slot) => !reservedSlots.contains(slot)).toList();
  }
} 