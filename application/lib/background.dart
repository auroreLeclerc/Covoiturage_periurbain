import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'globals.dart' as globals; // fichier pour les variables globales

FlutterLocalNotificationsPlugin fltrNotification =
    FlutterLocalNotificationsPlugin();
Timer? _cooldownTimer;
FlutterBlue flutterBlue = FlutterBlue.instance;
Timer? _scanTimer;
String? MACConducteur;
StreamSubscription? _scanSubscription;
bool searchBLE = true;
Map<String, dynamic>? _userData;
GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
String authToken = globals.authToken ;
Map<String, dynamic>? driverInfo;
Map<String, dynamic>? passengerInfo;
List listeArrets = [];
String ArretProche = "";

Future<Map<String, dynamic>?> fetchUserData() async {
  final response = await http.get(
    Uri.parse('http://10.42.0.1:4443/account'),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': authToken,
    },
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body) as Map<String, dynamic>;
  } else {
    print('Failed to load user data');
    return null;
  }
}

Future<List> getArretsFromServer() async {
  try {
    final response = await http.get(
      Uri.parse('http://10.42.0.1:4443/stops'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      // responseBody = [{id: 496, departure: Rivery, arrival: Amiens, mac: FB:86:61:5A:84:6B},
      // {id: 497, departure: Camon, arrival: Amiens, mac: D7:07:FC:B6:E4:E7},
      // {id: 498, departure: Dury, arrival: Amiens, mac: CA:0B:99:7B:2B:F7}]
      print('Liste des arrêts reçue du serveur.');
      print(responseBody);
      return responseBody;
    } else {
      print('Erreur lors de la requête au serveur pour obtenir les arrêts: ${response.body}');
    }
    return [];
  } catch (e) {
    print('Erreur lors de la récupération des arrêts: $e');
    return [];
  }
}

Future<void> enableBackgroundExecution() async {
  const androidConfig = FlutterBackgroundAndroidConfig(
    notificationTitle: "Navette",
    notificationText: "Exécution en arrière-plan",
    notificationImportance: AndroidNotificationImportance.Default,
  );
  await FlutterBackground.initialize(androidConfig: androidConfig);
  await FlutterBackground.enableBackgroundExecution();
}

//Partie Scan de Balise

void checkBluetoothAndStartScan() async {
  if (await flutterBlue.isOn) {
    print("On va récupérer userData");
      _userData = await fetchUserData();
      listeArrets = await getArretsFromServer();
      print(_userData);
     _startPeriodicBluetoothScan(_userData);
  } else {
    print("Bluetooth n'est pas activé");
  }
}


void _startPeriodicBluetoothScan(Map<String, dynamic>? userData) {

  // TEST Pour un passagé qui trouve un arrêt (pris au pif)
  //_sendNotificationPassager(listeArrets[1]);

  //TEST Pour un conducteur qui truve SA balise
  //_sendNotificationConducteur();
  //A DES FINS DE TESTS, LE SCAN DES BALISES EST DESACTIVE .
  _scanTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
    print("test");
    _startBluetoothScan(_userData);
  });
}


void initializeNotifications() {
  var androidInitializationSettings = const AndroidInitializationSettings('icon_notification');
  var initializationSettings = InitializationSettings(android: androidInitializationSettings);
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();
  flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();

  print('initialisation notification');
  fltrNotification.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse notificationResponse) {
      print("navigatorKey.currentState:");
      print(globals.navigatorKey.currentState);
      print("notificationResponse:");
      print(notificationResponse.notificationResponseType);

      // Gestion de la réponse de la notification
      if (globals.navigatorKey.currentState != null) {
        BuildContext context = globals.navigatorKey.currentState!.overlay!.context;
        switch (notificationResponse.notificationResponseType) {
          case NotificationResponseType.selectedNotification:
          // Action à effectuer quand la notification est sélectionnée
            print("Notification sélectionnée");
            _onSelectNotification(notificationResponse.payload, context);
            break;
          case NotificationResponseType.selectedNotificationAction:
          // TODO: Gérer ce cas si nécessaire
            break;
        }
      } else {
        print("NavigatorState est null");
      }
    },
  );
}

void _startBluetoothScan(Map<String, dynamic>? userData) async {
  // Vérifier si le scan est déjà en cours et l'arrêter si nécessaire
  print("tentative de scan...");
  if (searchBLE == true) {
    print("scan...");

    _scanSubscription = flutterBlue
        .scan(timeout: const Duration(seconds: 4))
        .listen((scanResult) {
      if (navigatorKey.currentState != null) {
        // Utilisation de GlobalKey
        ScaffoldMessenger.of(navigatorKey.currentState!.context).showSnackBar(
          const SnackBar(
            content: Text("Scanning Bluetooth..."),
            duration: Duration(seconds: 3),
          ),
        );
      }

      //Scan Conducteur
      if (userData?['role'] == "driver") {
        print(scanResult.device.id.toString());
        if (scanResult.device.id.toString().toUpperCase() ==
            userData?['mac'].toUpperCase()) {
          _sendNotificationConducteur();
        }
      }


      //Scan Arret passagé
      if (userData?['role'] == "passenger") {
        print(scanResult.device.id.toString());
        for (var arret in listeArrets) {
          if (scanResult.device.id.toString().toUpperCase() == arret['mac'].toUpperCase()) {
            print("Arrêt trouvé: ${arret['id']}");
            _sendNotificationPassager(arret);
            break; // Sortir de la boucle une fois l'arrêt trouvé
          }
        }

      }
    });
  }
}

void stopScan() {
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
  var androidDetails = const AndroidNotificationDetails(
    'channel_ID', // Assurez-vous que cet ID correspond à celui utilisé dans initializeNotifications
    'channel_name', // Nom de la chaîne pour l'affichage dans les paramètres de la notification
    importance: Importance.max, // Définit l'importance de la notification
    priority: Priority.high, // Définit la priorité de la notification
    ticker: 'ticker', // Texte qui s'affiche dans la barre d'état lors de la réception de la notification
    icon: 'icon_notification', // cette icône est présente dans le dossier res/drawable du projet Android
    // on peut ajoutez d'autres paramètres si nécessaire, comme le son, la vibration, etc.
  );

  var platformDetails = NotificationDetails(android: androidDetails);

  print("Envoie de la notification conducteur");
  stopScan();
  await fltrNotification.show(
    0, // ID unique pour la notification, assurez-vous qu'il est unique pour chaque notification
    'Voulez vous covoiturer ?', // Titre de la notification
    'Combien de passagers voulez-vous prendre?', // Corps de la notification
    platformDetails,
    payload: 'chauffeur', // Payload pour identifier cette notification spécifique
  );
}

    Future<void> _sendNotificationPassager(Map<String, dynamic> arret) async {
      var androidPlatformChannelSpecifics = const AndroidNotificationDetails(
        'channel_ID',
        'channel_name',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'ticker',
        icon: 'icon_notification', // Référence à l'icône dans le dossier drawable
      );

      stopScan();
      var platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);

      String title = 'Arrêt Approchant 🚌'; // Exemple de titre
      String body = 'Votre arrêt à ${arret['departure']} pour ${arret['arrival']} est proche!'; // Utilisation des informations de l'arrêt
      ArretProche = jsonEncode(arret);
      print("notification passager send");

      await flutterLocalNotificationsPlugin.show(
          3, // Assurez-vous que l'ID de la notification est unique
          title, // Titre de la notification
          body, // Corps de la notification
          platformChannelSpecifics,
          payload: 'reponse_passager' // Pas besoin de payload pour cette notification
      );
    }



    Future _onSelectNotification(String? payload, BuildContext context) async {
  print("Notification traitée avec payload: $payload");
  if (payload == 'chauffeur') {
    TextEditingController departEditingController = TextEditingController();
    TextEditingController arriveeEditingController = TextEditingController();
    TextEditingController passagersEditingController = TextEditingController();

    // Afficher une boîte de dialogue pour saisir les informations
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Informations sur le trajet'),
        content: Column(
          mainAxisSize: MainAxisSize.min, // Pour s'assurer que la colonne prend la taille minimale
          children: <Widget>[
            TextField(
              controller: departEditingController,
              decoration: const InputDecoration(
                labelText: 'Départ',
              ),
            ),
            TextField(
              controller: arriveeEditingController,
              decoration: const InputDecoration(
                labelText: 'Arrivée',
              ),
            ),
            TextField(
              controller: passagersEditingController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Nombre de passagers',
              ),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('OK'),
            onPressed: () {
              // Récupération et transformation des données en majuscules
              String depart = departEditingController.text.toUpperCase();
              String arrivee = arriveeEditingController.text.toUpperCase();
              String nombrePassagers = passagersEditingController.text;

              if (nombrePassagers.isNotEmpty) {
                // Envoyer les informations au serveur
                stopScan();
                _sendConducteurInfoToServer(depart, arrivee, int.parse(nombrePassagers));
              }
              Navigator.of(context).pop(); // Fermer le dialogue
            },
          ),
        ],
      ),
    );
  }
  else if (payload == 'reponse_passager') {
    // Décoder le payload pour obtenir les informations de l'arrêt
    Map<String, dynamic> arret = jsonDecode(ArretProche);

    // Initialiser les TextEditingController avec les données de l'arrêt
    TextEditingController departEditingController = TextEditingController(text: arret['departure'].toString().toUpperCase());
    TextEditingController arriveeEditingController = TextEditingController(text: arret['arrival'].toString().toUpperCase());

    // Afficher une boîte de dialogue pour demander la réponse de l'utilisateur
    Map<String, dynamic>? result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Arrêt trouvé !'),
        content: Column(
          mainAxisSize: MainAxisSize.min, // Pour s'assurer que la colonne prend la taille minimale
          children: <Widget>[
            const Text('Cherchez vous un chauffeur ?'),
            TextField(
              controller: departEditingController,
              decoration: const InputDecoration(
                labelText: 'Départ',
              ),
              readOnly: true, // Rendre le champ en lecture seule
            ),
            TextField(
              controller: arriveeEditingController,
              decoration: const InputDecoration(
                labelText: 'Arrivée',
              ),
              readOnly: true, // Rendre le champ en lecture seule
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop({'response': true, 'depart': arret['departure'].toString().toUpperCase(), 'arrivee': arret['arrival'].toString().toUpperCase()}),
            child: const Text('OUI'),
          ),
          TextButton(
            onPressed: () async {
              // Il n'est pas nécessaire de récupérer le résultat ici, car cette action ne retourne rien directement
              Navigator.of(context).pop({'response': false});
            },
            child: const Text('NON'),
          ),
        ],
      ),
    );

    // Vérifier le résultat après la fermeture de la boîte de dialogue
    if (result != null && result['response'] == true) {
      // L'utilisateur a appuyé sur "OUI" et a fourni des informations
      print("ok");
      stopScan();
      await _sendPassengerResponseToServer(_userData, result['depart'], result['arrivee']);
    }
  }

  else if (payload == 'show_passenger_data') {
    passengerInfo?['history'] = [];
    try {
      if(passengerInfo?['mail'] != null) {
        var response = await http.post(
          Uri.parse('http://10.42.0.1:4443/history'),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
            'Authorization': authToken,
          },
          body: jsonEncode({
            'mail': passengerInfo?['mail'],
          }),
        );
        print("history");
        print(response.statusCode);
        if (response.statusCode == 200) {
          var historyList = jsonDecode(response.body) as List;
          passengerInfo?['history'] = historyList;
        } else {
          print('Erreur lors du démarrage du voyage: ${response.body}');
        }
      }
    } catch (e) {
      print('Erreur lors de l\'envoi du démarrage du voyage: $e');
    }

    // Afficher une boîte de dialogue avec les informations du passager et l'historique des voyages
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Information Passager'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Email: ${passengerInfo?['mail']}'),
                if (passengerInfo?['history']?.isNotEmpty ?? false)
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: passengerInfo?['history']?.length ?? 0,
                      itemBuilder: (context, index) {
                        var historyItem = passengerInfo?['history'][index];
                        return ListTile(
                          title: Text("${historyItem['departure']} -> ${historyItem['arrival']}"),
                          subtitle: Text("Date: ${historyItem['registered']}"),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Fermer'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  else if (payload == 'show_conducteur_data') {
    try {
      var response = await http.post(
        Uri.parse('http://10.42.0.1:4443/history'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': authToken,
        },
        body: jsonEncode({
          'mail': driverInfo?['mail'],
        }),
      );
      print("history");
      print(response.statusCode);
      if (response.statusCode == 200) {
        var historyList = jsonDecode(response.body) as List;
        driverInfo?['history'] = historyList;
      } else {
        print('Erreur lors du démarrage du voyage: ${response.body}');
      }
    } catch (e) {
      print('Erreur lors de l\'envoi du démarrage du voyage: $e');
    }

    // Modification ici
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        // Vérifier si l'historique est vide ou non
        bool isHistoryEmpty = driverInfo?['history']?.isEmpty ?? true;

        print('historique');
        print(isHistoryEmpty);

        return AlertDialog(
          title: const Text('Information Conducteur'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Nom: ${driverInfo?['name']}'),
                Text('Email: ${driverInfo?['driver']}'),
                Text('Plaque: ${driverInfo?['numberplate']}'),
                const Text('Historique :'),
                // Conditionnellement afficher le SizedBox uniquement si l'historique n'est pas vide
                if (!isHistoryEmpty)
                  SizedBox(
                    height: 200, // Hauteur fixe pour le conteneur ListView.builder
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: driverInfo?['history']?.length ?? 0,
                      itemBuilder: (context, index) {
                        var historyItem = driverInfo?['history'][index];
                        return ListTile(
                          title: Text("${historyItem['departure']} -> ${historyItem['arrival']}"),
                          subtitle: Text("Date: ${historyItem['date']}"),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Fermer'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );

  }


}

//Partie Passager
//Partie Inscription à un voyage

Future<void> _sendPassengerResponseToServer(Map<String, dynamic>? userData ,String departure, String arrival) async {
  try {
    Timer.periodic(const Duration(seconds: 10), (Timer timer) async {
        // Inscrire le passager à un voyage
        var response = await http.post(
          Uri.parse('http://10.42.0.1:4443/match'),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
            'Authorization': authToken,
          },
          body: jsonEncode({
            'departure': departure,
            'arrival': arrival
          }),
        );
        print("response:");
        print(response.statusCode);
        if (response.statusCode == 201 || response.statusCode == 200) {
          String jsonString = response.body;

          // Trouver l'index où commence le JSON valide
          int jsonStartIndex = jsonString.indexOf('{');
          if (jsonStartIndex != -1) {
            // Extraire la partie JSON valide de la chaîne
            String jsonValid = jsonString.substring(jsonStartIndex);
            try {
              // Décoder le JSON valide
              var decoded = json.decode(jsonValid);
              // Accéder à la partie spécifique du JSON
              var desiredObject = decoded['body'][0];
              print("driver associé : ");
              print(desiredObject);
              String adresseMACConducteur = desiredObject['mac'];
              driverInfo = desiredObject;
              _showNotification(desiredObject);
              timer.cancel(); // Arrêter le timer si un match est trouvé
              // Continuez avec le traitement de l'adresse MAC du conducteur
              _checkVoyageConducteur(adresseMACConducteur);
            } catch (e) {
              print("Erreur lors du décodage du JSON: $e");
            }
          } else {
            print("JSON valide non trouvé dans la réponse");
          }
        }

    });
  } catch (e) {
    print('Erreur lors de l\'envoi des informations de passager: $e');
  }
}

//Verification du voyage
FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin(); // Ajouté pour les notifications

// Afficher une notification au passagé disant qu'un voyage est trouvé et que le conducteur vient le chercher !
Future<void> _showNotification(Map<String, dynamic> driverInfo) async {
  var androidPlatformChannelSpecifics = const AndroidNotificationDetails(
    'channel_ID',
    'channel_name',
    importance: Importance.max,
    priority: Priority.high,
    ticker: 'ticker',
    icon: 'icon_notification', // Référence à l'icône dans le dossier drawable
    ongoing: true, // Rend la notification persistante
  );

  var platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);

  print("notification passagé send");

  await flutterLocalNotificationsPlugin.show(
      2,
      'Voyage Trouvé',
      'Voyage avec ${driverInfo['name']} trouvé!',
      platformChannelSpecifics,
      payload: 'show_conducteur_data'
  );
}

//Partie Voyage qui vient de _sendPassengerResponseToServer

Timer? _voyageCheckTimer;
Duration totalDetectionDuration = const Duration();
DateTime? scanStartTime;

void _checkVoyageConducteur(String adresseMACConducteur) {
  scanStartTime = DateTime.now();
  _voyageCheckTimer =
      Timer.periodic(const Duration(seconds: 5), (Timer timer) async {
    // Implémentez ici votre logique de scan Bluetooth
    bool isConducteurNearby = await scanForConducteur(adresseMACConducteur);

    if (isConducteurNearby) {
      totalDetectionDuration += const Duration(seconds: 5);
    }

    //Temps de détection de la balise conducteur pour démarrer le voyage réduit de 10 à 1 minute pour le bien de la démo
    if (DateTime.now().difference(scanStartTime!).inMinutes >= 1) {
      if(true){
      //if (totalDetectionDuration.inMinutes >= 7) {
        print("Conducteur trouvé !");
        _sendVoyageStart(adresseMACConducteur);
        timer.cancel();
      } else {
        // Réinitialiser pour la prochaine fenêtre de 10 minutes
        totalDetectionDuration = const Duration();
        scanStartTime = DateTime.now();
      }
    }
  });
}

Future<bool> scanForConducteur(String adresseMACConducteur) async {
  if (!searchBLE) {
    return false;
  }

  searchBLE = false;
  bool conducteurFound = false;

  // Créer un listener pour le stream de scan
  var subscription = flutterBlue
      .scan(timeout: const Duration(seconds: 4))
      .listen((scanResult) {
    // Vérifier si l'adresse MAC du conducteur est trouvée
    if (scanResult.device.id.id == adresseMACConducteur) {
      conducteurFound = true;
    }
  });

  // Attendre la fin du scan
  await Future.delayed(const Duration(seconds: 4));

  // Annuler l'abonnement au stream pour arrêter le scan
  await subscription.cancel();

  searchBLE = true;
  return conducteurFound;
}

Future<void> _sendVoyageStart(String adresseMACConducteur) async {
  try {
    var response = await http.patch(
      Uri.parse('http://10.42.0.1:4443/state'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': authToken,
      },
    );
    print(response.statusCode);
    if (response.statusCode == 201) {
      print("ok");
      _checkVoyageEnd(adresseMACConducteur); // Passez à la vérification de la fin du voyage
    } else {
      print('Erreur lors du démarrage du voyage: ${response.body}');
    }
  } catch (e) {
    print('Erreur lors de l\'envoi du démarrage du voyage: $e');
  }
}

Timer? _voyageEndCheckTimer;
DateTime? lastDetectionTime;

void _checkVoyageEnd(String adresseMACConducteur) {
  lastDetectionTime = DateTime.now();
  _voyageEndCheckTimer = Timer.periodic(const Duration(seconds: 5), (Timer timer) async {
    bool isConducteurNearby = await scanForConducteur(adresseMACConducteur);
    print("oncheckvoyageEnd?");
    print(DateTime.now().difference(lastDetectionTime!).inMinutes);
    print(isConducteurNearby);
    if (isConducteurNearby) {
      lastDetectionTime = DateTime.now();
      //1min d'attente pour la démo
    } else if (DateTime.now().difference(lastDetectionTime!).inMinutes >= 1) {
      _sendVoyageEnd();
      timer.cancel();
    }
  });
}

Future<void> _sendVoyageEnd() async {
  try {
    print("FIN DU VOYAGE !");
    var response = await http.delete(
      Uri.parse('http://10.42.0.1:4443/state'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': authToken,
      },
      // Ajoutez les données nécessaires dans le corps de la requête
    );
    print(response.statusCode);
    if (response.statusCode == 201) {
      //Notification de remerciement de fin de voyage
      var androidPlatformChannelSpecifics = const AndroidNotificationDetails(
        'channel_ID',
        'channel_name',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'ticker',
        icon: 'icon_notification', // Référence à l'icône dans le dossier drawable
      );

      var platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);

      print("notification de fin de voyage send");

      await flutterLocalNotificationsPlugin.show(
          3, // Assurez-vous que l'ID de la notification est unique
          'Voyage Terminé 🎉', // Titre de la notification
          'Merci d\'avoir voyagé avec nous ! Bonne journée 😊', // Corps de la notification
          platformChannelSpecifics,
          payload: '' // Pas besoin de payload pour cette notification
      );

    } else {
      print('Erreur lors de la fin du voyage: ${response.body}');
    }
  } catch (e) {
    print('Erreur lors de l\'envoi de la fin du voyage: $e');
  }
}

//Partie Conducteur
//Partie création du voyage
Future<void> _sendConducteurInfoToServer(String departure, String arrival, int passengerCount) async {
  print(passengerCount);
  try {

    // Envoyer les informations au serveur
    await http.put(
      Uri.parse('http://10.42.0.1:4443/travel'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': authToken,
      },
      body: jsonEncode({
        'departure': departure,
        'arrival': arrival,
        'seats': passengerCount
      }),
    );
  } catch (e) {
    print('Erreur lors de l\'envoi des informations de passager: $e');
  }

  checkForPassengers();
}

//requête répétitive pour savoir si un passagé s'est inscrit au voyage
Future<void> checkForPassengers() async {
  // Définir le Timer en dehors pour pouvoir l'annuler plus tard
  Timer? timer;

  timer = Timer.periodic(const Duration(seconds: 5), (Timer t) async {
    print("Scan for passager");
    var response = await http.get(
      Uri.parse('http://10.42.0.1:4443/travel'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': authToken,
      },
    );
    print("POST :TRAVEL");
    print(response.statusCode);
    print(jsonDecode(response.body));
    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      print("information du passagé");
      print(data);
      if (data[0]?['mail'] != null) {
        // Si un passager est trouvé, affichez la notification
        _showConducteurNotification(data[0]!);

        // Et annulez le Timer pour arrêter la boucle
        if (timer != null) {
          timer.cancel();
        }
      }
    } else {
      print('Erreur lors de la vérification des passagers: ${response.body}');
    }
  });
}




//Si un passagé est dans le voyage, on envoit un notif au conducteur pour l'informé et lui montrer le profil
Future<void> _showConducteurNotification(Map<String, dynamic> passengerInfoFromServeur) async {
  var androidPlatformChannelSpecifics = const AndroidNotificationDetails(
    'channel_ID',
    'channel_name',
    importance: Importance.max,
    priority: Priority.high,
    ticker: 'ticker',
    icon: 'icon_notification', // Référence à l'icône dans le dossier drawable
    ongoing: true, // Rend la notification persistante
  );

  var platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
  passengerInfo = passengerInfoFromServeur;
  print("notification conducteur send");

  await flutterLocalNotificationsPlugin.show(
      2,
      'Voyageur Trouvé',
      'Tu peux aller chercher ${passengerInfo?['name']} !',
      platformChannelSpecifics,
      payload: 'show_passenger_data'
  );
}
