import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const AviatorApp());
}

class AviatorApp extends StatelessWidget {
  const AviatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aviator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0B0E13),
      ),
      home: const AviatorPage(),
    );
  }
}

enum RoundState { waiting, flying, crashed }

class AviatorPage extends StatefulWidget {
  const AviatorPage({super.key});

  @override
  State<AviatorPage> createState() => _AviatorPageState();
}

class _AviatorPageState extends State<AviatorPage> {
  final _random = Random();
  Timer? _timer;

  RoundState _state = RoundState.waiting;
  double _multiplier = 1.0;
  double _crashPoint = 2.0;
  double _balance = 29999.0;
  final List<double> _history = [3.37, 4.18, 1.57, 1.23, 177.86, 1.85, 8.69, 1.40];

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  double _nextCrashPoint() {
    final r = _random.nextDouble();
    return (1.0 / (1.0 - r * 0.97)).clamp(1.0, 200.0);
  }

  void _tick() {
    setState(() {
      _multiplier += 0.01 + (_multiplier - 1.0) * 0.012;
      if (_multiplier >= _crashPoint) {
        _multiplier = _crashPoint;
        _state = RoundState.crashed;
        _timer?.cancel();
        _history.insert(0, _crashPoint);
        if (_history.length > 10) _history.removeLast();
      }
    });
  }

  void startRound() {
    if (_state == RoundState.flying) return;
    setState(() {
      _multiplier = 1.0;
      _crashPoint = _nextCrashPoint();
      _state = RoundState.flying;
    });
    _timer = Timer.periodic(const Duration(milliseconds: 50), (_) => _tick());
  }

  void _newRound() {
    setState(() {
      _state = RoundState.waiting;
      _multiplier = 1.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final flying = _state == RoundState.flying;
    final crashed = _state == RoundState.crashed;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top bar: logo + balance + menu
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  const Text('Aviator',
                      style: TextStyle(
                          color: Color(0xFFE01E5A),
                          fontSize: 28,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Text(_balance.toStringAsFixed(2),
                      style: const TextStyle(
                          color: Color(0xFF37B34A),
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  const Text(' USD',
                      style: TextStyle(color: Colors.white70, fontSize: 16)),
                  const SizedBox(width: 12),
                  const Icon(Icons.menu, color: Colors.white54),
                ],
              ),
            ),
            // History row
            SizedBox(
              height: 28,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _history.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (_, i) {
                  final m = _history[i];
                  return Text('${m.toStringAsFixed(2)}x',
                      style: TextStyle(
                          fontSize: 14,
                          color: m >= 10
                              ? const Color(0xFFAA4DEE)
                              : const Color(0xFF2196F3)));
                },
              ),
            ),
            const SizedBox(height: 8),
            // Game area
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: const Color(0xFF141821),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  children: [
                    CustomPaint(
                      size: Size.infinite,
                      painter: _BeamPainter(),
                    ),
                    CustomPaint(
                      size: Size.infinite,
                      painter: _CurvePainter(
                          progress: ((log(_multiplier) / log(10)) * 1.6).clamp(0.0, 1.0),
                          crashed: crashed),
                    ),
                    if (flying || crashed)
                      Builder(builder: (context) {
                        final progress = ((log(_multiplier) / log(10)) * 1.6).clamp(0.0, 1.0);
                        return Positioned.fill(
                          child: CustomPaint(
                            painter: _PlanePainter(progress: progress),
                          ),
                        );
                      }),
                    Center(
                      child: Text(
                        '${_multiplier.toStringAsFixed(2)}x',
                        style: TextStyle(
                          fontSize: 56,
                          fontWeight: FontWeight.w900,
                          color: crashed ? Colors.grey : Colors.white,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        decoration: const BoxDecoration(
                          color: Color(0xFFD98E04),
                          borderRadius: BorderRadius.vertical(
                              top: Radius.circular(12)),
                        ),
                        child: const Center(
                          child: Text('FUN MODE',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Two bet panels
            BetPanel(
              multiplier: _multiplier,
              state: _state,
              crashPoint: _crashPoint,
              balance: _balance,
              onBetResult: (amt, win) => setState(() => _balance += win - amt),
              onBetPlaced: startRound,
            ),
            const SizedBox(height: 8),
            BetPanel(
              multiplier: _multiplier,
              state: _state,
              crashPoint: _crashPoint,
              balance: _balance,
              onBetResult: (amt, win) => setState(() => _balance += win - amt),
              onBetPlaced: startRound,
            ),
            if (crashed)
              TextButton(
                onPressed: _newRound,
                child: const Text('TAP TO CONTINUE',
                    style: TextStyle(color: Colors.white70)),
              ),
          ],
        ),
      ),
    );
  }
}

class BetPanel extends StatefulWidget {
  final double multiplier;
  final RoundState state;
  final double crashPoint;
  final double balance;
  final void Function(double amount, double win) onBetResult;
  final VoidCallback onBetPlaced;

  const BetPanel({
    super.key,
    required this.multiplier,
    required this.state,
    required this.crashPoint,
    required this.balance,
    required this.onBetResult,
    required this.onBetPlaced,
  });

  @override
  State<BetPanel> createState() => _BetPanelState();
}

class _BetPanelState extends State<BetPanel> {
  double _amount = 1.0;
  double? _cashedAt;
  bool _betPlaced = false;
  bool _autoTab = false;
  bool _resolved = false;


  @override
  void didUpdateWidget(BetPanel old) {
    super.didUpdateWidget(old);
    if (widget.state == RoundState.flying && _betPlaced && _cashedAt == null) {
      // still flying
    }
    if (widget.state == RoundState.crashed && _betPlaced && !_resolved) {
      _resolved = true;
      // stake was already deducted at bet time; winnings were credited at cashout
      _betPlaced = false;
      _cashedAt = null;
    }
    if (widget.state == RoundState.waiting && _resolved) {
      _resolved = false;
    }
  }

  void _bet() {
    if (widget.state == RoundState.flying) return;
    setState(() {
      _betPlaced = true;
      _cashedAt = null;
      _resolved = false;
    });
    widget.onBetResult(_amount, 0); // deduct stake; winnings credited at cashout
    widget.onBetPlaced();
  }

  void _cashOut() {
    if (widget.state != RoundState.flying || !_betPlaced || _cashedAt != null) {
      return;
    }
    setState(() => _cashedAt = widget.multiplier);
    widget.onBetResult(0, _amount * widget.multiplier);
  }

  @override
  Widget build(BuildContext context) {
    final flying = widget.state == RoundState.flying;
    final active = _betPlaced && flying;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F29),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2F3A),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _autoTab = false),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Text('Bet',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: !_autoTab
                                        ? Colors.white
                                        : Colors.white38)),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _autoTab = true),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Text('Auto',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: _autoTab
                                        ? Colors.white
                                        : Colors.white38)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline,
                          color: Colors.white70),
                      onPressed: () =>
                          setState(() => _amount = max(1, _amount - 1)),
                    ),
                    Text(_amount.toStringAsFixed(2),
                        style: const TextStyle(fontSize: 18)),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline,
                          color: Colors.white70),
                      onPressed: () => setState(() => _amount += 1),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [1, 2, 5, 10]
                      .map((v) => GestureDetector(
                            onTap: () => setState(() => _amount = v.toDouble()),
                            child: Text('$v',
                                style: const TextStyle(color: Colors.white38)),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SizedBox(
              height: 90,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: active
                      ? (_cashedAt != null
                          ? Colors.grey
                          : const Color(0xFFE07B00))
                      : const Color(0xFF2E9E1B),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: active
                    ? (_cashedAt != null ? null : _cashOut)
                    : (flying ? null : _bet),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      active
                          ? (_cashedAt != null ? 'Cashed Out' : 'Cash Out')
                          : 'Bet',
                      style: const TextStyle(fontSize: 22),
                    ),
                    Text(
                      active && _cashedAt == null
                          ? '${(_amount * widget.multiplier).toStringAsFixed(2)} USD'
                          : '${_amount.toStringAsFixed(2)} USD',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanePainter extends CustomPainter {
  final double progress;
  _PlanePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final end = Offset(size.width * progress, size.height * (1 - progress * 0.8));
    final painter = TextPainter(
      text: const TextSpan(
          text: '✈',
          style: TextStyle(fontSize: 44, color: Color(0xFFE01E5A))),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, end.translate(-18, -40));
  }

  @override
  bool shouldRepaint(_PlanePainter old) => old.progress != progress;
}

class _BeamPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(0, size.height);
    final paint = Paint()..color = const Color(0xFF1C2330);
    for (var i = 0; i < 12; i++) {
      final a1 = -i * 0.13 - 0.05;
      final a2 = a1 - 0.06;
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(center.dx + size.width * 2 * cos(a1), center.dy + size.width * 2 * sin(a1))
        ..lineTo(center.dx + size.width * 2 * cos(a2), center.dy + size.width * 2 * sin(a2))
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

class _CurvePainter extends CustomPainter {
  final double progress;
  final bool crashed;
  _CurvePainter({required this.progress, required this.crashed});

  @override
  void paint(Canvas canvas, Size size) {
    final start = Offset(0, size.height);
    final end = Offset(size.width * progress, size.height * (1 - progress * 0.8));

    final curve = Path()
      ..moveTo(start.dx, start.dy)
      ..quadraticBezierTo(
          size.width * progress * 0.5, size.height, end.dx, end.dy);

    final fill = Path.from(curve)
      ..lineTo(end.dx, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          (crashed ? Colors.purple : Colors.red).withValues(alpha: 0.35),
          (crashed ? Colors.purple : Colors.red).withValues(alpha: 0.05),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(fill, fillPaint);

    final stroke = Paint()
      ..color = crashed ? Colors.purpleAccent : const Color(0xFFFF1744)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawPath(curve, stroke);
  }

  @override
  bool shouldRepaint(_CurvePainter old) =>
      old.progress != progress || old.crashed != crashed;
}
