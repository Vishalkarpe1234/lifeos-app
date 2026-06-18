import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lifeos/config/theme/app_theme.dart';
import 'package:lifeos/services/api/api_client.dart';

class AdminLocationScreen extends ConsumerStatefulWidget {
  final int userId;
  final String userEmail;
  const AdminLocationScreen({super.key, required this.userId, required this.userEmail});
  @override
  ConsumerState<AdminLocationScreen> createState() => _LocState();
}

class _LocState extends ConsumerState<AdminLocationScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  // Track tab
  List<Map<String, dynamic>> _locations = [];
  List<Map<String, dynamic>> _chrono = [];
  bool _loading = true;
  int _playIndex = 0;
  bool _isPlaying = false;
  Timer? _playTimer;
  Timer? _refreshTimer;
  final MapController _mapController = MapController();
  final MapController _findMapController = MapController();

  // Find tab
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  Map<String, dynamic>? _foundLocation;
  bool _searching = false;
  String? _searchError;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _load();
    // Refresh every 1 minute — user sends every 5 min, so 1 min is responsive enough
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) => _load(silent: true));
  }

  @override
  void dispose() {
    _tabs.dispose();
    _playTimer?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    try {
      final r = await ref.read(dioProvider).get('/api/v1/admin/users/${widget.userId}/locations');
      final items = List<Map<String, dynamic>>.from(r.data['items']);
      final chrono = items.reversed.toList();
      final wasAtLive = _chrono.isEmpty || _playIndex >= _chrono.length - 1;
      if (mounted) {
        setState(() {
          _locations = items;
          _chrono = chrono;
          _loading = false;
          if (wasAtLive && !_isPlaying && _chrono.isNotEmpty) {
            _playIndex = _chrono.length - 1;
          }
          if (_playIndex >= _chrono.length) _playIndex = _chrono.isEmpty ? 0 : _chrono.length - 1;
        });
        if (wasAtLive && _chrono.isNotEmpty) _moveMap(_chrono.last);
      }
    } catch (_) {
      if (!silent && mounted) setState(() => _loading = false);
    }
  }

  void _moveMap(Map<String, dynamic> loc) {
    try { _mapController.move(LatLng((loc['latitude'] as num).toDouble(), (loc['longitude'] as num).toDouble()), _mapController.camera.zoom); } catch (_) {}
  }

  void _togglePlay() {
    if (_isPlaying) { _playTimer?.cancel(); setState(() => _isPlaying = false); return; }
    if (_chrono.length < 2) return;
    if (_playIndex >= _chrono.length - 1) _playIndex = 0;
    setState(() => _isPlaying = true);
    _playTimer = Timer.periodic(const Duration(milliseconds: 1200), (timer) {
      if (!mounted) { timer.cancel(); return; }
      setState(() {
        if (_playIndex < _chrono.length - 1) {
          _playIndex++;
          _moveMap(_chrono[_playIndex]);
        } else {
          _isPlaying = false;
          timer.cancel();
        }
      });
    });
  }

  void _goLive() {
    _playTimer?.cancel();
    if (_chrono.isEmpty) return;
    setState(() { _isPlaying = false; _playIndex = _chrono.length - 1; });
    _moveMap(_chrono.last);
  }

  Future<void> _findByTime() async {
    setState(() { _searching = true; _foundLocation = null; _searchError = null; });
    try {
      final dt = DateTime(
        _selectedDate.year, _selectedDate.month, _selectedDate.day,
        _selectedTime.hour, _selectedTime.minute,
      ).toUtc();
      final r = await ref.read(dioProvider).get(
        '/api/v1/admin/users/${widget.userId}/location/at',
        queryParameters: {'timestamp': dt.toIso8601String()},
      );
      if (mounted) {
        setState(() { _foundLocation = Map<String, dynamic>.from(r.data); _searching = false; });
        try {
          _findMapController.move(
            LatLng((_foundLocation!['latitude'] as num).toDouble(), (_foundLocation!['longitude'] as num).toDouble()),
            15,
          );
        } catch (_) {}
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

  Future<void> _openMaps(double lat, double lng) async {
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  String _fmtTime(String? s) {
    if (s == null || s == 'None') return '-';
    try {
      final dt = DateTime.parse(s).toLocal();
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      final h12 = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
      return '${dt.day}/${dt.month}/${dt.year} $h12:${dt.minute.toString().padLeft(2,'0')} $period';
    } catch (_) { return s; }
  }

  String _fmtDate(DateTime dt) {
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) return 'Today';
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day - 1) return 'Yesterday';
    return '${m[dt.month-1]} ${dt.day}, ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18), onPressed: () => context.pop()),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Location', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 16)),
          Text(widget.userEmail, style: const TextStyle(fontSize: 11, color: C.textSub, fontFamily: 'Inter', fontWeight: FontWeight.normal)),
        ]),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: () => _load(), tooltip: 'Refresh now'),
        ],
        bottom: TabBar(
          controller: _tabs,
          labelStyle: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 13),
          unselectedLabelStyle: const TextStyle(fontFamily: 'Inter', fontSize: 13),
          indicatorColor: C.primary,
          labelColor: C.primary,
          unselectedLabelColor: C.textSub,
          tabs: const [Tab(text: 'Live & History'), Tab(text: 'Find by Time')],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _buildTrackTab(),
          _buildFindTab(),
        ],
      ),
    );
  }

  // ────────────── TAB 1: Live & History ──────────────

  Widget _buildTrackTab() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_locations.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.location_off_rounded, color: C.textMuted, size: 48),
        const SizedBox(height: 16),
        const Text('No location data yet', style: TextStyle(color: C.textSub, fontFamily: 'Inter', fontSize: 15)),
        const SizedBox(height: 8),
        const Text('User has not shared location', style: TextStyle(color: C.textMuted, fontFamily: 'Inter', fontSize: 13)),
        const SizedBox(height: 20),
        ElevatedButton.icon(onPressed: () => _load(), icon: const Icon(Icons.refresh_rounded), label: const Text('Refresh')),
      ]));
    }

    final selected = _chrono.isNotEmpty ? _chrono[_playIndex] : null;
    final selectedLatLng = selected != null ? LatLng((selected['latitude'] as num).toDouble(), (selected['longitude'] as num).toDouble()) : null;
    final isLive = _chrono.isNotEmpty && _playIndex == _chrono.length - 1;

    return Column(children: [
      if (selectedLatLng != null) SizedBox(height: 240, child: Stack(children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(initialCenter: selectedLatLng, initialZoom: 14),
          children: [
            TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.hivetech.lifeos'),
            if (_chrono.length > 1) PolylineLayer(polylines: [
              Polyline(
                points: _chrono.map((l) => LatLng((l['latitude'] as num).toDouble(), (l['longitude'] as num).toDouble())).toList(),
                color: C.primary.withOpacity(0.5), strokeWidth: 3,
              ),
            ]),
            MarkerLayer(markers: [
              Marker(
                point: selectedLatLng, width: 40, height: 40,
                child: Icon(Icons.location_pin, color: isLive ? Colors.red : C.primary, size: 40),
              ),
            ]),
          ],
        ),
        Positioned(top: 8, left: 8, child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(color: isLive ? Colors.red : C.primary, borderRadius: BorderRadius.circular(20)),
          child: Text(isLive ? '● LIVE' : 'HISTORY', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800, fontFamily: 'Inter')),
        )),
        Positioned(bottom: 8, right: 8, child: ElevatedButton.icon(
          onPressed: () => _openMaps(selectedLatLng.latitude, selectedLatLng.longitude),
          icon: const Icon(Icons.open_in_new, size: 14),
          label: const Text('Open Maps', style: TextStyle(fontSize: 12, fontFamily: 'Inter')),
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), minimumSize: Size.zero),
        )),
      ])),
      if (_chrono.length > 1) Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        color: Colors.white,
        child: Column(children: [
          Row(children: [
            IconButton(
              icon: Icon(_isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded, color: C.primary, size: 32),
              onPressed: _togglePlay,
            ),
            Expanded(child: Slider(
              value: _playIndex.toDouble(),
              min: 0,
              max: (_chrono.length - 1).toDouble(),
              divisions: _chrono.length - 1,
              activeColor: C.primary,
              onChanged: (v) {
                _playTimer?.cancel();
                setState(() { _isPlaying = false; _playIndex = v.round(); });
                _moveMap(_chrono[_playIndex]);
              },
            )),
            TextButton(
              onPressed: isLive ? null : _goLive,
              child: Text('LIVE', style: TextStyle(color: isLive ? C.textMuted : C.primary, fontWeight: FontWeight.w800, fontFamily: 'Inter', fontSize: 12)),
            ),
          ]),
          Text(_fmtTime(selected?['timestamp']?.toString()),
            style: const TextStyle(fontSize: 12, color: C.textSub, fontFamily: 'Inter', fontWeight: FontWeight.w600)),
        ]),
      ),
      Expanded(child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _locations.length,
        itemBuilder: (_, i) {
          final loc = _locations[i];
          final lat = (loc['latitude'] as num).toDouble();
          final lng = (loc['longitude'] as num).toDouble();
          return GestureDetector(
            onTap: () {
              _playTimer?.cancel();
              setState(() { _isPlaying = false; _playIndex = _chrono.length - 1 - i; });
              _moveMap(_chrono[_playIndex]);
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: i == 0 ? C.primary.withOpacity(0.05) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: i == 0 ? C.primary.withOpacity(0.3) : C.border),
              ),
              child: Row(children: [
                Container(width: 28, height: 28,
                  decoration: BoxDecoration(color: i == 0 ? C.primary : C.bg, shape: BoxShape.circle),
                  child: Center(child: Text('${i+1}', style: TextStyle(color: i == 0 ? Colors.white : C.textSub, fontSize: 12, fontFamily: 'Inter', fontWeight: FontWeight.w700)))),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: C.text, fontFamily: 'Inter')),
                  Text(_fmtTime(loc['timestamp']?.toString()), style: const TextStyle(fontSize: 11, color: C.textMuted, fontFamily: 'Inter')),
                  if (i == 0) const Text('Most recent', style: TextStyle(fontSize: 10, color: C.primary, fontFamily: 'Inter', fontWeight: FontWeight.w700)),
                ])),
                IconButton(
                  padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                  icon: const Icon(Icons.map_outlined, color: C.primary, size: 20),
                  onPressed: () => _openMaps(lat, lng),
                ),
              ]),
            ),
          );
        },
      )),
    ]);
  }

  // ────────────── TAB 2: Find by Time ──────────────

  Widget _buildFindTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Where Was User?', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w800, fontSize: 22, color: C.text)),
        const SizedBox(height: 6),
        Text('Find ${widget.userEmail}\'s location at a specific time', style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: C.textSub)),
        const SizedBox(height: 24),

        _pickerLabel('Date'),
        GestureDetector(
          onTap: () async {
            final d = await showDatePicker(
              context: context, initialDate: _selectedDate,
              firstDate: DateTime.now().subtract(const Duration(days: 365)), lastDate: DateTime.now(),
            );
            if (d != null) setState(() => _selectedDate = d);
          },
          child: _pickerContainer(Icons.calendar_today_rounded, _fmtDate(_selectedDate)),
        ),
        const SizedBox(height: 14),

        _pickerLabel('Time'),
        GestureDetector(
          onTap: () async {
            final t = await showTimePicker(context: context, initialTime: _selectedTime);
            if (t != null) setState(() => _selectedTime = t);
          },
          child: _pickerContainer(Icons.schedule_rounded, _selectedTime.format(context)),
        ),
        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity, height: 50,
          child: ElevatedButton.icon(
            onPressed: _searching ? null : _findByTime,
            icon: _searching
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.search_rounded),
            label: Text(_searching ? 'Searching...' : 'Find Location',
              style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(height: 20),

        if (_searchError != null) Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: C.error.withOpacity(0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: C.error.withOpacity(0.3))),
          child: Row(children: [
            const Icon(Icons.info_outline_rounded, color: C.error, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(_searchError!, style: const TextStyle(fontFamily: 'Inter', color: C.error))),
          ]),
        ),

        if (_foundLocation != null) ...[
          const Text('Result', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 16, color: C.text)),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: C.border)),
            clipBehavior: Clip.antiAlias,
            child: Column(children: [
              SizedBox(
                height: 200,
                child: FlutterMap(
                  mapController: _findMapController,
                  options: MapOptions(
                    initialCenter: LatLng((_foundLocation!['latitude'] as num).toDouble(), (_foundLocation!['longitude'] as num).toDouble()),
                    initialZoom: 15,
                  ),
                  children: [
                    TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.hivetech.lifeos'),
                    MarkerLayer(markers: [
                      Marker(
                        point: LatLng((_foundLocation!['latitude'] as num).toDouble(), (_foundLocation!['longitude'] as num).toDouble()),
                        width: 36, height: 36,
                        child: Container(
                          decoration: BoxDecoration(color: C.error, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                          child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 18),
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    const Icon(Icons.gps_fixed_rounded, color: C.textMuted, size: 14),
                    const SizedBox(width: 6),
                    Expanded(child: Text(
                      '${(_foundLocation!['latitude'] as num).toStringAsFixed(6)}, ${(_foundLocation!['longitude'] as num).toStringAsFixed(6)}',
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: C.text),
                    )),
                  ]),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.schedule_rounded, color: C.textMuted, size: 14),
                    const SizedBox(width: 6),
                    Text('Recorded: ${_fmtTime(_foundLocation!['timestamp']?.toString())}',
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: C.textSub)),
                  ]),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _openMaps((_foundLocation!['latitude'] as num).toDouble(), (_foundLocation!['longitude'] as num).toDouble()),
                      icon: const Icon(Icons.open_in_new, size: 14),
                      label: const Text('Open in Google Maps', style: TextStyle(fontFamily: 'Inter')),
                    ),
                  ),
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
    child: Text(text, style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 13, color: C.text)),
  );

  Widget _pickerContainer(IconData icon, String label) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: C.border)),
    child: Row(children: [
      Icon(icon, color: C.primary, size: 20),
      const SizedBox(width: 12),
      Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w600, color: C.text)),
      const Spacer(),
      const Icon(Icons.chevron_right_rounded, color: C.textMuted),
    ]),
  );
}
