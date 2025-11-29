import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/logger_service.dart';
import 'map_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, this.apiService});

  final ApiService? apiService;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  late final ApiService _apiService;

  @override
  void initState() {
    super.initState();
    _apiService = widget.apiService ?? ApiService();
  }

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isSignUp = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _authenticate() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    LoggerService.debug(
        'Starting authentication - isSignUp: $_isSignUp, email: $email',
        component: 'AuthScreen');

    // Email validation
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email address')),
      );
      return;
    }
    if (!emailRegex.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address')),
      );
      return;
    }

    // Password validation
    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your password')),
      );
      return;
    }
    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Password must be at least 6 characters long')),
      );
      return;
    }
    if (_isSignUp) {
      // Additional requirements for sign up
      if (!RegExp(r'[A-Z]').hasMatch(password)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Password must contain at least one uppercase letter')),
        );
        return;
      }
      if (!RegExp(r'[0-9]').hasMatch(password)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Password must contain at least one number')),
        );
        return;
      }
    }

    setState(() => _isLoading = true);
    try {
      LoggerService.debug('Calling API service...', component: 'AuthScreen');
      if (_isSignUp) {
        LoggerService.debug('Attempting sign up', component: 'AuthScreen');
        await _apiService.signUp(email, password);
      } else {
        LoggerService.debug('Attempting sign in', component: 'AuthScreen');
        await _apiService.signIn(email, password);
      }

      LoggerService.info('Authentication successful!', component: 'AuthScreen');
      // Navigate to MapScreen after successful authentication
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MapScreen()),
        );
      }
    } catch (e) {
      LoggerService.error('Authentication failed: $e', component: 'AuthScreen');
      // Display API error messages
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInAnonymously() async {
    setState(() => _isLoading = true);
    try {
      await _apiService.signInAnonymously();

      // Navigate to MapScreen after successful anonymous authentication
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MapScreen()),
        );
      }
    } catch (e) {
      // Display API error messages
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isSignUp ? 'Sign Up' : 'Sign In'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _authenticate,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : Text(_isSignUp ? 'Sign Up' : 'Sign In'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => setState(() => _isSignUp = !_isSignUp),
              child: Text(_isSignUp
                  ? 'Already have an account? Sign In'
                  : 'Don\'t have an account? Sign Up'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _isLoading ? null : _signInAnonymously,
              child: const Text('Continue as Guest'),
            ),
          ],
        ),
      ),
    );
  }
}
