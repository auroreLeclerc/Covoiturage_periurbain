import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

Future<void> logout() async {
  await FacebookAuth.instance.logOut();
}
