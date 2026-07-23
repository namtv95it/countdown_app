import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'storage_service.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool _isMusicEnabled = false;

  bool get isPlaying => _isPlaying;
  bool get isMusicEnabled => _isMusicEnabled;

  Future<void> init() async {
    _audioPlayer.setReleaseMode(ReleaseMode.loop);
    _isMusicEnabled = await StorageService().getIsMusicEnabled();
    
    _audioPlayer.onPlayerStateChanged.listen((state) {
      _isPlaying = state == PlayerState.playing;
    });

    if (_isMusicEnabled) {
      await updateMusicSource();
    }
  }

  Future<void> updateMusicSource() async {
    if (!_isMusicEnabled) {
      await stopMusic();
      return;
    }
    
    final selectedMusicId = await StorageService().getSelectedMusicId();
    if (selectedMusicId == 'none') {
      await stopMusic();
      return;
    }

    try {
      if (selectedMusicId == 'custom') {
        final path = await StorageService().getCustomMusicPath();
        if (path != null && path.isNotEmpty) {
          await _audioPlayer.play(DeviceFileSource(path));
        } else {
          await stopMusic();
        }
      } else {
        // Fallback for when default music is selected but not supported anymore
        await stopMusic();
      }
    } catch (e) {
      debugPrint('Error playing audio: $e');
    }
  }

  Future<void> playMusic() async {
    if (!_isMusicEnabled) return;
    await updateMusicSource();
  }

  Future<void> stopMusic() async {
    try {
      await _audioPlayer.stop();
    } catch (e) {
      debugPrint('Error stopping audio: $e');
    }
  }

  Future<void> toggleMusic(bool enable) async {
    _isMusicEnabled = enable;
    await StorageService().setMusicEnabled(enable);
    if (enable) {
      playMusic();
    } else {
      stopMusic();
    }
  }

  Future<void> pauseMusic() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    }
  }

  Future<void> resumeMusic() async {
    if (_isMusicEnabled && !_isPlaying) {
      playMusic();
    }
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}
