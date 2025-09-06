import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'home_screen.dart';


class LoginScreen extends StatelessWidget {
  final AuthService authService = AuthService();

  LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.music_note,
                size: 80,
                color: Colors.white,
              ),
              SizedBox(height: 20),
              Text(
                'MusicChat',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'সঙ্গীত এবং চ্যাটের এক অভূতপূর্ব সমন্বয়',
                style: TextStyle(fontSize: 16, color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 40),
              ElevatedButton.icon(
                icon: Icon(Icons.music_note),
                label: Text('Spotify দিয়ে লগইন'),
                onPressed: () async {
                  try {
                    final token = await authService.authenticate();
                    if (token.trim().isNotEmpty) {
                      authService.connectToSpotify();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HomeScreen(token: token),
                        ),
                      );

                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('লগইন ব্যর্থ, আবার চেষ্টা করুন')),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('লগইন$e')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF1DB954),
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  textStyle: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}