import 'package:flutter/material.dart';

class AccountDetailsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Détails du Compte'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 50,
              // Remplacez avec votre image
              backgroundImage: AssetImage('assets/profile_pic.png'),
            ),
            SizedBox(height: 20),
            Text(
              'Informations perso',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextField(
              decoration: InputDecoration(labelText: 'Nom'),
            ),
            TextField(
              decoration: InputDecoration(labelText: 'Prénom'),
            ),
            TextField(
              decoration: InputDecoration(labelText: 'Numéro de téléphone'),
              keyboardType: TextInputType.phone,
            ),
            TextField(
              decoration: InputDecoration(labelText: 'Adresse'),
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
