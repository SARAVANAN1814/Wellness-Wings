import 'package:flutter/material.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  _AdminLoginPageState createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  void _login() {
    if (_formKey.currentState!.validate()) {
      if (_usernameController.text == 'admin' && _passwordController.text == 'admin123') {
        Navigator.pushReplacementNamed(context, '/admin_dashboard');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid credentials'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Console', style: TextStyle(color: Colors.white)), backgroundColor: Colors.indigo.shade900),
      body: Container(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Icon(Icons.admin_panel_settings, size: 80, color: Colors.indigo.shade900),
                   const SizedBox(height: 20),
                   const Text('Super Admin Login', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                   const SizedBox(height: 40),
                   TextFormField(
                     controller: _usernameController,
                     decoration: const InputDecoration(labelText: 'Username', prefixIcon: Icon(Icons.person), border: OutlineInputBorder()),
                     validator: (value) => value!.isEmpty ? 'Required' : null,
                   ),
                   const SizedBox(height: 16),
                   TextFormField(
                     controller: _passwordController,
                     obscureText: _obscurePassword,
                     decoration: InputDecoration(
                       labelText: 'Password', 
                       prefixIcon: const Icon(Icons.lock), 
                       border: const OutlineInputBorder(),
                       suffixIcon: IconButton(
                         icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                         onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                       ),
                     ),
                     validator: (value) => value!.isEmpty ? 'Required' : null,
                   ),
                   const SizedBox(height: 32),
                   ElevatedButton(
                     onPressed: _login,
                     style: ElevatedButton.styleFrom(
                       backgroundColor: Colors.indigo.shade900,
                       minimumSize: const Size(double.infinity, 50),
                     ),
                     child: const Text('Access Dashboard', style: TextStyle(fontSize: 16, color: Colors.white)),
                   ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
