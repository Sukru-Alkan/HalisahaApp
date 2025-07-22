import 'package:flutter/material.dart';
import '../services/reservation_service.dart';
import '../services/auth_service.dart';

class FacilitySearchScreen extends StatefulWidget {
  const FacilitySearchScreen({super.key});

  @override
  State<FacilitySearchScreen> createState() => _FacilitySearchScreenState();
}

class _FacilitySearchScreenState extends State<FacilitySearchScreen> {
  final ReservationService _reservationService = ReservationService();
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;

  Future<void> _searchFacilities(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final results = await _reservationService.searchFacilities(query);
      setState(() => _searchResults = results);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showBookingDialog(Map<String, dynamic> facility) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BookingBottomSheet(
        facility: facility,
        authService: _authService,
        reservationService: _reservationService,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Arama çubuğu
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                onChanged: _searchFacilities,
                decoration: InputDecoration(
                  hintText: 'Halı saha ara...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _searchFacilities('');
                          },
                        )
                      : null,
                ),
              ),
            ),

            // Sonuçlar
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _searchResults.isEmpty
                      ? Center(
                          child: Text(
                            _searchController.text.isEmpty
                                ? 'Halı saha aramak için yukarıdaki arama çubuğunu kullanın'
                                : 'Sonuç bulunamadı',
                            style: const TextStyle(color: Colors.black54),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final facility = _searchResults[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
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
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                title: Text(
                                  facility['facilityName'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 8),
                                    Text(
                                      facility['facilityAddress'],
                                      style: const TextStyle(color: Colors.black54),
                                    ),
                                    const SizedBox(height: 12),
                                    ElevatedButton(
                                      onPressed: () => _showBookingDialog(facility),
                                      child: const Text('Rezervasyon Yap'),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class BookingBottomSheet extends StatefulWidget {
  final Map<String, dynamic> facility;
  final AuthService authService;
  final ReservationService reservationService;

  const BookingBottomSheet({
    super.key,
    required this.facility,
    required this.authService,
    required this.reservationService,
  });

  @override
  State<BookingBottomSheet> createState() => _BookingBottomSheetState();
}

class _BookingBottomSheetState extends State<BookingBottomSheet> {
  DateTime selectedDate = DateTime.now();
  String? selectedTimeSlot;
  bool isLoading = false;
  List<Map<String, dynamic>> reservations = [];

  final List<String> timeSlots = List.generate(
    14,
    (index) => '${(index + 8).toString().padLeft(2, '0')}:00',
  );

  @override
  void initState() {
    super.initState();
    _loadReservations();
  }

  Future<void> _loadReservations() async {
    setState(() => isLoading = true);
    try {
      final result = await widget.reservationService
          .getReservationsForDay(widget.facility['id'], selectedDate);
      setState(() => reservations = result);
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _makeReservation() async {
    if (selectedTimeSlot == null) return;

    final athleteData = await widget.authService.getAthleteData();
    if (athleteData == null) return;

    setState(() => isLoading = true);
    try {
      await widget.reservationService.createReservation(
        facilityId: widget.facility['id'],
        athleteId: widget.authService.currentUser!.uid,
        date: selectedDate,
        timeSlot: selectedTimeSlot!,
        athleteName: athleteData['name'],
        facilityName: widget.facility['facilityName'],
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rezervasyon başarıyla oluşturuldu')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rezervasyon oluşturulamadı')),
        );
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Başlık
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              widget.facility['facilityName'],
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Tarih seçici
          Container(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(
                  30,
                  (index) {
                    final date = DateTime.now().add(Duration(days: index));
                    final isSelected = DateUtils.isSameDay(date, selectedDate);
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedDate = date;
                          selectedTimeSlot = null;
                        });
                        _loadReservations();
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.white,
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
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${date.day}/${date.month}',
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // Saat seçici
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: timeSlots.length,
                    itemBuilder: (context, index) {
                      final timeSlot = timeSlots[index];
                      final isReserved = reservations.any(
                        (r) => r['timeSlot'] == timeSlot,
                      );
                      final isSelected = timeSlot == selectedTimeSlot;

                      return GestureDetector(
                        onTap: isReserved
                            ? null
                            : () => setState(
                                  () => selectedTimeSlot =
                                      isSelected ? null : timeSlot,
                                ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isReserved
                                ? Colors.grey.shade200
                                : isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              timeSlot,
                              style: TextStyle(
                                color: isReserved
                                    ? Colors.grey
                                    : isSelected
                                        ? Colors.white
                                        : Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Rezervasyon butonu
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed:
                  selectedTimeSlot == null || isLoading ? null : _makeReservation,
              child: SizedBox(
                width: double.infinity,
                child: Center(
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Rezervasyon Yap'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 