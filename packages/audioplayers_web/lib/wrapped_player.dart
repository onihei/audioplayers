import 'dart:async';
import 'dart:js';
import 'dart:typed_data';

import 'package:audioplayers_platform_interface/audioplayers_platform_interface.dart';
import 'package:audioplayers_web/web_audio_js.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';

class WrappedPlayer {
  final String playerId;
  final eventStreamController = StreamController<AudioEvent>.broadcast();

  JsAudioContext? audioContext;
  double? _pausedAt;
  double _currentVolume = 1.0;
  double _currentPlaybackRate = 1.0;
  ReleaseMode _currentReleaseMode = ReleaseMode.release;
  String? _currentUrl;
  Future<AudioBuffer>? currentBuffer;
  bool _isPlaying = false;

  AudioBufferSourceNode? _currentSource;
  StereoPannerNode? _stereoPanner;
  GainNode? _gain;

  WrappedPlayer(this.playerId);

  void setAudioContext(AudioContext context) {
    final ctx = context.web as JsAudioContext;
    audioContext = ctx;
  }

  Future<void> setSourceBytes(Uint8List bytes) async{
    final completer = Completer<AudioBuffer>();
    audioContext!.decodeAudioData(
      Uint8List.fromList(bytes.toList()).buffer,
      allowInterop(completer.complete),
    );
    currentBuffer = completer.future;
    _currentUrl = null;

    stop();
    recreateNode();
    if (_isPlaying) {
      await resume();
    }
  }

  Future<void> setUrl(String url) async {
    if (_currentUrl == url) {
      return; // nothing to do
    }

    final uri = Uri.parse(url);
    final response = await get(uri);
    final bytes = response.bodyBytes;
    final completer = Completer<AudioBuffer>();
    audioContext!.decodeAudioData(
      Uint8List.fromList(bytes.toList()).buffer,
      allowInterop(completer.complete),
    );
    currentBuffer = completer.future;
    _currentUrl = url;

    stop();
    recreateNode();
    if (_isPlaying) {
      await resume();
    }
  }

  set volume(double volume) {
    _currentVolume = volume;
    _gain?.gain.value = volume;
  }

  set balance(double balance) {
    _stereoPanner?.pan.value = balance;
  }

  Future<void> setPlaybackRate(double rate) async {
    _currentPlaybackRate = rate;
    final buffer = await currentBuffer;
    if (buffer != null) {
      buffer.playbackRate = rate;
    }
  }

  Future<void> recreateNode() async {
    final buffer = currentBuffer;
    if (buffer == null) {
      return;
    }

    final ctx = audioContext ?? JsAudioContext();
    final source = ctx.createBufferSource();
    source.buffer = await buffer;
    final stereoPannerNode = ctx.createStereoPanner();
    final gainNode = ctx.createGain();
    source.connect(stereoPannerNode);
    stereoPannerNode.connect(gainNode);
    gainNode.connect(ctx.destination);
    gainNode.gain.value = _currentVolume;
    source.loop = shouldLoop();
    _stereoPanner = stereoPannerNode;
    _gain = gainNode;
    _currentSource = source;
  }

  bool shouldLoop() => _currentReleaseMode == ReleaseMode.loop;

  set releaseMode(ReleaseMode releaseMode) {
    _currentReleaseMode = releaseMode;
  }

  void release() {
    _cancel();
    _stereoPanner = null;
    _gain = null;
  }

  Future<void> start(double position) async {
    _isPlaying = true;
    if (currentBuffer == null) {
      return; // nothing to play yet
    }
    await recreateNode();
    _currentSource?.start(0, position);
  }

  Future<void> resume() async {
    await start(_pausedAt ?? 0);
  }

  void pause() {
    if (_isPlaying) {
      _pausedAt = audioContext?.currentTime;
      _currentSource?.stop();
    }
  }

  void stop() {
    _cancel();
  }

  void seek(int position) {
    final seekPosition = position / 1000.0;

    if (!_isPlaying) {
      _pausedAt = seekPosition;
    } else {
      pause();
      _pausedAt = seekPosition;
      resume();
    }
  }

  void _cancel() {
    if (_isPlaying) {
      _currentSource?.stop();
    }
    _isPlaying = false;
  }

  void log(String message) {
    eventStreamController.add(
      AudioEvent(eventType: AudioEventType.log, logMessage: message),
    );
  }

  Future<void> dispose() async {
    eventStreamController.close();
  }
}
