import 'dart:async';
import 'dart:typed_data';

import 'package:audioplayers_platform_interface/audioplayers_platform_interface.dart';
import 'package:audioplayers_web/global_audioplayers_web.dart';
import 'package:audioplayers_web/num_extension.dart';
import 'package:audioplayers_web/web_audio_js.dart';
import 'package:audioplayers_web/wrapped_player.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

class AudioplayersPlugin {
  /// The entrypoint called by the generated plugin registrant.
  static void registerWith(Registrar registrar) {
    AudioplayersPlatformInterface.instance = WebAudioplayersPlatform();
    GlobalAudioplayersPlatformInterface.instance =
        WebGlobalAudioplayersPlatform();
  }
}

class WebAudioplayersPlatform extends AudioplayersPlatformInterface {
  // players by playerId
  Map<String, WrappedPlayer> players = {};

  @override
  Future<void> create(String playerId) async {
    players[playerId] = WrappedPlayer(playerId);
  }

  WrappedPlayer getPlayer(String playerId) {
    return players[playerId] != null
        ? players[playerId]!
        : throw PlatformException(
            code: 'WebAudioError',
            message: 'Player with id $playerId was not created!',
          );
  }

  @override
  Future<int?> getCurrentPosition(String playerId) async {
    final currentTime = getPlayer(playerId).audioContext?.currentTime;
    if (currentTime == null) {
      return null;
    }
    return (currentTime * 1000).toInt();
  }

  @override
  Future<int?> getDuration(String playerId) async {
    final buffer =  await getPlayer(playerId).currentBuffer;
    if (buffer == null) {
      return null;
    }
    return buffer.duration.fromSecondsToDuration().inMilliseconds;
  }

  @override
  Future<void> pause(String playerId) async {
    getPlayer(playerId).pause();
  }

  @override
  Future<void> release(String playerId) async {
    getPlayer(playerId).release();
  }

  @override
  Future<void> resume(String playerId) async {
    await getPlayer(playerId).resume();
  }

  @override
  Future<void> seek(String playerId, Duration position) async {
    getPlayer(playerId).seek(position.inMilliseconds);
  }

  @override
  Future<void> setAudioContext(
    String playerId,
    AudioContext audioContext,
  ) async {
    getPlayer(playerId).setAudioContext(audioContext);
  }

  @override
  Future<void> setPlayerMode(
    String playerId,
    PlayerMode playerMode,
  ) async {
    // no-op: web doesn't have multiple modes
  }

  @override
  Future<void> setPlaybackRate(String playerId, double playbackRate) async {
    await getPlayer(playerId).setPlaybackRate(playbackRate);
  }

  @override
  Future<void> setReleaseMode(String playerId, ReleaseMode releaseMode) async {
    getPlayer(playerId).releaseMode = releaseMode;
  }

  @override
  Future<void> setSourceUrl(
    String playerId,
    String url, {
    bool? isLocal,
  }) async {
    await getPlayer(playerId).setUrl(url);
  }

  @override
  Future<void> setSourceBytes(String playerId, Uint8List bytes) async {
    getPlayer(playerId).setSourceBytes(bytes);
  }

  @override
  Future<void> setVolume(String playerId, double volume) async {
    getPlayer(playerId).volume = volume;
  }

  @override
  Future<void> setBalance(String playerId, double balance) async {
    getPlayer(playerId).balance = balance;
  }

  @override
  Future<void> stop(String playerId) async {
    getPlayer(playerId).stop();
  }

  @override
  Future<void> emitLog(String playerId, String message) async {
    getPlayer(playerId).log(message);
  }

  @override
  Future<void> emitError(String playerId, String code, String message) async {
    getPlayer(playerId)
        .eventStreamController
        .addError(PlatformException(code: code, message: message));
  }

  @override
  Stream<AudioEvent> getEventStream(String playerId) {
    return getPlayer(playerId).eventStreamController.stream;
  }

  @override
  Future<void> dispose(String playerId) async {
    final player = getPlayer(playerId);
    await player.dispose();
    players.remove(playerId);
  }
}
