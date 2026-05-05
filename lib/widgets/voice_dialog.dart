import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../providers/firebase_providers.dart';

class VoiceDialog extends ConsumerStatefulWidget {
  const VoiceDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (_) => const Dialog(
        backgroundColor: Colors.transparent,
        child: VoiceDialog(),
      ),
    );
  }

  @override
  ConsumerState<VoiceDialog> createState() => _VoiceDialogState();
}

class _VoiceDialogState extends ConsumerState<VoiceDialog>
    with SingleTickerProviderStateMixin {
  final SpeechToText _speech = SpeechToText();
  final TextEditingController _controller = TextEditingController();
  late final AnimationController _pulse;
  bool _listening = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
      lowerBound: 0.9,
      upperBound: 1.05,
    );
  }

  @override
  void dispose() {
    _speech.cancel();
    _pulse.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    final ok = await _speech.initialize(
      onError: (e) => setState(() => _error = e.errorMsg),
      onStatus: (s) {
        if (s == 'done' || s == 'notListening') {
          setState(() => _listening = false);
          _pulse.stop();
        }
      },
    );
    if (!ok) {
      setState(() => _error = 'Không có quyền micro.');
      return;
    }
    await _speech.listen(
      onResult: (r) {
        setState(() => _controller.text = r.recognizedWords);
      },
    );
    setState(() {
      _listening = true;
      _error = null;
    });
    _pulse.repeat(reverse: true);
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() => _error = 'Không nhận diện được giọng nói.');
      return;
    }
    try {
      final service = ref.read(firebaseServiceProvider);
      final connected = await service.checkConnection();
      if (!connected) {
        setState(() => _error = 'Không có internet hoặc Firebase offline.');
        return;
      }
      await service.sendVoiceCommand(text);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã gửi voice command lên Firebase.')),
      );
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF171C30),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Voice Control',
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
          const SizedBox(height: 14),
          ScaleTransition(
            scale: _pulse,
            child: GestureDetector(
              onTap: _listening ? null : _start,
              child: Container(
                width: 110,
                height: 110,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF26C6DA), Color(0xFF0097A7)],
                  ),
                ),
                child: Icon(
                  _listening ? Icons.hearing : Icons.mic,
                  color: Colors.white,
                  size: 44,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Recognized text...',
              border: OutlineInputBorder(),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Colors.redAccent)),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: _send,
                  child: const Text('Send'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
