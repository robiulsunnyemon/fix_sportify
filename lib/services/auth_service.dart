import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:http/http.dart' as http;
import 'package:spotify_sdk/spotify_sdk.dart';


class AuthService {

  static const String clientId = 'af5d6ea6d1154b9793b39a14ea02fba4';

  static const String clientSecret = '2db2dc5d299e4d02afd12840c1a7af13';

  static const String redirectUrl = 'mumu://callback';

  static const String scope =
      'user-read-private user-read-email user-read-playback-state user-modify-playback-state user-read-currently-playing streaming app-remote-control user-top-read';

  static final String authorizationEndpoint = 'https://accounts.spotify.com/authorize';
  static final String tokenEndpoint = 'https://accounts.spotify.com/api/token';

  String generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    final result = List.generate(length, (index) => chars[random.nextInt(chars.length)]).join();
    print('🔹 Generated random state: $result');
    return result;
  }

  Future<String> authenticate() async {
    try {
      late String userToken;
      final state = generateRandomString(16);
      final url = Uri.parse('$authorizationEndpoint?response_type=code&client_id=$clientId&scope=${Uri.encodeComponent(scope)}&redirect_uri=${Uri.encodeComponent(redirectUrl)}&state=$state');

      print('🔹 Opening Spotify auth URL: $url');
      print("start");
      final result = await FlutterWebAuth2.authenticate(
        url: url.toString(),
        callbackUrlScheme: 'mumu',
      );

      print("end");

      print('🔹 Auth result received: $result');

      final code = Uri.parse(result).queryParameters['code'];
      final returnedState = Uri.parse(result).queryParameters['state'];

      print('🔹 Received code: $code');
      print('🔹 Returned state: $returnedState');

      if (returnedState != state) {
        print('⚠️ State mismatch!');
        throw Exception('State mismatch');
      }

      if (code != null) {
        final token = await getToken(code);
        print('🔹 Token fetched: $token');
        userToken=token??'';
      }
      return userToken;
    } catch (e) {
      print('⚠️ Authentication error: $e');
      return '';
    }
  }

  Future<String?> getToken(String code) async {
    print('🔹 Requesting token with code: $code');
    final response = await http.post(
      Uri.parse(tokenEndpoint),
      headers: {
        'Authorization': 'Basic ${base64Encode(utf8.encode('$clientId:$clientSecret'))}',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'grant_type': 'authorization_code',
        'code': code,
        'redirect_uri': redirectUrl,
      },
    );

    print('🔹 Token response status: ${response.statusCode}');
    print('🔹 Token response body: ${response.body}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      // final prefs = await SharedPreferences.getInstance();
      // await prefs.setString('spotify_token', data['access_token']);
      // await prefs.setString('spotify_refresh_token', data['refresh_token']);
      // print('🔹 Tokens saved to SharedPreferences');
      return data['access_token'];
    } else {
      print('❌ Token request failed: ${response.statusCode}');
      return null;
    }
  }


  Future<void> connectToSpotify() async {
    try {
      var result = await SpotifySdk.connectToSpotifyRemote(
        clientId: clientId,
        redirectUrl: redirectUrl,
        scope: 'streaming,user-read-currently-playing,user-read-playback-state,user-modify-playback-state',
      );
      print('Connection successful: $result');
    } on PlatformException catch (e) {
      print('Connection failed: ${e.code}: ${e.message}');
    } on MissingPluginException {
      print('Missing Plugin Exception');
    }
  }


  Future<void> playTrack() async {
    try {
      await SpotifySdk.play(
        spotifyUri: 'spotify:track:1cM3P9b45w78c35b5E0h8', // এখানে আপনার পছন্দের গানের URI দিন
      );
      print('Playing song...');
    } on PlatformException catch (e) {
      print('Failed to play song: ${e.code}: ${e.message}');
    }
  }





  // Future<String?> refreshToken() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final refreshToken = prefs.getString('spotify_refresh_token');
  //   if (refreshToken == null) {
  //     print('⚠️ No refresh token found');
  //     return null;
  //   }
  //
  //   print('🔹 Refreshing token using refresh_token');
  //   final response = await http.post(
  //     Uri.parse(tokenEndpoint),
  //     headers: {
  //       'Authorization': 'Basic ${base64Encode(utf8.encode('$clientId:$clientSecret'))}',
  //       'Content-Type': 'application/x-www-form-urlencoded',
  //     },
  //     body: {
  //       'grant_type': 'refresh_token',
  //       'refresh_token': refreshToken,
  //     },
  //   );
  //
  //   print('🔹 Refresh token response status: ${response.statusCode}');
  //   print('🔹 Refresh token response body: ${response.body}');
  //
  //   if (response.statusCode == 200) {
  //     final data = json.decode(response.body);
  //     await prefs.setString('spotify_token', data['access_token']);
  //     print('🔹 Token refreshed and saved');
  //     return data['access_token'];
  //   } else {
  //     print('❌ Refresh token failed: ${response.statusCode}');
  //     return null;
  //   }
  // }
  //
  // Future<String?> getSavedToken() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final token = prefs.getString('spotify_token');
  //   print('🔹 Retrieved saved token: $token');
  //   return token;
  // }
  //
  // Future<void> logout() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   await prefs.remove('spotify_token');
  //   await prefs.remove('spotify_refresh_token');
  //   print('🔹 Logged out, tokens removed from SharedPreferences');
  // }
}