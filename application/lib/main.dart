import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';
import 'dart:math';

import './account.dart'; // page de compte

void main() async {
  runApp(Application());
}

class Application extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Navette',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  final List<String> ecoPhrases = [
    'Protégeons la planète ensemble !',
    'Faisons un pas vers un avenir plus vert.',
    'Réduisons notre empreinte carbone.',
    // Ajoutez d'autres phrases écologiques ici...
  ];

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null;
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      return await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      print('Failed to sign in with Google: $e');
      return null;
    }
  }

  Future<UserCredential?> signInWithFacebook() async {
    try {
      final LoginResult result = await FacebookAuth.instance.login();
      if (result.status != LoginStatus.success) return null;
      final credential = FacebookAuthProvider.credential(result.accessToken!.token);
      return await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      print('Failed to sign in with Facebook: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final randomPhrase = ecoPhrases[Random().nextInt(ecoPhrases.length)];

    return Scaffold(
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Container(
          decoration: BoxDecoration(
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
                  style: TextStyle(
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
                SizedBox(height: 20),
                SignInButton(
                  Buttons.Facebook,
                  text: "Connecter avec Facebook",
                  onPressed: () {
                    signInWithFacebook();
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
                    // Implémentez la logique de connexion Navette ici
                  },
                ),
                SizedBox(height: 50), // Espacement entre les boutons et le texte "Pas de compte ?"
                Text(

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
                    // Implémentez la logique d'inscription ici
                  },
                  child: Text('Inscrivez-vous'),
                  style: ElevatedButton.styleFrom(
                    primary: Colors.blue, // Vous pouvez changer la couleur du bouton ici
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AccountDetailsPage()),
                    );
                  },
                  child: Text('DEV'),
                  style: ElevatedButton.styleFrom(
                    primary: Colors.blue, // Vous pouvez changer la couleur du bouton ici
                  ),
                ),

              ],
            ),
          ),
        ),
      ),
    );
  }
}
