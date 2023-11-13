import 'package:flutter/material.dart';

class InscriptionForm extends StatefulWidget {
  @override
  _InscriptionFormState createState() => _InscriptionFormState();
}

class _InscriptionFormState extends State<InscriptionForm> {
  final _formKey = GlobalKey<FormState>();
  String? username;
  String? email;
  String? password;

  void _submit() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      // Ici, envoyez les données à votre serveur
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Inscription'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              Image.asset('assets/Navette2.png', height: 100), // Remplacez avec votre logo
              SizedBox(height: 20),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Nom d\'utilisateur',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onSaved: (value) => username = value,
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Veuillez entrer un nom d\'utilisateur';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onSaved: (value) => email = value,
                validator: (value) {
                  if (value!.isEmpty || !value.contains('@')) {
                    return 'Veuillez entrer une adresse email valide';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Mot de passe',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                obscureText: true,
                onSaved: (value) => password = value,
                validator: (value) {
                  if (value!.isEmpty || value.length < 6) {
                    return 'Le mot de passe doit contenir au moins 6 caractères';
                  }
                  return null;
                },
              ),
              SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  primary: Colors.white, // Couleur du bouton
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18.0),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                ),
                onPressed: _submit,
                child: Text('Inscrivez-vous'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
