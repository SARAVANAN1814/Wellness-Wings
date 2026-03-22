import 'package:flutter/material.dart';

class GuardianLoginPage extends StatelessWidget {
  const GuardianLoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Guardian Portal'),
        backgroundColor: Colors.indigo, // Visual distinction for Guardian
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.security, size: 80, color: Colors.indigo),
            const SizedBox(height: 16),
            const Text(
              'Guardian Authentication',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('Login and Registration functionality coming soon!'),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Go Back'),
            )
          ],
        ),
      ),
    );
  }
}
