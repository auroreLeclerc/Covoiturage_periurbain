import 'dart:convert';
import 'dart:typed_data';

import 'package:covoiturage_periurbain/account_connection.dart';
import 'package:covoiturage_periurbain/account_creation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';
import 'dart:math';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:async';
import 'package:permission_handler/permission_handler.dart';

// page de compte
import 'map_page.dart';
import 'package:http/http.dart' as http;
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      .then((_) {
    runApp(MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlue),
      ),
      themeMode: ThemeMode.system,
      home: const Application(),
    ));
  });
}



class Application extends StatefulWidget {


  const Application({super.key});
  @override
  State<Application> createState() => ApplicationAccueil();

}


class ApplicationAccueil extends State<Application> {
  Map<String, dynamic>? _userData;
  AccessToken? _accessToken;
  bool _checking = true;
  FlutterLocalNotificationsPlugin fltrNotification = FlutterLocalNotificationsPlugin();
  Timer? _cooldownTimer;
  FlutterBlue flutterBlue = FlutterBlue.instance;
  Timer? _scanTimer;
  String? MACConducteur;
  StreamSubscription? _scanSubscription;
  bool searchBLE = true;


  // Définition de la liste des conducteurs
  final List<Map<String, String>> defaultConducteurListe = [
    {"id": "491", "MAC": "D5:3E:21:C4:23:D0"},
    {"id": "494", "MAC": "D5:05:C9:41:03:89"}
  ];

  final List<Map<String, String>> listeArrets = [];

  Future<void> getArretsFromServer() async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:4443/getArrets'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        // Supposons que les arrêts sont retournés sous forme d'une liste de maps
        List<dynamic> arretsList = responseBody['arrets'];

        setState(() {
          listeArrets.clear();
          for (var arret in arretsList) {
            listeArrets.add(Map<String, String>.from(arret));
          }
        });

        print('Liste des arrêts reçue du serveur.');
      } else {
        print('Erreur lors de la requête au serveur pour obtenir les arrêts: ${response.body}');
      }
    } catch (e) {
      print('Erreur lors de la récupération des arrêts: $e');
    }
  }


  void requestPermissions() async {
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect, // Ajoutez cette ligne
      Permission.location,
    ].request();
  }

  @override
  void initState() {
    super.initState();
    requestPermissions();
    _initializeNotifications();
    _checkBluetoothAndStartScan(); // FIXME: Quand le bluetooth est désactiver l'app plante en boucle
    getArretsFromServer();
    // faut mettre à jour chatgpt @Felix-Jonathan https://github.com/pauldemarco/flutter_blue/issues/1150 
  }

  void _checkBluetoothAndStartScan() async {
    if (await flutterBlue.isOn) {
      _startPeriodicBluetoothScan();
    } else {
      print("Bluetooth n'est pas activé");
    }
  }

  void _startPeriodicBluetoothScan() {
    _scanTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      print("test");
      _startBluetoothScan();
    });
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Vérifier si les services de localisation sont activés
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Les services de localisation sont désactivés.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Les permissions de localisation sont refusées');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Les permissions de localisation sont définitivement refusées, nous ne pouvons pas demander les permissions.');
    }

    return await Geolocator.getCurrentPosition();
  }

  void _initializeNotifications() {
    var initializationSettingsAndroid = AndroidInitializationSettings('app_icon');
    var initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    fltrNotification.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse notificationResponse) {
        switch (notificationResponse.notificationResponseType) {
          case NotificationResponseType.selectedNotification:
            _onSelectNotification(notificationResponse.payload);
            break;
          case NotificationResponseType.selectedNotificationAction:
          // Gérer si nécessaire
            break;
        }
      },
    );
  }


  Future _onSelectNotification(String? payload) async {
    if (payload == 'chauffeur') {
      // Afficher une boîte de dialogue pour saisir le nombre de passagers
      await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Nombre de passagers'),
            content: TextField(
              keyboardType: TextInputType.number,
              onSubmitted: (value) {
                // Envoyer les informations au serveur
                _sendConducteurInfoToServer(int.parse(value));
              },
            ),
          ),
      );
    } else if (payload == 'reponse_passager') {
      // Afficher une boîte de dialogue pour demander la réponse de l'utilisateur
      bool response = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Arrêt trouvé !'),
          content: Text('Cherchez vous un chauffeur ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('OUI'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('NON'),
            ),
          ],
        ),
      );

      if (response) {
        // L'utilisateur a appuyé sur "OUI"
        Position position = await _determinePosition();
        String? id = _userData?['id'];
        await _sendPassengerResponseToServer(id, position.latitude, position.longitude);
      }
    }
  }



  @override
  void dispose() {
    _scanTimer?.cancel(); // Annuler le Timer lorsque le widget est disposé
    super.dispose();
  }

  void _startBluetoothScan() async {
    // Vérifier si le scan est déjà en cours et l'arrêter si nécessaire
    print("tentative de scan...");
    if (searchBLE == true) {
      print("scan...");
      _scanSubscription = flutterBlue.scan(timeout: const Duration(seconds: 4)).listen((scanResult) {
        if (mounted) { // Vérifier si le State est monté
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Scanning Bluetooth..."),
              duration: Duration(seconds: 3),
            ),
          );
        }

        //Scan Conducteur
        //for (var conducteur in defaultConducteurListe) {
          print(scanResult.device.id.toString());
          if (scanResult.device.id.toString() == "D5:42:AA:EB:8F:07") { //493
            print("findconducteur");
            _sendNotificationConducteur();
            //break;
            //}
          }

        //Scan Arret passagé
        //for (var arret in listeArrets) {
          print(scanResult.device.id.toString());
          if (scanResult.device.id.toString() == "FB:86:61:5A:84:6B") { //496
            print("findpassager");
            _sendNotificationPassager();
            //break;
          }
        //}
    });
    }
  }

  void _stopScan() {
    if (_scanSubscription != null) {
      print("Arrêt du scan.");
      searchBLE = false;
      _scanSubscription?.cancel();
      _scanSubscription = null;
    } else {
      print("Aucun scan en cours à arrêter.");
    }
  }

  void _sendNotificationConducteur() async {
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'channel_ID', 'channel_name',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'ticker',
        icon: 'icon_notification' // Référence à l'icône dans le dossier drawable
    );

    var platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics
    );

    print("notification send");
    //_stopScan();

    await fltrNotification.show(
      0,
      'Voulez vous covoiturer ?',
      'Combien de passagers voulez-vous prendre?',
      platformChannelSpecifics,
      payload: 'chauffeur',
    );
  }



  void _sendNotificationPassager() async {
    // Identifier uniques pour les actions de la notification
    const String ouiActionId = 'OUI_ACTION';
    const String nonActionId = 'NON_ACTION';

    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'channel_ID',
      'channel_name',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      icon: 'icon_notification', // Référence à l'icône dans le dossier drawable
      additionalFlags: Int32List.fromList(<int>[4]), // FLAG_AUTO_CANCEL
    );



    var platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);

    print("notification send");
    //_stopScan();

    await fltrNotification.show(
      0,
      'Arrêt trouvé !',
      'Cherchez vous un chauffeur ?',
      platformChannelSpecifics,
      payload: 'reponse_passager',
    );
  }


  void _handleNotificationAction(String actionId) async {
    if (actionId == 'OUI_ACTION') {
      // Envoyer les informations au serveur
      Position position = await _determinePosition();
      String? id = _userData?['id'];
      await _sendPassengerResponseToServer(id, position.latitude, position.longitude);
    }
  }

  Future<void> _sendPassengerResponseToServer(String? id, double latitude, double longitude) async {
    try {
      Position position = await _determinePosition();

      String? id = _userData?['id'];
      String? macAddress = MACConducteur;

      // Envoyer les informations au serveur
      await http.post(
        Uri.parse('http://10.0.2.2:4443/passengerInfo'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({
          'id': id,
          'mac': macAddress,
          'latitude': position.latitude,
          'longitude': position.longitude,
        }),
      );
    } catch (e) {
      print('Erreur lors de l\'envoi des informations de passager: $e');
    }
  }


  Future<void> _sendConducteurInfoToServer(int passengerCount) async {
    print(passengerCount);
    try {
      Position position = await _determinePosition();

      String? id = _userData?['id'];
      String? macAddress = MACConducteur;

      // Envoyer les informations au serveur
      await http.post(
        Uri.parse('http://10.0.2.2:4443/conducteurInfo'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({
          'id': id,
          'mac': macAddress,
          'passengerCount': passengerCount,
          'latitude': position.latitude,
          'longitude': position.longitude,
        }),
      );
    } catch (e) {
      print('Erreur lors de l\'envoi des informations de passager: $e');
    }
  }


  final List<String> ecoPhrases = [
    'Protégeons la planète ensemble !',
    'Faisons un pas vers un avenir plus vert.',
    'Réduisons notre empreinte carbone.',
    // Ajoutez d'autres phrases écologiques ici...
  ];

  _checkIfisLoggedIn() async {
    final accessToken = await FacebookAuth.instance.accessToken;

    setState(() {
      _checking = false;
    });

    if (accessToken != null) {
      print(accessToken.toJson());
      final userData = await FacebookAuth.instance.getUserData();
      _accessToken = accessToken;
      setState(() {
        _userData = userData;
      });
    }
  }

  _login() async {
    final LoginResult result = await FacebookAuth.instance.login();

    if (result.status == LoginStatus.success) {
      _accessToken = result.accessToken;

      final userData = await FacebookAuth.instance.getUserData();
      _userData = userData;

      // Envoyer le token au serveur
      await sendTokenToServer(_accessToken!.token);

      // Rediriger vers MairieMapPage
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => MapPage(userData: _userData!)),
      );
    } else {
      print(result.status);
      print(result.message);
    }
    setState(() {
      _checking = false;
    });
  }


  Future<void> logout() async {
    await FacebookAuth.instance.logOut();
    _accessToken = null;
    _userData = null;
    setState(() {});
  }
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null;
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

      // Stocker les informations d'utilisateur dans _userData
      setState(() {
        _userData = {
          'name': userCredential.user?.displayName,
          'email': userCredential.user?.email,
          'id' : userCredential.user?.uid,
        };
      });

      // Envoyer le token au serveur
      await sendTokenToServer(userCredential.user!.uid);

      // Rediriger vers MairieMapPage
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => MapPage(userData: _userData!)),
      );

      return userCredential;
    } catch (e) {
      print('Failed to sign in with Google: $e');
      return null;
    }
  }

  //GERER COTE SERVEUR => Envoyer Token, s'il n'existe pas,création compte côté serveur.
  //Renvoyer adresse Mac s'il y en a une lié
  Future<void> sendTokenToServer(String token) async {
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:4443/getMacByToken'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'token': token,
        }),
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        // Supposons que l'adresse MAC est retournée sous la clé 'mac'
        String macAddress = responseBody['mac'];

        setState(() {
          MACConducteur = macAddress;
        });

        print('Adresse MAC reçue du serveur: $MACConducteur');
      } else {
        print('Erreur lors de la requête au serveur: ${response.body}');
      }
    } catch (e) {
      print('Erreur lors de l\'envoi du token: $e');
    }
  }



  @override
  Widget build(BuildContext context) {
    final randomPhrase = ecoPhrases[Random().nextInt(ecoPhrases.length)];
    print("Démarrage");
    print(_userData);
    return Scaffold(
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/fond.jpg'),
              fit: BoxFit.cover,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(bottom: 150.0),
                  child: Image.asset('assets/Navette2.png', height: 150),
                ),
                Text(
                  randomPhrase,
                  style: const TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                    shadows: [
                      Shadow(
                        offset: Offset(-1.0, -1.0),
                        color: Colors.black,
                      ),
                      Shadow(
                        offset: Offset(1.0, -1.0),
                        color: Colors.black,
                      ),
                      Shadow(
                        offset: Offset(-1.0, 1.0),
                        color: Colors.black,
                      ),
                      Shadow(
                        offset: Offset(1.0, 1.0),
                        color: Colors.black,
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                SignInButton(
                  Buttons.Facebook,
                  text: "Connecter avec Facebook",
                  onPressed: () {
                    _login();
                  },
                ),
                SignInButton(
                  Buttons.Google,
                  text: "Connecter avec Google",
                  onPressed: () {
                    signInWithGoogle();
                  },
                ),
                SignInButton(
                  Buttons.Apple,
                  text: "Connecter avec Apple",
                  onPressed: () {
                    // Implémentez la logique de connexion Apple ici
                  },
                ),
                SignInButton(
                  Buttons.Email,
                  text: "Connecter avec Navette",
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const AccountConnection()),
                    );
                  },
                ),
                const SizedBox(
                    height:
                        50), // Espacement entre les boutons et le texte "Pas de compte ?"
                const Text(
                  'Pas de compte ?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16, // Vous pouvez ajuster la taille du texte ici
                    shadows: [
                      Shadow(
                        offset: Offset(-1.0, -1.0),
                        color: Colors.black,
                      ),
                      Shadow(
                        offset: Offset(1.0, -1.0),
                        color: Colors.black,
                      ),
                      Shadow(
                        offset: Offset(-1.0, 1.0),
                        color: Colors.black,
                      ),
                      Shadow(
                        offset: Offset(1.0, 1.0),
                        color: Colors.black,
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const AccountCreation()),
                    );
                  },
                  child: const Text('Inscrivez-vous'),
                ),

              ],
            ),
          ),
        ),
      ),
    );
  }


}
