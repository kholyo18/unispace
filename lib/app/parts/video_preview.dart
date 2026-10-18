part of '../../main.dart';

class _VideoInitGate {
  _VideoInitGate._();
  static final _VideoInitGate instance = _VideoInitGate._();

  static const int maxConcurrent = 1; // بدلها لـ 3 إلا بغيتي تسمح بشوية أكثر

  int _active = 0;
  final List<Completer<void>> _queue = [];

  Future<void> acquire() async {
    if (_active < maxConcurrent) {
      _active++;
      return;
    }
    final c = Completer<void>();
    _queue.add(c);
    await c.future;
    _active++;
  }

  void release() {
    _active = (_active - 1).clamp(0, 1 << 30);
    if (_queue.isNotEmpty) {
      _queue.removeAt(0).complete();
    }
  }
}

//================================================================
