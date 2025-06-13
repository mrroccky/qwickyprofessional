import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'dart:convert';
import 'package:qwickyprofessional/widgets/colors.dart';

class MapDialogWidget extends StatefulWidget {
  final String userAddress;

  const MapDialogWidget({super.key, required this.userAddress});

  @override
  State<MapDialogWidget> createState() => _MapDialogWidgetState();
}

class _MapDialogWidgetState extends State<MapDialogWidget> {
  GoogleMapController? _mapController;
  Location _location = Location();
  LatLng? _professionalLocation;
  LatLng? _userLocation;
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    try {
      // Get professional's current location
      LocationData? locationData = await _location.getLocation();
      if (locationData.latitude != null && locationData.longitude != null) {
        _professionalLocation = LatLng(locationData.latitude!, locationData.longitude!);
      } else {
        setState(() {
          _error = 'Could not get professional location';
          _isLoading = false;
        });
        return;
      }

      // Geocode user address to coordinates
      _userLocation = await _geocodeAddress(widget.userAddress);
      if (_userLocation == null) {
        setState(() {
          _error = 'Could not find user location';
          _isLoading = false;
        });
        return;
      }

      // Update markers
      _updateMarkers();

      // Get route
      await _getRoute();

      // Listen for location updates
      _location.onLocationChanged.listen((LocationData newLocation) {
        if (newLocation.latitude != null && newLocation.longitude != null && mounted) {
          setState(() {
            _professionalLocation = LatLng(newLocation.latitude!, newLocation.longitude!);
            _updateMarkers();
            _getRoute(); // Update route as professional moves
          });
        }
      });

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error initializing map: $e');
      setState(() {
        _error = 'Error loading map: $e';
        _isLoading = false;
      });
    }
  }

  Future<LatLng?> _geocodeAddress(String address) async {
    final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];
    final url = 'https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(address)}&key=$apiKey';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == 'OK' && data['results'].isNotEmpty) {
        final location = data['results'][0]['geometry']['location'];
        return LatLng(location['lat'], location['lng']);
      }
    }
    return null;
  }

  Future<void> _getRoute() async {
    if (_professionalLocation == null || _userLocation == null) return;

    final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];
    final origin = '${_professionalLocation!.latitude},${_professionalLocation!.longitude}';
    final destination = '${_userLocation!.latitude},${_userLocation!.longitude}';
    final url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=$origin&destination=$destination&key=$apiKey';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == 'OK') {
        final polylinePoints = PolylinePoints();
        final points = polylinePoints.decodePolyline(data['routes'][0]['overview_polyline']['points']);
        final List<LatLng> polylineCoordinates = points
            .map((point) => LatLng(point.latitude, point.longitude))
            .toList();

        setState(() {
          _polylines = {
            Polyline(
              polylineId: PolylineId('route'),
              color: AppColors.primaryColor,
              points: polylineCoordinates,
              width: 5,
            ),
          };
        });
      }
    }
  }

  void _updateMarkers() {
    _markers = {};
    if (_professionalLocation != null) {
      _markers.add(
        Marker(
          markerId: MarkerId('professional'),
          position: _professionalLocation!,
          infoWindow: InfoWindow(title: 'Your Location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    }
    if (_userLocation != null) {
      _markers.add(
        Marker(
          markerId: MarkerId('user'),
          position: _userLocation!,
          infoWindow: InfoWindow(title: 'User Location'),
        ),
      );
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        height: height * 0.9,
        width: width * 0.9,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          children: [
            if (_isLoading)
              Center(child: CircularProgressIndicator())
            else if (_error != null)
              Center(child: Text(_error!, style: TextStyle(fontSize: height * 0.02)))
            else
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _professionalLocation ?? LatLng(0, 0),
                    zoom: 14,
                  ),
                  markers: _markers,
                  polylines: _polylines,
                  onMapCreated: (GoogleMapController controller) {
                    _mapController = controller;
                    if (_professionalLocation != null && _userLocation != null) {
                      _mapController?.animateCamera(
                        CameraUpdate.newLatLngBounds(
                          LatLngBounds(
                            southwest: LatLng(
                              _professionalLocation!.latitude < _userLocation!.latitude
                                  ? _professionalLocation!.latitude
                                  : _userLocation!.latitude,
                              _professionalLocation!.longitude < _userLocation!.longitude
                                  ? _professionalLocation!.longitude
                                  : _userLocation!.longitude,
                            ),
                            northeast: LatLng(
                              _professionalLocation!.latitude > _userLocation!.latitude
                                  ? _professionalLocation!.latitude
                                  : _userLocation!.latitude,
                              _professionalLocation!.longitude > _userLocation!.longitude
                                  ? _professionalLocation!.longitude
                                  : _userLocation!.longitude,
                            ),
                          ),
                          50,
                        ),
                      );
                    }
                  },
                ),
              ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: Icon(Icons.close, size: height * 0.035, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}