import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'facility_schedule_screen.dart';

class FacilityOwnerHomeScreen extends StatefulWidget {
  const FacilityOwnerHomeScreen({super.key});

  @override
  State<FacilityOwnerHomeScreen> createState() => _FacilityOwnerHomeScreenState();
}

class _FacilityOwnerHomeScreenState extends State<FacilityOwnerHomeScreen> {
  final AuthService _authService = AuthService();
  Map<String, dynamic>? _ownerData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOwnerData();
  }

  Future<void> _loadOwnerData() async {
    try {
      final data = await _authService.getUserData();
      setState(() {
        _ownerData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_ownerData == null) {
      return const Scaffold(
        body: Center(child: Text('Kullanıcı bilgileri yüklenemedi')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_ownerData!['facilityName']),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authService.signOut();
              if (mounted) {
                Navigator.of(context).pushReplacementNamed('/welcome');
              }
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tesis Bilgileri
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tesis Bilgileri',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _infoRow('İsim', _ownerData!['name']),
                _infoRow('E-posta', _ownerData!['email']),
                _infoRow('Telefon', _ownerData!['phone']),
                _infoRow('Adres', _ownerData!['facilityAddress']),
              ],
            ),
          ),

          // Saha Durumu başlığı
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Saha Durumu',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Rezervasyon takvimi
          Expanded(
            child: FacilityScheduleScreen(
              facilityId: _authService.currentUser!.uid,
              facilityName: _ownerData!['facilityName'],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 