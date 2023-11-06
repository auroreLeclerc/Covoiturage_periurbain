import "dart:convert";

import "package:email_validator/email_validator.dart";
import "package:flutter/material.dart";

class MyCustomForm extends StatefulWidget {
  const MyCustomForm({super.key});
  @override
  MyCustomFormState createState() {
    return MyCustomFormState();
  }
}

class MyCustomFormState extends State<MyCustomForm> {
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
  late String surname;
  late String password;
  late String? role = list.first.value;
  late String town;

  @override
  Widget build(BuildContext context) {
    // Build a Form widget using the _formKey created above.
    return Scaffold(
        appBar: AppBar(
          title: const Text("Server"),
        ),
        body: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.network("https://http.cat/images/100.jpg"),
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
                  initialValue: "Aurore"),
              TextFormField(
                  validator: (String? value) => value == null || value.isEmpty
                      ? "Veuillez renseigner ce champ."
                      : null,
                  decoration: const InputDecoration(icon: Icon(Icons.person)),
                  onSaved: (String? value) => surname = value!,
                  initialValue: "Leclerc"),
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
                        "surname": surname,
                        "password": password,
                        "role": role.toString(),
                        "town": town
                      };
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(jsonEncode(toSend))),
                      );
                    }
                  },
                  child: const Text("Envoyer"),
                ),
              ),
            ],
          ),
        ));
  }
}
