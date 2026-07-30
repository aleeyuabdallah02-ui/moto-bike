import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../theme/app_theme.dart';
import 'place_order_screen.dart';

/// Client's landing screen after signup — fetches their current
/// location, then hands off to PlaceOrderScreen to pick a destination.
class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _resolveLocationAndContinue();
  }

  Future<void> _resolveLocationAndContinue() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        setState(() {
          _error = 'Ana bukatar izinin location don nemo direba kusa da kai.';
          _loading = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PlaceOrderScreen(
            currentPosition: LatLng(position.latitude, position.longitude),
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _error = 'Ba a iya samun location ba: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _loading
            ? const CircularProgressIndicator(color: AppTheme.primary)
            : Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error ?? '', textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    GradientButton(
                      label: 'Sake Gwadawa',
                      onPressed: () {
                        setState(() => _loading = true);
                        _resolveLocationAndContinue();
                      },
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
