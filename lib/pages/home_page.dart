import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/logo.png', width: 250, height: 250,),
            const SizedBox(height: 40),
            ElevatedButton.icon(onPressed: () => Navigator.pushNamed(context, '/tournament'), label: const Text('Iniciar torneio'), icon: const Icon(Icons.sports_volleyball),),
            const SizedBox(height: 24),
            ElevatedButton.icon(onPressed: () => Navigator.pushNamed(context, '/players'), label: const Text('Jogadores'), icon: const Icon(Icons.group),),
            const SizedBox(height: 24),
            ElevatedButton.icon(onPressed: () => Navigator.pushNamed(context, '/history'), label: const Text('Histórico'), icon: const Icon(Icons.history),),
          ],
        ),
      )
    );
  }
}
