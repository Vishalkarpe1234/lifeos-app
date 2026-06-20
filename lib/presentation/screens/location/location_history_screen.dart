import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';
import 'package:lifeos/config/theme/app_theme.dart';
import 'package:lifeos/services/api/api_client.dart';
import 'package:lifeos/services/location_service.dart';

final _locationHistoryProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.watch(dioProvider);
  final r = await dio.get(
    '/api/v1/location/history',
    queryParameters: {'page_size': 200},
  );
  return List<Map<String, dynamic>>.from(r.data['items']);
});

class LocationHistoryScreen extends ConsumerStatefulWidget {
  const LocationHistoryScreen({super.key});

  @override
  ConsumerState<LocationHistoryScreen> createState() =>
      _LocationHistoryScreenState();
}

class _LocationHistoryScreenState
    extends ConsumerState<LocationHistoryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final MapController _mapController = MapController();

  // Live tab
  Position? _currentPosition;
  bool _loadingLive = false;
  bool _acquiringFix = false; // true while fresh getCurrentPosition is in flight
  DateTime? _lastUpdated;
  bool _permissionGranted = false;
  bool _trackingEnabled = false;
  StreamSubscription<Position>? _liveStream;

  // Geocode cache: item id -> address string
  final Map<int, String> _addressCache = {};
  Timer? _geocodeTimer;

  // Find-by-time tab
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  Map<String, dynamic>? _foundLocation;
  bool _searching = false;
  String? _searchError;
  String? _foundAddress;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _checkPermissionAndLoad();
  }

  Future<void> _checkPermissionAndLoad() async {
    // Always check actual Android permission — stored flag can be stale
    // (user may have revoked in Android Settings after we stored 'true')
    final perm = await Geolocator.checkPermission();
    final granted = perm == LocationPermission.always ||
        perm == LocationPermission.whileInUse;
    if (mounted) setState(() => _permissionGranted = granted);
    if (!granted) return;

    // Also verify GPS service is on
    final serviceOn = await Geolocator.isLocationServiceEnabled();
    if (!serviceOn) {
      // Prompt user to enable GPS; don't crash
      await Geolocator.openLocationSettings();
      return;
    }

    _startLiveStream(); // stream first — keeps GPS warm
    _getLiveLocation(); // hard fix to centre map immediately
  }

  /// Starts a GPS position stream that updates the map in real-time.
  void _startLiveStream() {
    _liveStream?.cancel();
    _liveStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // update map on every 5 m of movement
      ),
    ).listen(
      (pos) {
        if (!mounted) return;
        setState(() {
          _currentPosition = pos;
          _lastUpdated = DateTime.now();
          _loadingLive = false;
        });
        try {
          _mapController.move(
              LatLng(pos.latitude, pos.longitude), _mapController.camera.zoom);
        } catch (_) {}
      },
      onError: (_) {},
      cancelOnError: false,
    );
  }

  @override
  void dispose() {
    _tabs.dispose();
    _geocodeTimer?.cancel();
    _liveStream?.cancel();
    super.dispose();
  }

  Future<void> _requestPermissionAndTrack() async {
    setState(() => _loadingLive = true);
    try {
      final dio = ref.read(dioProvider);
      final ok = await LocationService.requestAndGrant(dio, context: context);
      if (mounted) {
        setState(() {
          _permissionGranted = ok;
          _trackingEnabled = ok;
          _loadingLive = false;
        });
        if (ok) {
          _getLiveLocation();
          _startLiveStream();
        }
      }
    } catch (_) {
      if (mounted) setState(() => _loadingLive = false);
    }
  }

  /// Hard refresh: show last-known quickly (if fresh), then force a new GPS fix.
  Future<void> _getLiveLocation() async {
    if (!_permissionGranted) {
      _requestPermissionAndTrack();
      return;
    }
    setState(() { _loadingLive = true; _acquiringFix = true; });

    // Stage 1: last-known — ONLY use if it is less than 5 minutes old.
    // Older cached positions are in the wrong place and confuse the user.
    try {
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) {
        final ageMin = DateTime.now().difference(last.timestamp).inMinutes;
        if (ageMin < 5 && mounted) {
          setState(() {
            _currentPosition = last;
            _lastUpdated = DateTime.now();
            _loadingLive = false;
            // _acquiringFix stays true — fresh fix still in flight
          });
          try { _mapController.move(LatLng(last.latitude, last.longitude), 15); } catch (_) {}
        }
      }
    } catch (_) {}

    // Stage 2: force a fresh GPS fix (high accuracy, 45 s timeout)
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 45),
        ),
      );
      if (mounted) {
        setState(() {
          _currentPosition = pos;
          _lastUpdated = DateTime.now();
          _loadingLive = false;
          _acquiringFix = false;
        });
        try { _mapController.move(LatLng(pos.latitude, pos.longitude), 15); } catch (_) {}
      }
    } catch (_) {
      if (mounted) setState(() { _loadingLive = false; _acquiringFix = false; });
    }
  }

  Future<String?> _geocodeItem(int id, double lat, double lon) async {
    if (_addressCache.containsKey(id)) return _addressCache[id];
    try {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 8),
        headers: {'User-Agent': 'VK-OS-App/2.3 (contact@vkos.app)'},
      ));
      final r = await dio.get(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {
          'lat': lat,
          'lon': lon,
          'format': 'json',
          'zoom': 16,
        },
      );
      final addr = r.data['display_name']?.toString() ?? '';
      if (addr.isNotEmpty && mounted) {
        setState(() => _addressCache[id] = addr);
      }
      return addr.isEmpty ? null : addr;
    } catch (_) {
      return null;
    }
  }

  void _startGeocoding(List<Map<String, dynamic>> items) {
    _geocodeTimer?.cancel();
    final unresolved = items
        .where((item) => !_addressCache.containsKey(item['id'] as int))
        .toList();
    if (unresolved.isEmpty) return;
    int idx = 0;
    _geocodeTimer = Timer.periodic(const Duration(seconds: 1), (t) async {
      if (!mounted || idx >= unresolved.length) {
        t.cancel();
        return;
      }
      final item = unresolved[idx];
      final id = item['id'] as int;
      await _geocodeItem(
        id,
        (item['latitude'] as num).toDouble(),
        (item['longitude'] as num).toDouble(),
      );
      idx++;
    });
  }

  Future<void> _findByTime() async {
    setState(() {
      _searching = true;
      _foundLocation = null;
      _searchError = null;
      _foundAddress = null;
    });
    try {
      final dt = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      ).toUtc();
      final r = await ref.read(dioProvider).get(
        '/api/v1/location/history/at',
        queryParameters: {'timestamp': dt.toIso8601String()},
      );
      if (mounted) {
        setState(() {
          _foundLocation = Map<String, dynamic>.from(r.data);
          _searching = false;
        });
        // Geocode the result
        final addr = await _geocodeItem(
          0,
          (_foundLocation!['latitude'] as num).toDouble(),
          (_foundLocation!['longitude'] as num).toDouble(),
        );
        if (mounted) setState(() => _foundAddress = addr);
      }
    } on DioException catch (e) {
      final msg = e.response?.statusCode == 404
          ? 'No location data found for this time'
          : 'Failed to fetch location';
      if (mounted) setState(() { _searchError = msg; _searching = false; });
    } catch (e) {
      if (mounted) setState(() { _searchError = e.toString(); _searching = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        title: const Text('Location'),
        bottom: TabBar(
          controller: _tabs,
          labelStyle: const TextStyle(
              fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 13),
          unselectedLabelStyle:
              const TextStyle(fontFamily: 'Inter', fontSize: 13),
          indicatorColor: C.primary,
          labelColor: C.primary,
          unselectedLabelColor: C.textSub,
          tabs: const [
            Tab(text: 'Live'),
            Tab(text: 'History'),
            Tab(text: 'Find'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _buildLiveTab(),
          _buildHistoryTab(),
          _buildFindTab(),
        ],
      ),
    );
  }

  // ───────────── TAB 1: LIVE ─────────────

  Widget _buildLiveTab() {
    // Not yet granted — show enable button
    if (!_permissionGranted) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(width: 80, height: 80,
            decoration: BoxDecoration(color: C.primary.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.location_on_rounded, color: C.primary, size: 40)),
          const SizedBox(height: 20),
          const Text('Enable Location Tracking', textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w800, fontSize: 20, color: C.text)),
          const SizedBox(height: 12),
          const Text(
            'Allow location access to see your live position and save your location history.',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: C.textSub, height: 1.5)),
          const SizedBox(height: 28),
          SizedBox(width: double.infinity, height: 50, child: ElevatedButton.icon(
            onPressed: _loadingLive ? null : _requestPermissionAndTrack,
            icon: _loadingLive
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Icon(Icons.location_on_rounded),
            label: Text(_loadingLive ? 'Enabling...' : 'Enable Location',
              style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 16)),
          )),
          const SizedBox(height: 16),
          const Text(
            'You will see ONE location permission dialog from Android.\nThis is normal — just tap "Allow".',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: C.textMuted, height: 1.5)),
        ]),
      ));
    }

    return Column(children: [
      Expanded(
        flex: 3,
        child: _currentPosition == null
            ? Center(
                child: _loadingLive
                    ? const CircularProgressIndicator()
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.location_off_rounded,
                              color: C.textMuted, size: 48),
                          const SizedBox(height: 12),
                          const Text('Getting your location...',
                              style: TextStyle(
                                  fontFamily: 'Inter', color: C.textSub)),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _getLiveLocation,
                            icon: const Icon(Icons.my_location_rounded),
                            label: const Text('Refresh'),
                          ),
                        ],
                      ),
              )
            : Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: LatLng(
                        _currentPosition!.latitude,
                        _currentPosition!.longitude,
                      ),
                      initialZoom: 15,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
                        userAgentPackageName: 'com.vishalkarpe.lifeos',
                      ),
                      // Accuracy radius circle
                      CircleLayer(circles: [
                        CircleMarker(
                          point: LatLng(
                            _currentPosition!.latitude,
                            _currentPosition!.longitude,
                          ),
                          radius: _currentPosition!.accuracy,
                          useRadiusInMeter: true,
                          color: C.primary.withOpacity(0.10),
                          borderColor: C.primary.withOpacity(0.45),
                          borderStrokeWidth: 1.5,
                        ),
                      ]),
                      MarkerLayer(markers: [
                        Marker(
                          point: LatLng(
                            _currentPosition!.latitude,
                            _currentPosition!.longitude,
                          ),
                          width: 44,
                          height: 44,
                          child: Container(
                            decoration: BoxDecoration(
                              color: _accuracyColor(),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: _accuracyColor().withOpacity(0.4),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                )
                              ],
                            ),
                            child: const Icon(Icons.person_rounded,
                                color: Colors.white, size: 22),
                          ),
                        ),
                      ]),
                    ],
                  ),
                  // "Acquiring precise fix…" badge overlay
                  if (_acquiringFix)
                    Positioned(
                      top: 10, left: 0, right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.65),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(mainAxisSize: MainAxisSize.min, children: [
                            SizedBox(
                              width: 12, height: 12,
                              child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                            ),
                            SizedBox(width: 8),
                            Text('Acquiring precise location…',
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'Inter',
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                          ]),
                        ),
                      ),
                    ),
                ],
              ),
      ),

      // Info panel
      Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
        child: Column(children: [
          Row(children: [
            Container(
              width: 10, height: 10,
              decoration: BoxDecoration(
                  color: _currentPosition != null ? _accuracyColor() : C.textMuted,
                  shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              _acquiringFix ? 'Acquiring GPS…' : 'Live Location',
              style: const TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: C.text)),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.my_location_rounded, color: C.primary),
              onPressed: (_loadingLive && _currentPosition == null) ? null : _getLiveLocation,
              tooltip: 'Hard refresh GPS',
            ),
          ]),
          if (_currentPosition != null) ...[
            const SizedBox(height: 8),
            _infoRow(Icons.gps_fixed_rounded, 'Coordinates',
                '${_currentPosition!.latitude.toStringAsFixed(6)}, ${_currentPosition!.longitude.toStringAsFixed(6)}'),
            const SizedBox(height: 4),
            _infoRow(Icons.radar_rounded, 'Accuracy', _accuracyLabel(),
                valueColor: _accuracyColor()),
            if (_lastUpdated != null) ...[
              const SizedBox(height: 4),
              _infoRow(Icons.schedule_rounded, 'Updated',
                  _fmtTime(_lastUpdated!)),
            ],
            const SizedBox(height: 10),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: C.primary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Map updates in real-time as you move. Location is saved automatically whenever you move 50 m or every 5 minutes.',
                style: TextStyle(
                    fontFamily: 'Inter', fontSize: 11, color: C.textSub),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ]),
      ),
    ]);
  }

  Color _accuracyColor() {
    if (_currentPosition == null) return C.textMuted;
    final acc = _currentPosition!.accuracy;
    if (acc <= 20) return C.success;
    if (acc <= 100) return const Color(0xFFF57C00); // orange
    return C.error;
  }

  String _accuracyLabel() {
    if (_currentPosition == null) return '-';
    final acc = _currentPosition!.accuracy;
    if (acc <= 10) return '±${acc.toStringAsFixed(0)} m  (Excellent)';
    if (acc <= 30) return '±${acc.toStringAsFixed(0)} m  (Good)';
    if (acc <= 100) return '±${acc.toStringAsFixed(0)} m  (Fair)';
    return '±${acc.toStringAsFixed(0)} m  (Low — move outdoors)';
  }

  Widget _infoRow(IconData icon, String label, String value,
      {Color? valueColor}) =>
      Row(children: [
        Icon(icon, size: 14, color: C.textMuted),
        const SizedBox(width: 6),
        Text('$label: ',
            style: const TextStyle(
                fontFamily: 'Inter', fontSize: 12, color: C.textMuted)),
        Expanded(
            child: Text(value,
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? C.text),
                overflow: TextOverflow.ellipsis)),
      ]);

  // ───────────── TAB 2: HISTORY ─────────────

  Widget _buildHistoryTab() {
    final asyncData = ref.watch(_locationHistoryProvider);
    return RefreshIndicator(
      onRefresh: () => ref.refresh(_locationHistoryProvider.future),
      child: asyncData.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: C.error, size: 48),
                const SizedBox(height: 12),
                const Text('Failed to load history',
                    style: TextStyle(fontFamily: 'Inter', color: C.textSub)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () =>
                      ref.refresh(_locationHistoryProvider.future),
                  child: const Text('Retry'),
                ),
              ]),
        ),
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.history_rounded,
                        color: C.textMuted, size: 48),
                    const SizedBox(height: 12),
                    const Text('No location history yet',
                        style: TextStyle(
                            fontFamily: 'Inter', color: C.textSub)),
                    const SizedBox(height: 8),
                    const Text(
                        'Allow location permission to start tracking',
                        style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: C.textMuted)),
                  ]),
            );
          }

          // Start geocoding in background
          _startGeocoding(items);

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
            itemCount: items.length,
            itemBuilder: (ctx, i) {
              final item = items[i];
              final id = item['id'] as int;
              final lat = (item['latitude'] as num).toDouble();
              final lon = (item['longitude'] as num).toDouble();
              final dt =
                  DateTime.tryParse(item['recorded_at'] ?? '')?.toLocal();
              final address = _addressCache[id];

              final prevDt = i > 0
                  ? DateTime.tryParse(
                          items[i - 1]['recorded_at'] ?? '')
                      ?.toLocal()
                  : null;
              final showDateHeader =
                  i == 0 || !_sameDay(prevDt, dt);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showDateHeader)
                    Padding(
                      padding: const EdgeInsets.only(top: 14, bottom: 6),
                      child: Text(
                        dt != null ? _fmtDate(dt) : 'Unknown date',
                        style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: C.textMuted,
                            letterSpacing: 0.5),
                      ),
                    ),
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: C.border),
                    ),
                    child: Row(children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: _isToday(dt)
                              ? C.primary.withOpacity(0.1)
                              : C.textMuted.withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.location_on_rounded,
                            color: _isToday(dt) ? C.primary : C.textMuted,
                            size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dt != null ? _fmtTimeOnly(dt) : 'Unknown',
                              style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: C.text),
                            ),
                            const SizedBox(height: 2),
                            if (address != null)
                              Text(address,
                                  style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 12,
                                      color: C.textSub),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis)
                            else
                              Text(
                                '${lat.toStringAsFixed(5)}, ${lon.toStringAsFixed(5)}',
                                style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12,
                                    color: C.textMuted),
                              ),
                          ],
                        ),
                      ),
                    ]),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  // ───────────── TAB 3: FIND BY TIME ─────────────

  Widget _buildFindTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Where Was I?',
            style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w800,
                fontSize: 22,
                color: C.text)),
        const SizedBox(height: 6),
        const Text('Pick a date and time to see your location',
            style: TextStyle(
                fontFamily: 'Inter', fontSize: 13, color: C.textSub)),
        const SizedBox(height: 28),

        // Date picker
        _pickerLabel('Date'),
        GestureDetector(
          onTap: () async {
            final d = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate:
                  DateTime.now().subtract(const Duration(days: 365)),
              lastDate: DateTime.now(),
            );
            if (d != null) setState(() => _selectedDate = d);
          },
          child: _pickerContainer(
            Icons.calendar_today_rounded,
            _fmtDate(_selectedDate),
          ),
        ),
        const SizedBox(height: 16),

        // Time picker
        _pickerLabel('Time'),
        GestureDetector(
          onTap: () async {
            final t = await showTimePicker(
                context: context, initialTime: _selectedTime);
            if (t != null) setState(() => _selectedTime = t);
          },
          child:
              _pickerContainer(Icons.schedule_rounded, _selectedTime.format(context)),
        ),
        const SizedBox(height: 24),

        // Search button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _searching ? null : _findByTime,
            icon: _searching
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.search_rounded),
            label: Text(_searching ? 'Searching...' : 'Find Location',
                style: const TextStyle(
                    fontFamily: 'Inter', fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(height: 24),

        // Error
        if (_searchError != null)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: C.error.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: C.error.withOpacity(0.3)),
            ),
            child: Row(children: [
              const Icon(Icons.info_outline_rounded,
                  color: C.error, size: 20),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(_searchError!,
                      style: const TextStyle(
                          fontFamily: 'Inter', color: C.error))),
            ]),
          ),

        // Result
        if (_foundLocation != null) ...[
          const Text('Result',
              style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: C.text)),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: C.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(children: [
              SizedBox(
                height: 180,
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: LatLng(
                      (_foundLocation!['latitude'] as num).toDouble(),
                      (_foundLocation!['longitude'] as num).toDouble(),
                    ),
                    initialZoom: 15,
                    interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.none),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
                      userAgentPackageName: 'com.vishalkarpe.lifeos',
                    ),
                    MarkerLayer(markers: [
                      Marker(
                        point: LatLng(
                          (_foundLocation!['latitude'] as num).toDouble(),
                          (_foundLocation!['longitude'] as num).toDouble(),
                        ),
                        width: 36, height: 36,
                        child: Container(
                          decoration: BoxDecoration(
                            color: C.error,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.location_on_rounded,
                              color: Colors.white, size: 18),
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_foundAddress != null) ...[
                        Text(_foundAddress!,
                            style: const TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: C.text)),
                        const SizedBox(height: 6),
                      ],
                      Text(
                        '${(_foundLocation!['latitude'] as num).toStringAsFixed(6)}, ${(_foundLocation!['longitude'] as num).toStringAsFixed(6)}',
                        style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: C.textMuted),
                      ),
                      if (_foundLocation!['recorded_at'] != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Recorded: ${_fmtDateTime(DateTime.tryParse(_foundLocation!['recorded_at'])?.toLocal())}',
                          style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              color: C.textSub),
                        ),
                      ],
                    ]),
              ),
            ]),
          ),
        ],
      ]),
    );
  }

  Widget _pickerLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text,
        style: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: C.text)),
  );

  Widget _pickerContainer(IconData icon, String label) => Container(
    padding: const EdgeInsets.all(16),
    margin: const EdgeInsets.only(bottom: 0),
    decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: C.border)),
    child: Row(children: [
      Icon(icon, color: C.primary, size: 20),
      const SizedBox(width: 12),
      Text(label,
          style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: C.text)),
      const Spacer(),
      const Icon(Icons.chevron_right_rounded, color: C.textMuted),
    ]),
  );

  // ───────────── HELPERS ─────────────

  bool _sameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isToday(DateTime? dt) {
    if (dt == null) return false;
    final now = DateTime.now();
    return dt.year == now.year && dt.month == now.month && dt.day == now.day;
  }

  String _fmtDate(DateTime dt) {
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec',
    ];
    final now = DateTime.now();
    if (_sameDay(dt, now)) return 'Today';
    if (_sameDay(dt, now.subtract(const Duration(days: 1)))) return 'Yesterday';
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  String _fmtTimeOnly(DateTime dt) {
    final h = dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = h >= 12 ? 'PM' : 'AM';
    final h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$h12:$m $period';
  }

  String _fmtTime(DateTime dt) => '${_fmtDate(dt)} at ${_fmtTimeOnly(dt)}';

  String _fmtDateTime(DateTime? dt) {
    if (dt == null) return 'Unknown';
    return '${_fmtDate(dt)} at ${_fmtTimeOnly(dt)}';
  }
}
