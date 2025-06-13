import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'dart:convert';

class MapDataProvider with ChangeNotifier {
  Location _location = Location();
  LatLng? _professionalLocation;
  Map<int, LatLng> _userLocations = {};
  Map<int, Set<Polyline>> _routes = {};
  String? _error;
  bool _isLoading = true;

  LatLng? get professionalLocation => _professionalLocation;
  Map<int, LatLng> get userLocations => _userLocations;
  Map<int, Set<Polyline>> get routes => _routes;
  String? get error => _error;
  bool get isLoading => _isLoading;

  Future<void> initialize() async {
    try {
      LocationData? locationData = await _location.getLocation();
      if (locationData.latitude != null && locationData.longitude != null) {
        _professionalLocation = LatLng(locationData.latitude!, locationData.longitude!);
      } else {
        _error = 'Could not get professional location';
        _isLoading = false;
        notifyListeners();
        return;
      }

      _location.onLocationChanged.listen((LocationData newLocation) async {
        if (newLocation.latitude != null && newLocation.longitude != null) {
          LatLng newPos = LatLng(newLocation.latitude!, newLocation.longitude!);
          if (_professionalLocation != null) {
            double distance = geo.Geolocator.distanceBetween(
              _professionalLocation!.latitude,
              _professionalLocation!.longitude,
              newPos.latitude,
              newPos.longitude,
            );
            if (distance > 50) {
              _professionalLocation = newPos;
              await _updateRoutes();
              notifyListeners();
            }
          } else {
            _professionalLocation = newPos;
            notifyListeners();
          }
        }
      });

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error initializing map data: $e');
      _error = 'Error initializing map data: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addUserLocation(int bookingId, String address) async {
    if (_userLocations.containsKey(bookingId)) return;

    LatLng? userLocation = await _geocodeAddress(address);
    if (userLocation != null) {
      _userLocations[bookingId] = userLocation;
      await _getRoute(bookingId, userLocation);
      notifyListeners();
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

  Future<void> _getRoute(int bookingId, LatLng userLocation) async {
    if (_professionalLocation == null) return;

    final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];
    final origin = '${_professionalLocation!.latitude},${_professionalLocation!.longitude}';
    final destination = '${userLocation.latitude},${userLocation.longitude}';
    final url = 'https://maps.googleapis.com/maps/api/directions/json?origin=$origin&destination=$destination&key=$apiKey';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == 'OK') {
        final polylinePoints = PolylinePoints();
        final points = polylinePoints.decodePolyline(data['routes'][0]['overview_polyline']['points']);
        final List<LatLng> polylineCoordinates = points.map((point) => LatLng(point.latitude, point.longitude)).toList();

        _routes[bookingId] = {
          Polyline(
            polylineId: PolylineId('route_$bookingId'),
            color: Colors.blue,
            points: polylineCoordinates,
            width: 5,
          ),
        };
      }
    }
  }

  Future<void> _updateRoutes() async {
    for (var entry in _userLocations.entries) {
      await _getRoute(entry.key, entry.value);
    }
    notifyListeners();
  }
}