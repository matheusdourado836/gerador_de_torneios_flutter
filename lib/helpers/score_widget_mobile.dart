import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:volleyball_tournament_app/model/partida.dart';

class ScoreWidgetMobile extends StatefulWidget {
  final Partida? partida;
  const ScoreWidgetMobile({super.key, this.partida});

  @override
  State<ScoreWidgetMobile> createState() => _ScoreWidgetMobileState();
}

class _ScoreWidgetMobileState extends State<ScoreWidgetMobile> with TickerProviderStateMixin {
  AnimationController? _controllerA;
  AnimationController? _controllerB;
  int _teamA = 0;
  int _teamB = 0;
  final List<String> _points = [''];
  bool _reversed = false;

  void _startARotation() => _controllerA?.forward(from: 0);
  void _startBRotation() => _controllerB?.forward(from: 0);

  void setMatchPoints() {
    if (widget.partida != null) {
      widget.partida!.pontos = '$_teamA X $_teamB';
    }
  }

  @override
  void initState() {
    if (widget.partida != null) {
      final parts = widget.partida?.pontos?.split(' X ');
      if (parts != null && parts.length == 2) {
        _teamA = int.tryParse(parts[0]) ?? 0;
        _teamB = int.tryParse(parts[1]) ?? 0;
      }
    }
    _controllerA = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    _controllerB = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    super.initState();
  }

  @override
  void dispose() {
    _controllerA?.dispose();
    _controllerB?.dispose();
    super.dispose();
  }

  Widget buildScoreColumn({
    required String label,
    required int score,
    required VoidCallback onAdd,
    required VoidCallback onUndo,
    required AnimationController controller,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: controller,
          builder: (_, child) {
            return Transform.rotate(
              angle: controller.value * 2 * 3.1416 * 3,
              child: child,
            );
          },
          child: GestureDetector(
            onTap: onAdd,
            child: Container(
              padding: const EdgeInsets.all(8),
              alignment: Alignment.center,
              child: Text(
                score.toString(),
                style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 140,
          child: ElevatedButton(
            onPressed: onUndo,
            child: const Text('Cancelar ponto', textAlign: TextAlign.center),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pontuação'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (!_reversed)
              buildScoreColumn(
                label: 'Time A',
                score: _teamA,
                onAdd: () {
                  if (_points.last == 'teamB') _startARotation();
                  _points.add('teamA');
                  setState(() => _teamA++);
                  setMatchPoints();
                },
                onUndo: () {
                  if (_teamA > 0) {
                    setState(() {
                      _teamA--;
                      _points.removeLast();
                    });
                    setMatchPoints();
                  }
                },
                controller: _controllerA!,
              ),
            if (!_reversed) const SizedBox(height: 16),
            Text('X', style: TextStyle(fontSize: width < 350 ? 24 : 32)),
            const SizedBox(height: 16),
            if (_reversed)
              buildScoreColumn(
                label: 'Time A',
                score: _teamA,
                onAdd: () {
                  if (_points.last == 'teamB') _startARotation();
                  _points.add('teamA');
                  setState(() => _teamA++);
                  setMatchPoints();
                },
                onUndo: () {
                  if (_teamA > 0) {
                    setState(() {
                      _teamA--;
                      _points.removeLast();
                    });
                    setMatchPoints();
                  }
                },
                controller: _controllerA!,
              ),
            if (_reversed) const SizedBox(height: 16),
            buildScoreColumn(
              label: 'Time B',
              score: _teamB,
              onAdd: () {
                if (_points.last == 'teamA') _startBRotation();
                _points.add('teamB');
                setState(() => _teamB++);
                setMatchPoints();
              },
              onUndo: () {
                if (_teamB > 0) {
                  setState(() {
                    _teamB--;
                    _points.removeLast();
                  });
                  setMatchPoints();
                }
              },
              controller: _controllerB!,
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => setState(() => _reversed = !_reversed),
                icon: const Icon(Icons.swap_vert),
                label: const Text('Trocar Lados'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.check),
                label: const Text('Finalizar Partida'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}