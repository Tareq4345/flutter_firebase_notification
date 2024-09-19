import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;
import 'package:jose/jose.dart';

class Service {
  Future<String> getAccessToken() async {
    final jsonCredentials = await rootBundle.loadString('data/key_data.json');

    final cred = auth.ServiceAccountCredentials.fromJson(jsonCredentials);

    final jwtToken = _createJwtToken(cred);

    var uri = Uri.parse('https://oauth2.googleapis.com/token');

    final responseData = await http.post(uri, headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
    }, body: {
      'grant_type': 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      'assertion': jwtToken
    });

    final responseBody = jsonDecode(responseData.body);
    if (responseData.statusCode == 200) {
      return responseBody['access_token'];
    } else {
      throw Exception('Failed to obtain access token');
    }
  }

  Future<void> sendNotificaton(
      String accessToken, String userToken, String title, String body) async {
    Map<String, dynamic> notificationPayload = {
      "message": {
        "token": userToken,
        "notification": {
          "title": title,
          "body": body,
        },
      }
    };

    const senderId = '482745827376';

    var url = Uri.parse(
        'https://fcm.googleapis.com/v1/projects/$senderId/messages:send');

    final response = await http.post(url,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(notificationPayload));

    debugPrint('Notification response body: ${response.body}');
    if (response.statusCode == 200) {
      debugPrint('Notification sent successfully!');
    } else {
      debugPrint('Error sending notification. Status: ${response.statusCode}');
    }
  }

  String _createJwtToken(auth.ServiceAccountCredentials creds) {
    final jwtHeader = {
      'alg': 'RS256',
      'typ': 'JWT',
    };

    final jwtClaims = {
      'iss': creds.email,
      'scope': 'https://www.googleapis.com/auth/cloud-platform',
      'aud': 'https://oauth2.googleapis.com/token',
      'exp': (DateTime.now().millisecondsSinceEpoch ~/ 1000) + 3600,
      'iat': (DateTime.now().millisecondsSinceEpoch ~/ 1000),
    };

    final String encodedHeader =
        base64Url.encode(utf8.encode(json.encode(jwtHeader)));
    final String encodedClaims =
        base64Url.encode(utf8.encode(json.encode(jwtClaims)));

    // ignore: unused_local_variable
    final String unsignedToken = '$encodedHeader.$encodedClaims';

    final privateKey = JsonWebKey.fromPem(creds.privateKey);

    final signer = JsonWebSignatureBuilder()
      ..jsonContent = jwtClaims
      ..addRecipient(privateKey, algorithm: 'RS256');

    final signedToken = signer.build().toCompactSerialization();

    return signedToken;
  }
}
