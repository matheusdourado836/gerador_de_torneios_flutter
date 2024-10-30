import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
            ElevatedButton.icon(onPressed: () => GoRouter.of(context).go('/tournament'), label: const Text('Iniciar torneio'), icon: const Icon(Icons.sports_volleyball),),
            const SizedBox(height: 24),
            ElevatedButton.icon(onPressed: () => GoRouter.of(context).go('/players'), label: const Text('Jogadores'), icon: const Icon(Icons.group),),
            const SizedBox(height: 24),
            ElevatedButton.icon(onPressed: () => GoRouter.of(context).go('/history'), label: const Text('Histórico'), icon: const Icon(Icons.history),),
          ],
        ),
      )
    );
  }
}
