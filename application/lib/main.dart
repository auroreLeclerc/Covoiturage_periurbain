import 'package:covoiturage_periurbain/account_connection.dart';
import 'package:covoiturage_periurbain/account_creation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
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


  // Définition de la liste des conducteurs
  final List<Map<String, String>> defaultConducteurListe = [
    {"id": "491", "MAC": "D5:3E:21:C4:23:D0"},
    {"id": "494", "MAC": "D5:05:C9:41:03:89"}
  ];

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
    // _startPeriodicBluetoothScan(); // FIXME: Quand le bluetooth est désactiver l'app plante en boucle
  }

  void _startPeriodicBluetoothScan() {
    _scanTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      print("test");
      _startBluetoothScan();
    });
  }



  void _initializeNotifications() {
    var initializationSettingsAndroid = const AndroidInitializationSettings('icon_notification');
    var initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid);
    fltrNotification.initialize(initializationSettings);
  }

  @override
  void dispose() {
    _scanTimer?.cancel(); // Annuler le Timer lorsque le widget est disposé
    super.dispose();
  }


  void _startBluetoothScan() async {
    print("scan...");
    flutterBlue.scan(timeout: const Duration(seconds: 4)).listen((scanResult) {
      if (mounted) { // Vérifier si le State est monté
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Scanning Bluetooth..."),
            duration: Duration(seconds: 3),
          ),
        );

      }else{
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Scanning Bluetooth..."),
              duration: Duration(seconds: 3),
            ),
        );
      }

      for (var conducteur in defaultConducteurListe) {
        if (scanResult.device.id.toString() == conducteur["MAC"]) {
          _sendNotification();
          break;
        }
      }
    });
  }



  void _sendNotification() async {
    if (_cooldownTimer == null || !_cooldownTimer!.isActive) {
      var androidPlatformChannelSpecifics = const AndroidNotificationDetails(
          'channel_ID', 'channel_name',
          importance: Importance.max, priority: Priority.high, ticker: 'ticker');
      var platformChannelSpecifics = NotificationDetails(
          android: androidPlatformChannelSpecifics
          );

      await fltrNotification.show(
        0,
        'Notification de Conducteur',
        'Voulez-vous prendre des passagers?',
        platformChannelSpecifics,
        payload: 'item x',
      );

      _cooldownTimer = Timer(const Duration(minutes: 1), () {});
    }
  }


  void handleDeviceFound(ScanResult scanResult) {
    for (var conducteur in defaultConducteurListe) {
      if (scanResult.device.id.toString() == conducteur["MAC"]) {
        // Appareil trouvé
      }
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
      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      UserCredential userCredential =
      await FirebaseAuth.instance.signInWithCredential(credential);

      // Stocker les informations d'utilisateur dans _userData
      setState(() {
        _userData = {
          'name': userCredential.user?.displayName,
          'email': userCredential.user?.email,
          'id' : userCredential.user?.uid,
        };
      });

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
