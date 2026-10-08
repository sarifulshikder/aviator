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
  Timer? _phaseTimer;
  Timer? _waitTimer;

  RoundState _state = RoundState.waiting;
  double _multiplier = 1.0;
  double _crashPoint = 2.0;
  double _balance = 0.0;
  double _waitProgress = 1.0;
  int _pendingCount = 0;
  int _totalBets = 0;
  double _totalWin = 0.0;
  final List<double> _history = [5.34, 1.20, 1.24, 4.16, 1.06, 1.04, 2.57, 2.49];

  @override
  void initState() {
    super.initState();
    _startWaitPhase();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _phaseTimer?.cancel();
    _waitTimer?.cancel();
    super.dispose();
  }

  double _nextCrashPoint() {
    final r = _random.nextDouble();
    return (1.0 / (1.0 - r * 0.97)).clamp(1.0, 200.0);
  }

  void _startWaitPhase() {
    setState(() {
      _state = RoundState.waiting;
      _multiplier = 1.0;
      _waitProgress = 1.0;
    });
    _waitTimer = Timer.periodic(const Duration(milliseconds: 50), (t) {
      setState(() {
        _waitProgress -= 1 / 60; // 3s countdown
        if (_waitProgress <= 0) {
          _waitProgress = 0;
          t.cancel();
          _startFlyPhase();
        }
      });
    });
  }

  void _startFlyPhase() {
    setState(() {
      _multiplier = 1.0;
      _crashPoint = _nextCrashPoint();
      _state = RoundState.flying;
    });
    _timer = Timer.periodic(const Duration(milliseconds: 50), (_) => _tick());
  }

  void startRound() {
    // called by panels to try to start immediately; if a phase timer is
    // running, cancel it and start now
    _phaseTimer?.cancel();
    _waitTimer?.cancel();
    if (_state != RoundState.flying) {
      _startFlyPhase();
    }
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
        _phaseTimer = Timer(const Duration(milliseconds: 2500), _startWaitPhase);
      }
    });
  }

  void _onPendingChanged(bool pending) {
    setState(() => _pendingCount += pending ? 1 : -1);
  }

  @override
  Widget build(BuildContext context) {
    final flying = _state == RoundState.flying;
    final crashed = _state == RoundState.crashed;
    final waiting = _state == RoundState.waiting;
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
                          fontSize: 26,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Text(
                      '${DateTime.now().hour.toString().padLeft(2, '0')}:'
                      '${DateTime.now().minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(color: Colors.white70)),
                  const Spacer(),
                  Text(_balance.toStringAsFixed(0),
                      style: const TextStyle(
                          color: Color(0xFF37B34A),
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  const Text(' BDT',
                      style: TextStyle(color: Colors.white70, fontSize: 16)),
                  const SizedBox(width: 12),
                  const Icon(Icons.menu, color: Colors.white54),
                ],
              ),
            ),
            SizedBox(
              height: 28,
              child: Row(
                children: [
                  Expanded(
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: _history.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 12),
                      itemBuilder: (_, i) {
                        final m = _history[i];
                        return Text(m.toStringAsFixed(2),
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
                  const Icon(Icons.keyboard_arrow_down,
                      color: Colors.white54, size: 18),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: const Color(0xFF0E1B2A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  children: [
                    const CustomPaint(
                      size: Size.infinite,
                      painter: _StarPainter(),
                    ),
                    if (flying)
                      CustomPaint(
                        size: Size.infinite,
                        painter: _CurvePainter(progress: progress),
                      ),
                    if (flying)
                      Positioned.fill(
                        child: CustomPaint(
                            painter: _FlyingPlanePainter(progress: progress)),
                      ),
                    if (waiting)
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CustomPaint(
                              size: const Size(260, 120),
                              painter: _FrontPlanePainter(),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              width: 260,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A2433),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.white12),
                              ),
                              child: Column(
                                children: [
                                  const Text('WAITING FOR THE NEXT ROUND',
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 13)),
                                  const SizedBox(height: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: _waitProgress,
                                      minHeight: 6,
                                      backgroundColor: Colors.white12,
                                      color: const Color(0xFFD8232A),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: const [
                                      Text('Original Gambling Brand',
                                          style: TextStyle(
                                              color: Colors.white54,
                                              fontSize: 12)),
                                      SizedBox(width: 8),
                                      Text('SINCE 2017',
                                          style: TextStyle(
                                              color: Color(0xFFD8232A),
                                              fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
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
                            Text('138', style: TextStyle(color: Colors.white)),
                          ],
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
              onBet: (amt) => setState(() {
                _balance -= amt;
                _totalBets++;
              }),
              onWin: (win) => setState(() {
                _balance += win;
                _totalWin += win;
              }),
              onBetPlaced: startRound,
              onPendingChanged: _onPendingChanged,
            ),
            const SizedBox(height: 8),
            BetPanel(
              multiplier: _multiplier,
              state: _state,
              onBet: (amt) => setState(() {
                _balance -= amt;
                _totalBets++;
              }),
              onWin: (win) => setState(() {
                _balance += win;
                _totalWin += win;
              }),
              onBetPlaced: startRound,
              onPendingChanged: _onPendingChanged,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Bets',
                          style: TextStyle(
                              color: Colors.white54, fontSize: 12)),
                      Text('$_totalBets/${_totalBets + 5}',
                          style: const TextStyle(color: Colors.white)),
                    ],
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Total Win BDT',
                          style: TextStyle(
                              color: Colors.white54, fontSize: 12)),
                      Text(_totalWin.toStringAsFixed(2),
                          style: const TextStyle(color: Colors.white)),
                    ],
                  ),
                ],
              ),
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
  final void Function(double amt) onBet;
  final void Function(double win) onWin;
  final VoidCallback onBetPlaced;
  final ValueChanged<bool> onPendingChanged;

  const BetPanel({
    super.key,
    required this.multiplier,
    required this.state,
    required this.onBet,
    required this.onWin,
    required this.onBetPlaced,
    required this.onPendingChanged,
  });

  @override
  State<BetPanel> createState() => _BetPanelState();
}

class _BetPanelState extends State<BetPanel> {
  double _amount = 15.0;
  double? _cashedAt;
  bool _pendingBet = false;
  bool _activeBet = false;

  @override
  void didUpdateWidget(BetPanel old) {
    super.didUpdateWidget(old);
    if (widget.state != old.state) {
      if (widget.state == RoundState.flying) {
        if (_pendingBet && !_activeBet) {
          _activeBet = true;
          widget.onBet(_amount);
        }
      } else {
        _activeBet = false;
        _cashedAt = null;
      }
    }
  }

  void _bet() {
    _pendingBet = true;
    widget.onPendingChanged(true);
    widget.onBetPlaced();
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
    if (_activeBet && flying && _cashedAt == null) {
      action = ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE07B00),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: _cashOut,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Cash Out', style: TextStyle(fontSize: 22)),
            Text('${(_amount * widget.multiplier).toStringAsFixed(2)} BDT'),
          ],
        ),
      );
    } else if (_activeBet && flying) {
      action = ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: null,
        child: const Text('Cashed Out', style: TextStyle(fontSize: 22)),
      );
    } else if (_pendingBet) {
      action = ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFD8232A),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: _cancel,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Waiting', style: TextStyle(fontSize: 16)),
            Text('${_amount.toStringAsFixed(2)} BDT',
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    } else {
      action = ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2E9E1B),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: _bet,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('BET', style: TextStyle(fontSize: 16)),
            Text('${_amount.toStringAsFixed(2)} BDT',
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold)),
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
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline,
                              color: Colors.white70),
                          onPressed: () =>
                              setState(() => _amount = max(1, _amount - 5)),
                        ),
                        Text(_amount.toStringAsFixed(2),
                            style: const TextStyle(fontSize: 18)),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline,
                              color: Colors.white70),
                          onPressed: () => setState(() => _amount += 5),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [10, 100, 500, 1000]
                          .map((v) => GestureDetector(
                                onTap: () =>
                                    setState(() => _amount = v.toDouble()),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10141C),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(v == 1000 ? '1K' : '$v',
                                      style: const TextStyle(
                                          color: Colors.white70)),
                                ),
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: SizedBox(height: 76, child: action)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2F3A),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.replay, size: 16, color: Colors.white70),
                      SizedBox(width: 6),
                      Text('Autoplay',
                          style: TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2F3A),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Center(
                    child: Text('Auto Cash Out',
                        style: TextStyle(color: Colors.white70)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StarPainter extends CustomPainter {
  const _StarPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF0E2036), Color(0xFF070D16)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bg);

    final rand = Random(42);
    final dot = Paint()..color = Colors.white38;
    for (var i = 0; i < 60; i++) {
      final x = rand.nextDouble() * size.width;
      final y = rand.nextDouble() * size.height;
      canvas.drawCircle(Offset(x, y), rand.nextDouble() * 1.4 + 0.3, dot);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

class _FrontPlanePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD8232A)
      ..style = PaintingStyle.fill;
    final cx = size.width / 2;
    final cy = size.height * 0.45;
    // fuselage circle
    canvas.drawCircle(Offset(cx, cy), 34, paint);
    // wings
    final wing = Path()
      ..moveTo(cx - 130, cy + 8)
      ..quadraticBezierTo(cx, cy + 30, cx + 130, cy + 8)
      ..quadraticBezierTo(cx, cy - 10, cx - 130, cy + 8)
      ..close();
    canvas.drawPath(wing, paint);
    // propeller ring
    canvas.drawCircle(Offset(cx, cy), 44, Paint()
      ..color = const Color(0xFFD8232A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6);
    // top tail
    final tail = Path()
      ..moveTo(cx - 30, cy - 40)
      ..quadraticBezierTo(cx, cy - 70, cx + 30, cy - 40)
      ..lineTo(cx + 24, cy - 34)
      ..quadraticBezierTo(cx, cy - 58, cx - 24, cy - 34)
      ..close();
    canvas.drawPath(tail, paint);
    // center hole
    canvas.drawCircle(Offset(cx, cy), 22,
        Paint()..color = const Color(0xFF0E1B2A));
    canvas.drawCircle(Offset(cx, cy), 8, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

class _FlyingPlanePainter extends CustomPainter {
  final double progress;
  _FlyingPlanePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final end = Offset(
        size.width * progress, size.height * (1 - progress * 0.8));
    final painter = TextPainter(
      text: const TextSpan(
          text: '✈',
          style: TextStyle(fontSize: 44, color: Color(0xFFD8232A))),
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

class _CurvePainter extends CustomPainter {
  final double progress;
  _CurvePainter({required this.progress});

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
          const Color(0xFFD8232A).withValues(alpha: 0.6),
          const Color(0xFFD8232A).withValues(alpha: 0.08),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(fill, fillPaint);

    final stroke = Paint()
      ..color = const Color(0xFFD8232A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawPath(curve, stroke);
  }

  @override
  bool shouldRepaint(_CurvePainter old) => old.progress != progress;
}
