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
  Timer? _nextRoundTimer;

  RoundState _state = RoundState.waiting;
  double _multiplier = 1.0;
  double _crashPoint = 2.0;
  double _balance = 29999.0;
  int _pendingCount = 0;
  final List<double> _history = [2.21, 6.63, 1.62, 5.91, 2.44, 1.25, 1.13, 3.93];

  @override
  void dispose() {
    _timer?.cancel();
    _nextRoundTimer?.cancel();
    super.dispose();
  }

  double _nextCrashPoint() {
    final r = _random.nextDouble();
    return (1.0 / (1.0 - r * 0.97)).clamp(1.0, 200.0);
  }

  void startRound() {
    _nextRoundTimer?.cancel();
    if (_state == RoundState.flying) return;
    setState(() {
      _multiplier = 1.0;
      _crashPoint = _nextCrashPoint();
      _state = RoundState.flying;
    });
    _timer = Timer.periodic(const Duration(milliseconds: 50), (_) => _tick());
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
        if (_pendingCount > 0) {
          _nextRoundTimer = Timer(const Duration(seconds: 2), () {
            if (_state == RoundState.crashed && _pendingCount > 0) startRound();
          });
        }
      }
    });
  }

  void _onPendingChanged(bool pending) {
    setState(() => _pendingCount += pending ? 1 : -1);
    if (_pendingCount == 0) _nextRoundTimer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final flying = _state == RoundState.flying;
    final crashed = _state == RoundState.crashed;
    final progress = ((log(_multiplier) / log(10)) * 1.6).clamp(0.0, 1.0);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
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
                              ? const Color(0xFFE91E63)
                              : (m >= 2
                                  ? const Color(0xFFAA4DEE)
                                  : const Color(0xFF2196F3))));
                },
              ),
            ),
            const SizedBox(height: 8),
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
                      painter: _BeamPainter(progress: progress),
                    ),
                    if (flying)
                      CustomPaint(
                        size: Size.infinite,
                        painter: _CurvePainter(progress: progress, crashed: false),
                      ),
                    if (flying)
                      Positioned.fill(
                        child: CustomPaint(
                            painter: _FlyingPlanePainter(progress: progress)),
                      ),
                    if (!flying && !crashed)
                      Positioned.fill(
                        child: CustomPaint(painter: _ParkedPlanePainter()),
                      ),
                    if (flying)
                      Center(
                        child: Text(
                          '${_multiplier.toStringAsFixed(2)}x',
                          style: const TextStyle(
                            fontSize: 56,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    if (crashed)
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('FLEW AWAY!',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 22)),
                            Text(
                              '${_multiplier.toStringAsFixed(2)}x',
                              style: const TextStyle(
                                fontSize: 56,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFFD8232A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    Positioned(
                      right: 12,
                      bottom: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                                radius: 10, backgroundColor: Colors.blueGrey),
                            SizedBox(width: 4),
                            CircleAvatar(
                                radius: 10, backgroundColor: Colors.teal),
                            SizedBox(width: 4),
                            CircleAvatar(
                                radius: 10, backgroundColor: Colors.brown),
                            SizedBox(width: 8),
                            Text('193', style: TextStyle(color: Colors.white)),
                          ],
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
            BetPanel(
              multiplier: _multiplier,
              state: _state,
              balance: _balance,
              onBet: (amt) => setState(() => _balance -= amt),
              onWin: (win) => setState(() => _balance += win),
              onBetPlaced: startRound,
              onPendingChanged: _onPendingChanged,
            ),
            const SizedBox(height: 8),
            BetPanel(
              multiplier: _multiplier,
              state: _state,
              balance: _balance,
              onBet: (amt) => setState(() => _balance -= amt),
              onWin: (win) => setState(() => _balance += win),
              onBetPlaced: startRound,
              onPendingChanged: _onPendingChanged,
              showCardIcon: true,
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
  final double balance;
  final void Function(double amt) onBet;
  final void Function(double win) onWin;
  final VoidCallback onBetPlaced;
  final ValueChanged<bool> onPendingChanged;
  final bool showCardIcon;

  const BetPanel({
    super.key,
    required this.multiplier,
    required this.state,
    required this.balance,
    required this.onBet,
    required this.onWin,
    required this.onBetPlaced,
    required this.onPendingChanged,
    this.showCardIcon = false,
  });

  @override
  State<BetPanel> createState() => _BetPanelState();
}

class _BetPanelState extends State<BetPanel> {
  double _amount = 1.0;
  double? _cashedAt;
  bool _pendingBet = false;
  bool _activeBet = false;
  bool _autoTab = false;

  @override
  void didUpdateWidget(BetPanel old) {
    super.didUpdateWidget(old);
    if (widget.state != old.state) {
      if (widget.state == RoundState.flying) {
        if (_pendingBet && !_activeBet) {
          _activeBet = true;
          widget.onBet(_amount); // deduct stake
        }
      } else {
        // waiting or crashed: round over / not started
        _activeBet = false;
        _cashedAt = null;
      }
    }
  }

  void _bet() {
    _pendingBet = true;
    widget.onPendingChanged(true);
    widget.onBetPlaced(); // starts round if not flying
    setState(() {});
  }

  void _cancel() {
    _pendingBet = false;
    widget.onPendingChanged(false);
    setState(() {});
  }

  void _cashOut() {
    if (widget.state != RoundState.flying || !_activeBet || _cashedAt != null) {
      return;
    }
    setState(() => _cashedAt = widget.multiplier);
    widget.onWin(_amount * widget.multiplier);
  }

  @override
  Widget build(BuildContext context) {
    final flying = widget.state == RoundState.flying;

    Widget action;
    if (_activeBet && flying) {
      if (_cashedAt == null) {
        action = ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE07B00),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: _cashOut,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Cash Out', style: TextStyle(fontSize: 22)),
              Text('${(_amount * widget.multiplier).toStringAsFixed(2)} USD'),
            ],
          ),
        );
      } else {
        action = ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: null,
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Cashed Out', style: TextStyle(fontSize: 22)),
            ],
          ),
        );
      }
    } else if (_pendingBet) {
      action = ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFB3122E),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: _cancel,
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Cancel', style: TextStyle(fontSize: 22)),
            Text('Waiting for next round', style: TextStyle(fontSize: 14)),
          ],
        ),
      );
    } else {
      action = ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2E9E1B),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: _activeBet ? null : _bet,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Bet', style: TextStyle(fontSize: 22)),
            Text('${_amount.toStringAsFixed(2)} USD'),
          ],
        ),
      );
    }

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
                Row(
                  children: [
                    Expanded(
                      child: Container(
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
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 6),
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
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 6),
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
                    ),
                    if (widget.showCardIcon)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF2A2F3A),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.all(6),
                          child: const Icon(Icons.credit_card,
                              color: Colors.white54, size: 18),
                        ),
                      ),
                  ],
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
            child: SizedBox(height: 90, child: action),
          ),
        ],
      ),
    );
  }
}

class _ParkedPlanePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final painter = TextPainter(
      text: const TextSpan(
          text: '✈',
          style: TextStyle(fontSize: 44, color: Color(0xFFE01E5A))),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, Offset(20, size.height - 70));
  }

  @override
  bool shouldRepaint(_) => false;
}

class _FlyingPlanePainter extends CustomPainter {
  final double progress;
  _FlyingPlanePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final end =
        Offset(size.width * progress, size.height * (1 - progress * 0.8));
    final painter = TextPainter(
      text: const TextSpan(
          text: '✈',
          style: TextStyle(fontSize: 44, color: Color(0xFFE01E5A))),
      textDirection: TextDirection.ltr,
    )..layout();
    final angle = atan2(-0.8 * progress * size.height,
        size.width * progress * 0.5 + 0.001);
    canvas.save();
    canvas.translate(end.dx, end.dy - 20);
    canvas.rotate(angle);
    painter.paint(canvas, const Offset(-22, -22));
    canvas.restore();
  }

  @override
  bool shouldRepaint(_FlyingPlanePainter old) => old.progress != progress;
}

class _BeamPainter extends CustomPainter {
  final double progress;
  _BeamPainter({this.progress = 0});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(0, size.height);
    final paint = Paint()..color = const Color(0xFF1C2330);
    for (var i = 0; i < 12; i++) {
      final a1 = -i * 0.13 - 0.05;
      final a2 = a1 - 0.06;
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(center.dx + size.width * 2 * cos(a1),
            center.dy + size.width * 2 * sin(a1))
        ..lineTo(center.dx + size.width * 2 * cos(a2),
            center.dy + size.width * 2 * sin(a2))
        ..close();
      canvas.drawPath(path, paint);
    }
    final glowColor = Color.lerp(
        const Color(0xFF1565C0), const Color(0xFF6A1B9A), progress)!;
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [glowColor.withValues(alpha: 0.35), Colors.transparent],
      ).createShader(Rect.fromCircle(
          center: Offset(size.width * 0.5, size.height * 0.35),
          radius: size.width));
    canvas.drawRect(Offset.zero & size, glow);
  }

  @override
  bool shouldRepaint(_BeamPainter old) => old.progress != progress;
}

class _CurvePainter extends CustomPainter {
  final double progress;
  final bool crashed;
  _CurvePainter({required this.progress, required this.crashed});

  @override
  void paint(Canvas canvas, Size size) {
    final start = Offset(0, size.height);
    final end = Offset(
        size.width * progress, size.height * (1 - progress * 0.8));

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
