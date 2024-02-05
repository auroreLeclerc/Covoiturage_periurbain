import "dart:convert";

import "package:covoiturage_periurbain/account_update.dart";
import "package:covoiturage_periurbain/map_page.dart";
import "package:covoiturage_periurbain/user_data.dart";
import "package:email_validator/email_validator.dart";
import "package:flutter/material.dart";
import 'package:http/http.dart' as http;
import 'globals.dart' as globals;
import './background.dart'; //Lancer le scan des balises


class AccountConnection extends StatefulWidget {
  const AccountConnection({super.key});
  @override
  AccountConnectionState createState() {
    return AccountConnectionState();
  }
}

class AccountConnectionState extends State<AccountConnection> {
  final _formKey = GlobalKey<FormState>();
  late String mail;
  late String password;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Connecter à un compte"),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Image.network(catUrl, height: 200),
              TextFormField(
                  validator: (String? value) {
                    if (value == null || value.isEmpty) {
                      return "Veuillez renseigner ce champ.";
                    } else if (!EmailValidator.validate(value)) {
                      return "Please enter a valid email";
                    }
                    return null;
                  },
                  decoration: const InputDecoration(icon: Icon(Icons.email)),
                  onSaved: (String? value) => mail = value!,
                  initialValue: "aurore.leclerc@etud.u-picardie.fr"),
              TextFormField(
                  obscureText: true,
                  obscuringCharacter: "*",
                  validator: (String? value) => value == null || value.isEmpty
                      ? "Veuillez renseigner ce champ."
                      : null,
                  decoration: const InputDecoration(icon: Icon(Icons.password)),
                  onSaved: (String? value) => password = value!,
                  initialValue: "password"),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();

                      final Map<String, String> toSend = {
                        "mail": mail,
                        "password": password,
                      };
                      http.post(
                        Uri.parse('http://10.42.0.1:4443/account'),
                        headers: <String, String>{
                          'Content-Type': 'application/json; charset=UTF-8',
                        },
                        body: jsonEncode(toSend),
                      ).then((response) {
                        print("Response status: ${response.statusCode}");
                        print("Response body: ${response.body}");
                        if (response.statusCode == 200) {
                          globals.authToken = response.body;
                          http.get(
                              Uri.parse('http://10.42.0.1:4443/account'),
                              headers: <String, String>{
                                'Content-Type': 'application/json; charset=UTF-8',
                                'Authorization': globals.authToken
                              }
                          ).then((responseGet) {
                            print("responseGet status: ${responseGet.statusCode}");
                            print("responseGet body: ${responseGet.body}");
                            if (responseGet.statusCode != 426) {
                              // Logique pour gérer une réponse valide
                              final userDataReceived = jsonDecode(responseGet.body);

                              Map<String, dynamic> userData = {
                                'name': userDataReceived['name'],
                                'email': mail,
                                'id': null,
                                'token': globals.authToken
                              };

                              print("Initialisation du scan...");
                              checkBluetoothAndStartScan();

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => MapPage(
                                      userData: userData,
                                    )
                                ),
                              );
                            } else {
                              // Rediriger vers AccountUpdate si la réponse est vide
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => AccountUpdate(
                                          userData: UserData(
                                              email: mail,
                                              token: response.body
                                          )
                                      )
                                  )
                              );
                            }
                          });
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(response.body))
                          );
                        }
                      }).catchError((error) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(error.toString())),
                        );
                      });
                    }
                  },
                  child: const Text("Se connecter"),
                ),
              ),
            ],
          ),
        ));
  }
}
