library globals;

import 'package:flutter/cupertino.dart';

// Cette variable globale est utilisée pour stocker le jeton d'authentification
// de l'utilisateur dans l'ensemble de l'application.
String authToken = "";

// GlobalKey<NavigatorState> est utilisé pour maintenir une référence globale
// au Navigator de l'application. Cela permet d'interagir avec le
// Navigator depuis n'importe quel endroit de votre application sans avoir à
// passer explicitement le BuildContext.
GlobalKey<NavigatorState> navigatorKey = GlobalKey();
