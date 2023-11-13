import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'account.dart'; // Assurez-vous que le chemin est correct

class MapPage extends StatefulWidget {
  final Map<String, dynamic> userData;

  const MapPage({super.key, required this.userData});

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  int _currentIndex = 0;
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const MapContent(),
      AccountDetailsPage(widget.userData),
    ];
  }

  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex], // Plus d'AppBar ici
      bottomNavigationBar: BottomNavigationBar(
        onTap: onTabTapped,
        currentIndex: _currentIndex,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Carte',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Compte',
          ),
        ],
      ),
    );
  }
}



class MapContent extends StatefulWidget {
  const MapContent({super.key});

  @override
  _MapContentState createState() => _MapContentState();
}

class _MapContentState extends State<MapContent> {
  List<Mairie> mairiesProches = [];
  List<Mairie> mairiesFiltrees = [];
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _determinePosition().then((pos) {
      _fetchMairiesProches(pos);
    });
  }

  void _fetchMairiesProches(Position position) {
    List<Mairie> mairiesFictives = [
      Mairie('Mairie de Salouël', LatLng(49.8619, 2.2269)),
      Mairie('Mairie de Rivery', LatLng(49.9028, 2.3011)),
      Mairie('Mairie de Pont-de-Metz', LatLng(49.8625, 2.2483)),
      Mairie('Mairie de Dury', LatLng(49.8484, 2.2681)),
      Mairie('Mairie de Longueau', LatLng(49.8731, 2.3833)),
      Mairie('Mairie de Camon', LatLng(49.9102, 2.3788)),
      Mairie('Mairie de Poulainville', LatLng(49.9381, 2.3208)),
      Mairie('Mairie de Cagny', LatLng(49.8355, 2.3538)),
      Mairie('Mairie de Glisy', LatLng(49.8530, 2.3945)),
      Mairie('Mairie de Boves', LatLng(49.8355, 2.4083)),
    ];

    for (var mairie in mairiesFictives) {
      double distanceInMeters = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        mairie.coordonnees.latitude,
        mairie.coordonnees.longitude,
      );
      mairie.distance = distanceInMeters / 1000; // Convertir en kilomètres
    }

    setState(() {
      mairiesProches = mairiesFictives;
      mairiesFiltrees = List.from(mairiesProches);
    });
  }

  void _filterMairies(String enteredKeyword) {
    List<Mairie> results = [];
    if (enteredKeyword.isEmpty) {
      results = List.from(mairiesProches);
    } else {
      results = mairiesProches
          .where((mairie) =>
          mairie.nom.toLowerCase().contains(enteredKeyword.toLowerCase()))
          .toList();
    }

    setState(() {
      mairiesFiltrees = results;
    });
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Les services de localisation sont désactivés.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Les permissions de localisation sont refusées.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Les permissions de localisation sont définitivement refusées, nous ne pouvons pas demander de permissions.');
    }

    return await Geolocator.getCurrentPosition();
  }

  void _launchGoogleMaps(LatLng destination) async {
    var googleMapsUrl = 'https://www.google.com/maps/search/?api=1&query=${destination.latitude},${destination.longitude}';
    if (await canLaunchUrl(Uri.parse(googleMapsUrl))) {
      await launchUrl(Uri.parse(googleMapsUrl));
    } else {
      throw 'Could not launch $googleMapsUrl';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: searchController,
            decoration: const InputDecoration(
              labelText: 'Recherche',
              suffixIcon: Icon(Icons.search),
            ),
            onChanged: (value) {
              _filterMairies(value);
            },
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: mairiesFiltrees.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(mairiesFiltrees[index].nom),
                subtitle: Text('Distance: ${mairiesFiltrees[index].distance.toStringAsFixed(2)} km'),
                trailing: IconButton(
                  icon: const Icon(Icons.map),
                  onPressed: () {
                    _launchGoogleMaps(mairiesFiltrees[index].coordonnees);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class Mairie {
  String nom;
  LatLng coordonnees;
  double distance = 0.0;

  Mairie(this.nom, this.coordonnees);
}

class LatLng {
  final double latitude;
  final double longitude;

  LatLng(this.latitude, this.longitude);
}
