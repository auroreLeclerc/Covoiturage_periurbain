import "dart:convert";

import "package:email_validator/email_validator.dart";
import "package:flutter/material.dart";
import 'package:http/http.dart' as http;

class AccountCreation extends StatefulWidget {
  const AccountCreation({super.key});
  @override
  AccountCreationState createState() {
    return AccountCreationState();
  }
}

class AccountCreationState extends State<AccountCreation> {
  final _formKey = GlobalKey<FormState>();
  final list = <DropdownMenuItem<String>>[
    const DropdownMenuItem(
      value: "passenger",
      child: Text("Passager"),
    ),
    const DropdownMenuItem(
      value: "driver",
      child: Text("Conducteur"),
    ),
  ];
  late String mail;
  late String name;
  late String password;
  late String? role = list.first.value;
  late String town;
  late String catUrl = "https://http.cat/images/100.jpg";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Créer un compte"),
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
                  validator: (String? value) => value == null || value.isEmpty
                      ? "Veuillez renseigner ce champ."
                      : null,
                  decoration: const InputDecoration(icon: Icon(Icons.person)),
                  onSaved: (String? value) => name = value!,
                  initialValue: "Aurore Leclerc"),
              TextFormField(
                  obscureText: true,
                  obscuringCharacter: "*",
                  validator: (String? value) => value == null || value.isEmpty
                      ? "Veuillez renseigner ce champ."
                      : null,
                  decoration: const InputDecoration(icon: Icon(Icons.password)),
                  onSaved: (String? value) => password = value!,
                  initialValue: "password"),
              DropdownButton<String>(
                value: role,
                icon: const Icon(Icons.drive_eta),
                onChanged: (String? value) {
                  // This is called when the user selects an item.
                  setState(() {
                    role = value!;
                  });
                },
                items: list,
              ),
              TextFormField(
                  validator: (String? value) => value == null || value.isEmpty
                      ? "Veuillez renseigner ce champ."
                      : null,
                  decoration:
                      const InputDecoration(icon: Icon(Icons.location_city)),
                  onSaved: (String? value) => town = value!,
                  initialValue: "Albert"),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();

                      final Map<String, String> toSend = {
                        "mail": mail,
                        "name": name,
                        "password": password,
                        "role": role.toString(),
                        "town": town
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
                        setState(() {
                          catUrl =
                              "https://http.cat/images/${response.statusCode}.jpg";
                        });
                        if (response.statusCode == 201) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Compte créer avec Succès")));
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(response.body)));
                        }

                      }).catchError((error) {
                        setState(() {
                          catUrl = "https://http.cat/images/521.jpg";
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(error.toString())),
                        );
                      });
                    }
                  },
                  child: const Text("Créer un compte"),
                ),
              ),
            ],
          ),
        ));
  }
}
