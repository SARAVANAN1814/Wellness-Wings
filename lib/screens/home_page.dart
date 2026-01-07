import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Widget _buildQuoteCard(String quote, String author) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              quote,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "- $author",
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.teal,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.healing, color: Colors.white),
            const SizedBox(width: 8),
            const Text('Wellness Wings'),
          ],
        ),
        backgroundColor: Colors.teal,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.teal, Colors.white],
            stops: [0.0, 0.4],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.favorite, color: Colors.white, size: 24),
                    const SizedBox(width: 8),
                    const Text(
                      'Wellness Wings',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  width: 80,
                  height: 2,
                  color: Colors.white,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Bridging Hearts, Building Support',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                            children: [
                              const Text(
                                'Our Mission',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.teal,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Connecting elderly and physically challenged individuals with compassionate volunteers to create a supportive community where dignity, independence, and well-being flourish.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: _buildQuoteCard(
                                  "The greatest happiness of life is the conviction that we are loved.",
                                  "Victor Hugo"
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildQuoteCard(
                                  "The best way to find yourself is to lose yourself in the service of others.",
                                  "Mahatma Gandhi"
                                ),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      icon: Icon(Icons.elderly, color: Colors.white),
                                      label: const Text(
                                        'Elderly Login',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.teal.shade800,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        elevation: 2,
                                      ),
                                      onPressed: () {
                                        Navigator.pushNamed(context, '/elderly_login');
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      icon: Icon(Icons.volunteer_activism, color: Colors.white),
                                      label: const Text(
                                        'Volunteer Login',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.teal.shade900,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        elevation: 2,
                                      ),
                                      onPressed: () {
                                        Navigator.pushNamed(context, '/volunteer_login');
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.lightbulb, size: 14, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'Join us in making a difference',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontStyle: FontStyle.italic,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}