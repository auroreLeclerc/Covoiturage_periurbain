import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'main.dart';
import 'auth_helper.dart';


class AccountDetailsPage extends StatelessWidget {
  final Map<String, dynamic> userData;

  AccountDetailsPage(this.userData);

  Future<void> signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    await logout();  // Cela devrait maintenant fonctionner
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => Application()),
          (Route<dynamic> route) => false,
    );
  }

  String? getPictureUrl(Map<String, dynamic> userData) {
    try {
      return userData['picture']['data']['url'] as String?;
    } catch (e) {
      return null;
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Détails du Compte'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => signOut(context),
          )
        ],
      ),
      body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundImage: (getPictureUrl(userData) != null)
                    ? NetworkImage(getPictureUrl(userData)!)
                    : null,
              ),
          SizedBox(height: 20),
          Text(
            'Informations perso',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Prénom',
                  hintText: (userData['name'] == null || userData['name'].isEmpty) ? '' : userData['name'],
                ),
              ),
          TextField(
            decoration: InputDecoration(labelText: 'Email',
                hintText: (userData['email'] == null || userData['email'].isEmpty) ? '' : userData['email'],
          ),
          ),
            TextField(
              decoration: InputDecoration(labelText: 'Numéro de téléphone'),
              keyboardType: TextInputType.phone,
            ),
            SizedBox(height: 20),
            Text(
              'Informations bancaires',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextField(
              decoration: InputDecoration(labelText: 'Infos de compte'),
            ),
          ],
        ),
      ),
    );
  }
}
