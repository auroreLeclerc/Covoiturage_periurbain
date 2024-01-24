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
  late String mail;
  late String password;
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
                        "password": password
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
                              const SnackBar(
                                  content: Text("Compte créé avec succès.")));
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
