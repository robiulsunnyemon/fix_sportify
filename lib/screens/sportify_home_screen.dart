import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:spotify_sdk/spotify_sdk.dart';
import 'package:get_storage/get_storage.dart';

class SpotifyHome extends StatefulWidget {
  const SpotifyHome({super.key});

  @override
  State<SpotifyHome> createState() => _SpotifyHomeState();
}

class _SpotifyHomeState extends State<SpotifyHome> {
  final String clientId = "af5d6ea6d1154b9793b39a14ea02fba4";
  final String redirectUri = "mumu://callback";
  final List<String> scopes = [
    'app-remote-control',
    'user-modify-playback-state',
    'user-read-playback-state',
    'user-read-currently-playing',
  ];

  final box = GetStorage();

  bool _connected = false;
  String _status = "Not Connected";
  String _currentTrack = "No track";

  @override
  void initState() {
    super.initState();
    _initSpotify();
  }

  Future<void> _initSpotify() async {
    setState(() => _status = "🔹 Connecting to Spotify...");
    try {
      // Step 1: Get Access Token (triggers user authentication)
      final token = await SpotifySdk.getAccessToken(
        clientId: clientId,
        redirectUrl: redirectUri,
        scope: scopes.join(' '),
      );
      print("token: $token");
      box.write('spotify_access_token', token);

      // Step 2: Connect to Spotify Remote using the granted access.
      final result = await SpotifySdk.connectToSpotifyRemote(
        clientId: clientId,
        redirectUrl: redirectUri,
      );

      setState(() {
        _connected = result;
        _status = result ? "✅ Connected to Spotify" : "❌ Connection failed";
      });

      // Step 3: Fetch current track
      await _getCurrentTrack();
    } on PlatformException catch (e) {
      if (e.code == "UserNotAuthorizedException") {
        setState(() => _status = "❌ Authorization required. Please reconnect.");
        print("Spotify init error: User needs to authorize the app.");
      } else {
        setState(() => _status = "❌ Error: ${e.message}");
        print("Spotify init error: $e");
      }
    } catch (e) {
      setState(() => _status = "❌ Unexpected Error: $e");
      print("Spotify init error: $e");
    }
  }

  Future<void> _getCurrentTrack() async {
    final token = box.read('spotify_access_token');
    if (token == null) {
      setState(() => _currentTrack = "Access token missing");
      return;
    }

    final url = Uri.parse("https://api.spotify.com/v1/me/player/currently-playing");
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data != null && data['item'] != null) {
        final track = data['item'];
        final name = track['name'];
        final artist = track['artists'][0]['name'];
        setState(() => _currentTrack = "$name by $artist");
      } else {
        setState(() => _currentTrack = "No track playing");
      }
    } else {
      setState(() => _currentTrack = "Failed to fetch track");
    }
  }

  Future<void> _play(String uri) async {
    try {
      await SpotifySdk.play(spotifyUri: uri);
      await _getCurrentTrack();
    } catch (e) {
      print("Play error: $e");
    }
  }

  Future<void> _pause() async {
    try {
      await SpotifySdk.pause();
    } catch (e) {
      print("Pause error: $e");
    }
  }

  Future<void> _reconnect() async {
    await _initSpotify();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Spotify Remote Control")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_status, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            Text("Current Track: $_currentTrack", textAlign: TextAlign.center),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => _play("spotify:track:6rqhFgbbKwnb9MLmUQDhG6"), // Example
              child: const Text("Play Track"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _pause,
              child: const Text("Pause Track"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _getCurrentTrack,
              child: const Text("Refresh Current Track"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _reconnect,
              child: const Text("Reconnect Spotify"),
            ),
          ],
        ),
      ),
    );
  }
}