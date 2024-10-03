import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:library_application/Pages/home.dart';
import 'package:library_application/Pages/welcome.dart';
import 'package:library_application/model/user.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  Future<dynamic> authenticateUser(String username, String password) async {
    try {
      final response = await http.get(Uri.parse(
          'http://192.168.1.5:3000/users?username=$username&password=$password'));
      if (response.statusCode == 200) {
        User user = User.fromJson(json.decode(response.body));

        if (user.username == username && user.password == password) {
          return user;
        } else {
          setState(() {
            _errorMessage = 'Invalid username or password';
          });
        }
      } else {
        setState(() {
          _errorMessage =
              "Failed to authenticate. Status Code: ${response.statusCode}";
        });
      }
    } catch (error) {
      setState(() {
        _errorMessage = "Error occurred while authenticating: $error";
      });
    }

    return false;
  }

  void _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      String username = _usernameController.text;
      String password = _passwordController.text;

      User user = await authenticateUser(username, password);
      if (user.role == 'admin') {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => DashboardScreen(
              userName: user.username,
              userId: user.userId,
            ),
          ),
        );
      } else if (user.role == 'user') {
        print("this is user not link to any page");
      } else {
        setState(() {
          _errorMessage = 'Invalid username or password';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred during login';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/background_library.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 60),
              decoration: const BoxDecoration(
                image: DecorationImage(
                    image: AssetImage('assets/images/Exclude2.png'),
                    fit: BoxFit.fill),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    spreadRadius: 5,
                  ),
                ],
              ),
              width: MediaQuery.of(context).size.width * 1,
              height: MediaQuery.of(context).size.height * 0.6,
              child: Stack(
                children: [
                  // Back arrow at the top-left corner of the login box
                  Positioned(
                    top: 0,
                    left: 0,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.brown),
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => const WelcomePage()));
                      },
                    ),
                  ),
                  // Title in the center at the top
                  const Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: EdgeInsets.only(top: 12.0),
                      child: Text(
                        'Login',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.brown,
                        ),
                      ),
                    ),
                  ),
                  // Login form below the title
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 60),
                      TextField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          labelText: 'Username',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (_errorMessage != null) ...[
                        Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 10),
                      ],
                      _isLoading
                          ? const CircularProgressIndicator()
                          : ElevatedButton(
                              onPressed: _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.brown[200],
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 40),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: const Text('Confirm'),
                            ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
