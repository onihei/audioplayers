import 'dart:html';
import 'dart:typed_data';

import 'package:js/js.dart';

@JS('AudioContext')
@staticInterop
abstract class JsAudioContext {
  external factory JsAudioContext();
}

extension JsAudioContextExtension on JsAudioContext {
  external MediaElementAudioSourceNode createMediaElementSource(
    AudioElement element,
  );

  external void decodeAudioData(
      ByteBuffer buffer,
      Function(AudioBuffer buffer) onSuccess,
      );

  external AudioBufferSourceNode createBufferSource();

  external GainNode createGain();

  external StereoPannerNode createStereoPanner();

  external AudioNode get destination;

  external double get currentTime;
}

@JS()
@staticInterop
abstract class AudioNode {
  external factory AudioNode();
}

@JS()
@staticInterop
abstract class AudioBuffer {
  external factory AudioBuffer();
}

extension AudioBufferExtension on AudioBuffer {
  external double get duration;

  external double playbackRate;
}

extension AudioNodeExtension on AudioNode {
  external AudioNode connect(AudioNode audioNode);
}

@JS()
@staticInterop
class AudioParam {
  external factory AudioParam();
}

extension AudioParamExtension on AudioParam {
  external num value;
}

@JS()
@staticInterop
class StereoPannerNode implements AudioNode {
  external factory StereoPannerNode();
}

extension StereoPannerNodeExtension on StereoPannerNode {
  external AudioParam get pan;
}

@JS()
@staticInterop
class GainNode implements AudioNode {
  external factory GainNode();
}

extension GainNodeExtension on GainNode {
  external AudioParam get gain;
}

@JS()
@staticInterop
class MediaElementAudioSourceNode implements AudioNode {
  external factory MediaElementAudioSourceNode();
}

@JS()
@staticInterop
class AudioBufferSourceNode implements AudioNode {
  external factory AudioBufferSourceNode();

}

extension AudioBufferSourceNodeExtension on AudioBufferSourceNode {
  external AudioBuffer buffer;

  external bool loop;

  external void start(double when, double offset);

  external void stop();
}
