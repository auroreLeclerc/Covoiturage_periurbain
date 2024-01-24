import 'dart:convert';

import 'package:covoiturage_periurbain/account_connection.dart';
import 'package:covoiturage_periurbain/account_creation.dart';
import './background.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';
import 'dart:math';
import 'package:firebase_core/firebase_core.dart';
import 'dart:async';
import 'package:permission_handler/permission_handler.dart';

// page de compte
import 'map_page.dart';
import 'package:http/http.dart' as http;

void main() async {
  GlobalKey<NavigatorState> navigatorKey = GlobalKey();
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
      navigatorKey: navigatorKey,
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
  String? MACConducteur;

  // Définition de la liste des conducteurs
  final List<Map<String, String>> defaultConducteurListe = [
    {"id": "491", "MAC": "D5:3E:21:C4:23:D0"},
    {"id": "494", "MAC": "D5:05:C9:41:03:89"}
  ];

  final List<Map<String, String>> listeArrets = [];

  Future<void> getArretsFromServer() async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:4443/stops'),
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
        print(
            'Erreur lors de la requête au serveur pour obtenir les arrêts: ${response.body}');
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

  //Initialisation de l'application
  @override
  void initState() {
    super.initState();
    requestPermissions();
    getArretsFromServer();
  }

  final List<String> ecoPhrases = [
    'Protégeons la planète ensemble !',
    'Faisons un pas vers un avenir plus vert.',
    'Réduisons notre empreinte carbone.',
    // Ajoutez d'autres phrases écologiques ici...
  ];

  _signInWithFB() async {
    final LoginResult result = await FacebookAuth.instance.login();

    if (result.status == LoginStatus.success) {
      _accessToken = result.accessToken;

      final userData = await FacebookAuth.instance.getUserData();
      _userData = userData;

      // Envoyer le token au serveur
      await sendTokenToServer(_userData?['email'], _userData?['name'],
          _userData?['id'], "passenger");

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
    stopScan();
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
          'id': userCredential.user?.uid,
        };
      });

      // Envoyer les infos au serveur
      await sendTokenToServer(
          _userData?['email'], _userData?['name'], _userData?['id'], "driver");

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

  Future<void> sendTokenToServer(
      String mail, String name, String password, String role) async {
    try {
      final Map<String, String> toSend = {
        "mail": mail,
        "name": name,
        "password": password,
        "role": role.toString(),
        "town": "Amiens" //Town de Test
      };
      http
          .put(
        Uri.parse('http://10.0.2.2:4443/account'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(toSend),
      )
          .then((response) {
        if (response.statusCode == 201) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Compte créer avec Succès")));
        } else {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(response.body)));
        }
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      });
    } catch (e) {
      print('Erreur lors de l\'envoi du token: $e');
    }

    final Map<String, String> toSend = {
      "mail": mail,
      "password": password,
    };

    http
        .post(
      Uri.parse('http://10.0.2.2:4443/account'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(toSend),
    )
        .then((response) {
      print('response : $response');
      if (response.statusCode == 200) {
        http.get(Uri.parse('http://10.0.2.2:4443/account'),
            headers: <String, String>{
              'Content-Type': 'application/json; charset=UTF-8',
              'Authorization': response.body
            }).then((responseGet) {
          print("Response status: ${responseGet.statusCode}");
          print("Response body: ${responseGet.body}");
          final userData = jsonDecode(responseGet.body);
          print('reçue du serveur: $userData');
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => MapPage(userData: {
                      'name': userData["name"],
                      'email': mail,
                      'id': null,
                      'token': response.body,
                    })),
          );
        });
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(response.body)));
      }
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    });

    print("Initialisation du scan...");
    //Initialisation du scan une fois connecté sous un role
    checkBluetoothAndStartScan(role);
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
                    _signInWithFB();
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
