import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  final String token;
  const HomeScreen({super.key, required this.token});
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService authService = AuthService();
  List<dynamic> tracks = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchTopTracks();
  }

  Future<void> fetchTopTracks() async {
    setState(() => isLoading = true);


    final url = Uri.parse('https://api.spotify.com/v1/me/top/tracks');
    print('🔹 Making GET request to: $url');

    final response = await http.get(url, headers: {'Authorization': 'Bearer ${widget
        .token}'});
    print('🔹 Response status: ${response.statusCode}');
    print('🔹 Response body: ${response.body}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        tracks = data['items'];
        isLoading = false;
      });
      print(data);
      print('🔹 Tracks fetched: ${tracks.length}');
    } else if (response.statusCode == 401) {
      print('⚠️ Token expired, refreshing...');
    } else {
      print('❌ Error fetching tracks: ${response.statusCode}');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Spotify Top Tracks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              print('🔹 Logging out...');
              setState(() => tracks = []);
              print('🔹 Logged out, cleared tracks');
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              print('🔹 Refresh button pressed');
              fetchTopTracks();
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : tracks.isEmpty
          ? Center(
        child: ElevatedButton(
            onPressed: () {
              print('🔹 Retry button pressed');
              fetchTopTracks();
            },
            child: const Text('Retry')),
      )
          : ListView.builder(
        itemCount: tracks.length,
        itemBuilder: (context, index) {
          final track = tracks[index];
          return ListTile(
            leading: Image.network(
              track['album']['images'][0]['url'],
              width: 50,
              height: 50,
              fit: BoxFit.cover,
            ),
            title: Text(track['name']),
            subtitle: Text(track['artists'][0]['name']),
          );
        },
      ),
    );
  }
}