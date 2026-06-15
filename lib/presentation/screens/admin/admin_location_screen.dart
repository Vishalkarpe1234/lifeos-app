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
  List<Map<String, dynamic>> _locations = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await ref.read(dioProvider).get('/api/v1/admin/users/${widget.userId}/locations');
      setState(() {
        _locations = List<Map<String, dynamic>>.from(r.data['items']);
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  String _fmtTime(String? s) {
    if (s == null || s == 'None') return '-';
    try {
      final dt = DateTime.parse(s).toLocal();
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
    } catch (_) { return s; }
  }

  Future<void> _openMaps(double lat, double lng) async {
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final latest = _locations.isNotEmpty ? _locations.first : null;
    final latLng = latest != null ? LatLng(latest['latitude'] as double, latest['longitude'] as double) : null;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18), onPressed: () => context.pop()),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Location History'),
          Text(widget.userEmail, style: const TextStyle(fontSize: 11, color: C.textSub, fontFamily: 'Inter', fontWeight: FontWeight.normal)),
        ]),
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
              // Map showing latest location
              if (latLng != null) SizedBox(height: 260, child: Stack(children: [
                FlutterMap(
                  options: MapOptions(initialCenter: latLng, initialZoom: 14),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.hivetech.lifeos',
                    ),
                    MarkerLayer(markers: [
                      Marker(
                        point: latLng, width: 40, height: 40,
                        child: const Icon(Icons.location_pin, color: Colors.red, size: 40),
                      ),
                    ]),
                  ],
                ),
                Positioned(bottom: 8, right: 8, child: ElevatedButton.icon(
                  onPressed: () => _openMaps(latest!['latitude'] as double, latest['longitude'] as double),
                  icon: const Icon(Icons.open_in_new, size: 14),
                  label: const Text('Open in Maps', style: TextStyle(fontSize: 12, fontFamily: 'Inter')),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), minimumSize: Size.zero),
                )),
              ])),
              // Location history list
              Expanded(child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _locations.length,
                itemBuilder: (_, i) {
                  final loc = _locations[i];
                  final lat = loc['latitude'] as double;
                  final lng = loc['longitude'] as double;
                  return Container(
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
                        if (i == 0) const Text('Most recent', style: TextStyle(fontSize: 10, color: C.primary, fontFamily: 'Inter', fontWeight: FontWeight.w700)),
                      ])),
                      IconButton(
                        padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                        icon: const Icon(Icons.map_outlined, color: C.primary, size: 20),
                        onPressed: () => _openMaps(lat, lng),
                      ),
                    ]),
                  );
                },
              )),
            ]),
    );
  }
}
