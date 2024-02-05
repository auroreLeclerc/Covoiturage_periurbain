import "dart:convert";

import "package:covoiturage_periurbain/user_data.dart";
import "package:flutter/material.dart";
import 'package:http/http.dart' as http;

class AccountUpdate extends StatefulWidget {
  final UserData userData;
  const AccountUpdate({super.key, required this.userData});
  @override
  AccountUpdateState createState() {
    return AccountUpdateState();
  }
}

class AccountUpdateState extends State<AccountUpdate> {
  final _formKey = GlobalKey<FormState>();
  final list = <DropdownMenuItem<String>>[
    const DropdownMenuItem(value: "passenger", child: Text("Passager")),
    const DropdownMenuItem(value: "driver", child: Text("Conducteur")),
  ];

  late String? name;
  late String? role = list.first.value; // Défaut à 'passenger'
  late String? town = "";
  late String? phone = "";
  late String numberplate = "";
  late String mac = "";
  // late String catUrl = "https://http.cat/images/100.jpg";

  @override
  void initState() {
    super.initState();
    name = widget.userData.name ?? "";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Initialiser mon compte"),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Image.network(catUrl, height: 200),
              TextFormField(
                decoration: const InputDecoration(icon: Icon(Icons.person)),
                onSaved: (String? value) => name = value,
                initialValue: name,
              ),
              DropdownButtonFormField<String>(
                value: role,
                icon: const Icon(Icons.drive_eta),
                onChanged: (String? value) => setState(() => role = value),
                items: list,
                onSaved: (String? value) => role = value,
              ),
              TextFormField(
                  decoration:
                      const InputDecoration(icon: Icon(Icons.location_city)),
                  onSaved: (String? value) => town = value!,
                  initialValue: "Albert"),
              TextFormField(
                  decoration: const InputDecoration(icon: Icon(Icons.phone)),
                  onSaved: (String? value) => phone = value!,
                  initialValue: "0666666666"),
              Visibility(
                visible: role == list[1].value,
                child: Column(children: [
                  TextFormField(
                      validator: (String? value) =>
                          value == null || value.isEmpty
                              ? "Veuillez renseigner ce champ."
                              : null,
                      decoration: const InputDecoration(
                          icon: Icon(Icons.sort_by_alpha)),
                      onSaved: (String? value) => numberplate = value!,
                      initialValue: "AA-111-AA"),
                  TextFormField(
                      validator: (String? value) =>
                          value == null || value.isEmpty
                              ? "Veuillez renseigner ce champ."
                              : null,
                      decoration: const InputDecoration(
                          icon: Icon(Icons.developer_mode)),
                      onSaved: (String? value) => mac = value!,
                      initialValue: "ff:ff:ff:ff:ff:ff")
                ]),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();

                      final Map<String, String> toSend = {
                        "role": role.toString(),
                        "name": name.toString(),
                        "town": town.toString(),
                        "phone": phone.toString()
                      };

                      if (role == list[1].value) {
                        toSend.addAll({'numberplate': numberplate, 'mac': mac});
                      }

                      http
                          .patch(
                        Uri.parse('http://10.42.0.1:4443/account'),
                        headers: <String, String>{
                          'Content-Type': 'application/json; charset=UTF-8',
                          'Authorization': widget.userData.token
                        },
                        body: jsonEncode(toSend),
                      )
                          .then((response) {
                        // setState(() {
                        //   // catUrl = "https://http.cat/images/${response.statusCode}.jpg";
                        // });
                        if (response.statusCode == 201) {
                          Navigator.pop(context);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(response.body)));
                        }
                      }).catchError((error) {
                        // setState(() {
                        //   // catUrl = "https://http.cat/images/521.jpg";
                        // });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(error.toString())),
                        );
                      });
                    }
                  },
                  child: const Text("Initialiser mon compte"),
                ),
              ),
            ],
          ),
        ));
  }
}
