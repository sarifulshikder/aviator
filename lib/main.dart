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
        scaffoldBackgroundColor: const Color(0xFF0E1626),
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
  double _balance = 1000.0;
  double _bet = 100.0;
  double? _cashoutAt;
  bool _betPlaced = false;
  final _betController = TextEditingController(text: '100');
  String _message = 'Place your bet!';

  @override
  void dispose() {
    _timer?.cancel();
    _betController.dispose();
    super.dispose();
  }

  double _nextCrashPoint() {
    // exponential distribution skewed to low multipliers
    final r = _random.nextDouble();
    return (1.0 / (1.0 - r * 0.97)).clamp(1.0, 100.0);
  }

  void _startRound() {
    final bet = double.tryParse(_betController.text) ?? 0;
    if (bet <= 0 || bet > _balance) {
      setState(() => _message = 'Invalid bet');
      return;
    }
    setState(() {
      _balance -= bet;
      _bet = bet;
      _betPlaced = true;
      _cashoutAt = null;
      _multiplier = 1.0;
      _crashPoint = _nextCrashPoint();
      _state = RoundState.flying;
      _message = 'Flying...';
    });
    _timer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      setState(() {
        _multiplier += 0.01 + (_multiplier - 1.0) * 0.012;
        if (_multiplier >= _crashPoint) {
          _multiplier = _crashPoint;
          _state = RoundState.crashed;
          _timer?.cancel();
          if (_cashoutAt != null) {
            _message = 'Crashed at ${_crashPoint.toStringAsFixed(2)}x — you won ${(_bet * _cashoutAt!).toStringAsFixed(2)}!';
          } else {
            _message = 'Crashed at ${_crashPoint.toStringAsFixed(2)}x — you lost ${_bet.toStringAsFixed(2)}';
          }
          _betPlaced = false;
        }
      });
    });
  }

  void _cashOut() {
    if (_state != RoundState.flying || !_betPlaced || _cashoutAt != null) return;
    setState(() {
      _cashoutAt = _multiplier;
      _balance += _bet * _multiplier;
      _message = 'Cashed out at ${_multiplier.toStringAsFixed(2)}x!';
    });
  }

  void _newRound() {
    setState(() {
      _state = RoundState.waiting;
      _multiplier = 1.0;
      _cashoutAt = null;
      _betPlaced = false;
      _message = 'Place your bet!';
    });
  }

  @override
  Widget build(BuildContext context) {
    final flying = _state == RoundState.flying;
    final crashed = _state == RoundState.crashed;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AVIATOR'),
        backgroundColor: const Color(0xFF141E33),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Balance: ${_balance.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 20, color: Colors.greenAccent)),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF1B2A44),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${_multiplier.toStringAsFixed(2)}x',
                      style: TextStyle(
                        fontSize: 64,
                        fontWeight: FontWeight.bold,
                        color: crashed ? Colors.redAccent : Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      crashed ? 'FLEW AWAY' : (flying ? '✈' : '—'),
                      style: const TextStyle(fontSize: 40),
                    ),
                    const SizedBox(height: 8),
                    Text(_message, style: const TextStyle(fontSize: 16)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_state == RoundState.waiting) ...[
              TextField(
                controller: _betController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Bet amount',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  onPressed: _startRound,
                  child: const Text('BET & FLY', style: TextStyle(fontSize: 20)),
                ),
              ),
            ] else if (flying) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  onPressed: _cashoutAt == null ? _cashOut : null,
                  child: Text(
                    _cashoutAt == null ? 'CASH OUT' : 'Cashed out — waiting for crash',
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  onPressed: _newRound,
                  child: const Text('NEW ROUND', style: TextStyle(fontSize: 20)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
