import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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

class _LocState extends ConsumerState<AdminLocationScreen> {
  List<Map<String, dynamic>> _locations = []; // newest first, as returned by API
  List<Map<String, dynamic>> _chrono = []; // oldest first, for playback/route
  bool _loading = true;
  int _playIndex = 0;
  bool _isPlaying = false;
  Timer? _playTimer;
  Timer? _refreshTimer;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _load();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) => _load(silent: true));
  }

  @override
  void dispose() {
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
      setState(() {
        _locations = items;
        _chrono = chrono;
        _loading = false;
        // Keep the view pinned to "Live" (most recent) unless the admin is scrubbing history
        if (wasAtLive && !_isPlaying && _chrono.isNotEmpty) {
          _playIndex = _chrono.length - 1;
        }
        if (_playIndex >= _chrono.length) _playIndex = _chrono.isEmpty ? 0 : _chrono.length - 1;
      });
      if (wasAtLive && _chrono.isNotEmpty) {
        _moveMap(_chrono.last);
      }
    } catch (_) {
      if (!silent && mounted) setState(() => _loading = false);
    }
  }

  void _moveMap(Map<String, dynamic> loc) {
    try {
      _mapController.move(LatLng(loc['latitude'] as double, loc['longitude'] as double), _mapController.camera.zoom);
    } catch (_) {}
  }

  void _togglePlay() {
    if (_isPlaying) {
      _playTimer?.cancel();
      setState(() => _isPlaying = false);
      return;
    }
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
    setState(() {
      _isPlaying = false;
      _playIndex = _chrono.length - 1;
    });
    _moveMap(_chrono.last);
  }

  String _fmtTime(String? s) {
    if (s == null || s == 'None') return '-';
    try {
      final dt = DateTime.parse(s).toLocal();
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}:${dt.second.toString().padLeft(2,'0')}';
    } catch (_) { return s; }
  }

  Future<void> _openMaps(double lat, double lng) async {
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final selected = _chrono.isNotEmpty ? _chrono[_playIndex] : null;
    final selectedLatLng = selected != null ? LatLng(selected['latitude'] as double, selected['longitude'] as double) : null;
    final isLive = _chrono.isNotEmpty && _playIndex == _chrono.length - 1;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18), onPressed: () => context.pop()),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Location History'),
          Text(widget.userEmail, style: const TextStyle(fontSize: 11, color: C.textSub, fontFamily: 'Inter', fontWeight: FontWeight.normal)),
        ]),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: () => _load()),
        ],
      ),
      body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _locations.isEmpty
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.location_off_rounded, color: C.textMuted, size: 48),
              const SizedBox(height: 16),
              const Text('No location data available', style: TextStyle(color: C.textSub, fontFamily: 'Inter', fontSize: 15)),
              const SizedBox(height: 8),
              const Text('User has not shared any location yet', style: TextStyle(color: C.textMuted, fontFamily: 'Inter', fontSize: 13)),
            ]))
          : Column(children: [
              // Map showing selected/live location with route history
              if (selectedLatLng != null) SizedBox(height: 260, child: Stack(children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(initialCenter: selectedLatLng, initialZoom: 14),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.hivetech.lifeos',
                    ),
                    if (_chrono.length > 1) PolylineLayer(polylines: [
                      Polyline(
                        points: _chrono.map((l) => LatLng(l['latitude'] as double, l['longitude'] as double)).toList(),
                        color: C.primary.withOpacity(0.5),
                        strokeWidth: 3,
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
                  label: const Text('Open in Maps', style: TextStyle(fontSize: 12, fontFamily: 'Inter')),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), minimumSize: Size.zero),
                )),
              ])),
              // Playback controls
              if (_chrono.length > 1) Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                color: Colors.white,
                child: Column(children: [
                  Row(children: [
                    IconButton(
                      icon: Icon(_isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded, color: C.primary, size: 34),
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
                  Text(_fmtTime(selected?['timestamp']?.toString()), style: const TextStyle(fontSize: 12, color: C.textSub, fontFamily: 'Inter', fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                ]),
              ),
              // Location history list
              Expanded(child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _locations.length,
                itemBuilder: (_, i) {
                  final loc = _locations[i];
                  final lat = loc['latitude'] as double;
                  final lng = loc['longitude'] as double;
                  return GestureDetector(
                    onTap: () {
                      _playTimer?.cancel();
                      setState(() { _isPlaying = false; _playIndex = _chrono.length - 1 - i; });
                      _moveMap(_chrono[_playIndex]);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
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
                          Text('${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: C.text, fontFamily: 'Inter')),
                          Text(_fmtTime(loc['timestamp']?.toString()), style: const TextStyle(fontSize: 11, color: C.textMuted, fontFamily: 'Inter')),
                          if (loc['accuracy'] != null) Text('Accuracy: ±${(loc['accuracy'] as num).toStringAsFixed(0)}m', style: const TextStyle(fontSize: 10, color: C.textMuted, fontFamily: 'Inter')),
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
            ]),
    );
  }
}
