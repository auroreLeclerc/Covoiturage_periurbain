import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;


FlutterLocalNotificationsPlugin fltrNotification = FlutterLocalNotificationsPlugin();
Timer? _cooldownTimer;
FlutterBlue flutterBlue = FlutterBlue.instance;
Timer? _scanTimer;
String? MACConducteur;
StreamSubscription? _scanSubscription;
bool searchBLE = true;
Map<String, dynamic>? _userData;
GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();


Future<Map<String, dynamic>?> fetchUserData() async {
  final response = await http.get(Uri.parse('http://10.0.2.2:4443/account'));
  print("user: ");
  print(response.body);
  if (response.statusCode == 200) {
    return jsonDecode(response.body) as Map<String, dynamic>;
  } else {
    print('Failed to load user data');
    return null;
  }
}

Future<void> enableBackgroundExecution() async {
  final androidConfig = FlutterBackgroundAndroidConfig(
    notificationTitle: "Votre Application",
    notificationText: "Exécution en arrière-plan",
    notificationImportance: AndroidNotificationImportance.Default,
  );
  await FlutterBackground.initialize(androidConfig: androidConfig);
  await FlutterBackground.enableBackgroundExecution();
}



  //Partie Scan de Balise

  void checkBluetoothAndStartScan(String role) async {
    if (await flutterBlue.isOn) {
      print("On va récupérer userData");
      _userData = await fetchUserData();
      _startPeriodicBluetoothScan(role);
    } else {
      print("Bluetooth n'est pas activé");
    }
  }

  void _startPeriodicBluetoothScan(String role) {
    _scanTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      print("test");
      _startBluetoothScan(role);
    });
  }


  void _initializeNotifications() {
    var initializationSettingsAndroid = const AndroidInitializationSettings('app_icon');
    var initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    fltrNotification.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse notificationResponse) {
        if (navigatorKey.currentState != null) {
          BuildContext context = navigatorKey.currentState!.context;
          switch (notificationResponse.notificationResponseType) {
            case NotificationResponseType.selectedNotification:
              _onSelectNotification(notificationResponse.payload, context);
              break;
          // Autres cas
            case NotificationResponseType.selectedNotificationAction:
              // TODO: Handle this case.
          }
        }
      },
    );

  }

  Future _onSelectNotification(String? payload, BuildContext context) async {
    if (payload == 'chauffeur') {
      // Afficher une boîte de dialogue pour saisir le nombre de passagers
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Nombre de passagers'),
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
          title: const Text('Arrêt trouvé !'),
          content: const Text('Cherchez vous un chauffeur ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('OUI'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('NON'),
            ),
          ],
        ),
      );

      if (response) {
        // L'utilisateur a appuyé sur "OUI"
        await _sendPassengerResponseToServer(_userData);
      }
    }
  }


  void _startBluetoothScan(String role) async {
    // Vérifier si le scan est déjà en cours et l'arrêter si nécessaire
    print("tentative de scan...");
    if (searchBLE == true) {
      print("scan...");
      _scanSubscription = flutterBlue.scan(timeout: const Duration(seconds: 4)).listen((scanResult) {
        if (navigatorKey.currentState != null) { // Utilisation de GlobalKey
          ScaffoldMessenger.of(navigatorKey.currentState!.context).showSnackBar(
            const SnackBar(
              content: Text("Scanning Bluetooth..."),
              duration: Duration(seconds: 3),
            ),
          );
        }

        //Scan Conducteur
        //for (var conducteur in defaultConducteurListe) {
        if(role == "driver") {
          print(scanResult.device.id.toString());
          if (scanResult.device.id.toString() == "D5:42:AA:EB:8F:07") {
            //493
            print("findconducteur");
            _sendNotificationConducteur();
            //break;
            //}
        }
      }

      //Scan Arret passagé
        //for (var arret in listeArrets) {
        if(role == "passenger") {
          print(scanResult.device.id.toString());
          if (scanResult.device.id.toString() == "FB:86:61:5A:84:6B") { //496
            print("findpassager");
            _sendNotificationPassager();
            //break;
          }
        }
        //}
      }
        );
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
    var androidPlatformChannelSpecifics = const AndroidNotificationDetails(
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
      String? id = _userData?['id'];
      await _sendPassengerResponseToServer(_userData);
    }
  }

//Partie Passager
//Partie Inscription à un voyage

Future<void> _sendPassengerResponseToServer(Map<String, dynamic>? userData) async {
  try {
    Timer.periodic(Duration(seconds: 10), (Timer timer) async {
      if (userData != null && userData['id'] != null) {
        // Inscrire le passager à un voyage
        var response = await http.post(
          Uri.parse('http://10.0.2.2:4443/match'),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode({
            'userdata': userData,
            'departure': "Amiens",
            'arrival': "Paris"
          }),
        );

        if (response.statusCode == 200) {
          var data = jsonDecode(response.body);
          if (data != null && data['driverMacAddress'] != null) {
            String adresseMACConducteur = data['driverMacAddress'];
            _showNotification(data);
            timer.cancel(); // Arrêter le timer si un match est trouvé
            // Continuez avec le traitement de l'adresse MAC du conducteur
            _checkVoyageConducteur(adresseMACConducteur);
          }
        } else {
          print('Erreur lors de l\'inscription au voyage: ${response.body}');
        }
      } else {
        print('Erreur : Les données utilisateur sont manquantes ou incomplètes.');
      }
    });
  } catch (e) {
    print('Erreur lors de l\'envoi des informations de passager: $e');
  }
}


//Verification du voyage
FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin(); // Ajouté pour les notifications

// Afficher une notification au passagé disant qu'un voyage est trouvé et que le conducteur vient le chercher !
Future<void> _showNotification(Map<String, dynamic> driverInfo) async {
  const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'your_channel_id', 'your_channel_name',
      importance: Importance.max, priority: Priority.high, showWhen: false);
  const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
  await flutterLocalNotificationsPlugin.show(
      0, 'Voyage Trouvé', 'Voyage avec ${driverInfo['name']} trouvé!', platformChannelSpecifics);

}

void onNotificationClick(Map<String, dynamic> driverInfo) {
  navigatorKey.currentState?.push(
    MaterialPageRoute(
      builder: (context) => DriverInfoPage(driverInfo: driverInfo),
    ),
  );
}


//Si le passager clique sur la notification précédente, on le redirige vers une page de résumé du conducteur
class DriverInfoPage extends StatelessWidget {
  final Map<String, dynamic> driverInfo;

  // Assurez-vous que le constructeur est correctement déclaré avec 'Key? key'
  DriverInfoPage({Key? key, required this.driverInfo}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Informations du Conducteur'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('Nom: ${driverInfo['name']}'),
            Text('Email: ${driverInfo['email']}'),
            Text('Plaque d\'immatriculation: ${driverInfo['numberplate']}'),
            Text('Adresse MAC: ${driverInfo['mac']}'),
            // Ajoutez plus de champs selon vos besoins
          ],
        ),
      ),
    );
  }
}

//Partie Voyage qui vient de _sendPassengerResponseToServer

Timer? _voyageCheckTimer;
Duration totalDetectionDuration = Duration();
DateTime? scanStartTime;

void _checkVoyageConducteur(String adresseMACConducteur) {
  scanStartTime = DateTime.now();
  _voyageCheckTimer = Timer.periodic(Duration(seconds: 5), (Timer timer) async {
    // Implémentez ici votre logique de scan Bluetooth
    bool isConducteurNearby = await scanForConducteur(adresseMACConducteur);

    if (isConducteurNearby) {
      totalDetectionDuration += Duration(seconds: 5);
    }

    if (DateTime.now().difference(scanStartTime!).inMinutes >= 10) {
      if (totalDetectionDuration.inMinutes >= 7) {
        _sendVoyageStart(adresseMACConducteur);
        timer.cancel();
      } else {
        // Réinitialiser pour la prochaine fenêtre de 10 minutes
        totalDetectionDuration = Duration();
        scanStartTime = DateTime.now();
      }
    }
  });
}

Future<bool> scanForConducteur(String adresseMACConducteur) async {
  bool conducteurFound = false;

  // Créer un listener pour le stream de scan
  var subscription = flutterBlue.scan(timeout: Duration(seconds: 4)).listen((scanResult) {
    // Vérifier si l'adresse MAC du conducteur est trouvée
    if (scanResult.device.id.id == adresseMACConducteur) {
      conducteurFound = true;
    }
  });

  // Attendre la fin du scan
  await Future.delayed(Duration(seconds: 4));

  // Annuler l'abonnement au stream pour arrêter le scan
  await subscription.cancel();

  return conducteurFound;
}




Future<void> _sendVoyageStart(String adresseMACConducteur) async {
  try {
    var response = await http.patch(
      Uri.parse('http://10.0.2.2:4443/state'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      // Ajoutez les données nécessaires dans le corps de la requête
    );

    if (response.statusCode == 200) {
      // Gérez la réponse du serveur
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
  _voyageEndCheckTimer = Timer.periodic(Duration(seconds: 5), (Timer timer) async {
    bool isConducteurNearby = await scanForConducteur(adresseMACConducteur);

    if (isConducteurNearby) {
      lastDetectionTime = DateTime.now();
    } else if (lastDetectionTime != null && DateTime.now().difference(lastDetectionTime!).inMinutes >= 5) {
      _sendVoyageEnd();
      timer.cancel();
    }
  });
}


Future<void> _sendVoyageEnd() async {
  try {
    var response = await http.delete(
      Uri.parse('http://10.0.2.2:4443/state'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      // Ajoutez les données nécessaires dans le corps de la requête
    );

    if (response.statusCode == 200) {
      // Gérez la réponse du serveur
    } else {
      print('Erreur lors de la fin du voyage: ${response.body}');
    }
  } catch (e) {
    print('Erreur lors de l\'envoi de la fin du voyage: $e');
  }
}


//Partie Conducteur
//Partie création du voyage
  Future<void> _sendConducteurInfoToServer(int passengerCount) async {
    print(passengerCount);
    try {

      String? id = _userData?['id'];
      String? macAddress = MACConducteur;

      // Envoyer les informations au serveur
      await http.put(
        Uri.parse('http://10.0.2.2:4443/travel'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({
          'userdata' : _userData,
          'departure' : "Amiens",
          'arrival' : "Paris",
          'seats': passengerCount
        }),
      );
    } catch (e) {
      print('Erreur lors de l\'envoi des informations de passager: $e');
    }
  }

  //requête répétitive pour savoir si un passagé s'est inscrit au voyage
Future<void> checkForPassengers(String conducteurId) async {
  Timer.periodic(Duration(seconds: 5), (Timer timer) async {
    var response = await http.post(
      Uri.parse('http://10.0.2.2:4443/travel'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({'conducteurId': conducteurId}),
    );

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      if (data != null && data['passengerFound']) {
        _showConducteurNotification(data['passengerInfo']);
        timer.cancel(); // Arrêter le timer si un passager est trouvé
      }
    } else {
      print('Erreur lors de la vérification des passagers: ${response.body}');
    }
  });
}

//Si un passagé est dans le voyage, on envoit un notif au conducteur pour l'informé et lui montrer le profil
Future<void> _showConducteurNotification(Map<String, dynamic> passengerInfo) async {
  const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'your_channel_id', 'your_channel_name',
      importance: Importance.max, priority: Priority.high, showWhen: false);
  const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
  await flutterLocalNotificationsPlugin.show(
      0, 'Passager Trouvé', 'Un passager a été trouvé pour votre voyage!', platformChannelSpecifics);
}

void onConducteurNotificationClick(Map<String, dynamic> passengerInfo) {
  navigatorKey.currentState?.push(
    MaterialPageRoute(
      builder: (context) => PassengerInfoPage(passengerInfo: passengerInfo),
    ),
  );
}

//Page d'information du passager pour le conducteur

class PassengerInfoPage extends StatelessWidget {
  final Map<String, dynamic> passengerInfo;

  PassengerInfoPage({Key? key, required this.passengerInfo}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Informations du Passager'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('Nom: ${passengerInfo['name'] ?? 'Non disponible'}'),
            Text('Email: ${passengerInfo['email'] ?? 'Non disponible'}'),
            Text('Adresse: ${passengerInfo['address'] ?? 'Non disponible'}'),
            Text('Téléphone: ${passengerInfo['phone'] ?? 'Non disponible'}'),
            // Ajoutez plus de champs selon vos besoins
          ],
        ),
      ),
    );
  }
}
