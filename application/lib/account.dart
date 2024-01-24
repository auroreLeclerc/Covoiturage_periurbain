import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'main.dart';
import 'auth_helper.dart';

class AccountDetailsPage extends StatelessWidget {
  final Map<String, dynamic> userData;

  const AccountDetailsPage(this.userData, {super.key});

  Future<void> signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    await logout(); // Cela devrait maintenant fonctionner
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const Application()),
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
        title: const Text('Détails du Compte'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
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
            const SizedBox(height: 20),
            const Text(
              'Informations perso',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextField(
              decoration: InputDecoration(
                labelText: 'Prénom',
                hintText: (userData['name'] == null || userData['name'].isEmpty)
                    ? ''
                    : userData['name'],
              ),
            ),
            TextField(
              decoration: InputDecoration(
                labelText: 'Email',
                hintText:
                    (userData['email'] == null || userData['email'].isEmpty)
                        ? ''
                        : userData['email'],
              ),
            ),
            const TextField(
              decoration: InputDecoration(labelText: 'Numéro de téléphone'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 20),
            const Text(
              'Informations bancaires',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const TextField(
              decoration: InputDecoration(labelText: 'Infos de compte'),
            ),
          ],
        ),
      ),
    );
  }
}
