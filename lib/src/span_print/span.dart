import 'dart:async';
import 'dart:io';

class Spinner {
  static const _spinnerFrames = ['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏'];
  final String message;
  final Duration speed;
  int _index = 0;
  Timer? _timer;

  Spinner(this.message, {this.speed = const Duration(milliseconds: 100)});

  void start() {
    stdout.write('\r$message... ${_spinnerFrames[_index]}');
    _timer = Timer.periodic(speed, (_) {
      _index = (_index + 1) % _spinnerFrames.length;
      stdout.write('\r$message... ${_spinnerFrames[_index]}');
    });
  }

  void stop({String? doneMessage}) {
    _timer?.cancel();
    stdout.write('\r$message... ${doneMessage ?? "✓"}\n');
  }
}