import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:logging/logging.dart';
import 'package:lottie_flutter/lottie_flutter.dart';
import 'package:flutter/widgets.dart';

final _logger = Logger('animated_emoji');

class AnimatedEmoji extends StatefulWidget {
  const AnimatedEmoji({Key key, this.asset}) : super(key: key);
  AnimatedEmoji.points(int points) : this(asset: assetForPoints(points));

  final String asset;

  static String assetForPoints(int points) {
    switch (points) {
      case 0:
        return 'assets/lottie/1441-suspects.json';
      case 1:
        return 'assets/lottie/44-emoji-shock.json';
      case 2:
        return 'assets/lottie/4054-smoothymon-clap.json';
      case 3:
      case 4:
        return 'assets/lottie/677-trophy.json';
    }
    _logger.shout('invalid points $points');
    return 'assets/lottie/1441-suspects.json';
  }

  @override
  _AnimatedEmojiState createState() => _AnimatedEmojiState();
}

const _assets = [
  'assets/lottie/44-emoji-shock.json',
  'assets/lottie/1441-suspects.json',
  'assets/lottie/4054-smoothymon-clap.json',
  'assets/lottie/6365-amazing-animationemoji.json',
  'assets/lottie/677-trophy.json',
//  'assets/lottie/1434-mr-lama-stikers-suspect.json',
//  'assets/lottie/945-happy-emoji-great-work.json',
//  'assets/lottie/2837-trophy-animation.json',
//  'assets/lottie/1801-fireworks.json',
];

class _AnimatedEmojiState extends State<AnimatedEmoji> with SingleTickerProviderStateMixin {
  LottieComposition _composition;
  MyAnimationController _controller;
  int _assetNr = 0;

  Timer _animationTimeoutTimer;

  @override
  void initState() {
    super.initState();
    _controller = MyAnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _loadAsset();
//    _controller.addListener(() => setState(() {}));
  }

  void _loadAsset() {
//    final assetName = 'assets/lottie/44-emoji-shock.json';
    final assetName = widget.asset ?? _assets[_assetNr];
    loadAsset(assetName).then((LottieComposition composition) {
      _logger.fine('Loaded lottie composition ($_assetNr ${_assets[_assetNr]}): ${composition.bounds.size}');
      setState(() {
        _composition = composition;
        _controller.reset();
        _controller.repeat(period: Duration(milliseconds: composition.duration));
//        _controller.forward(from: 0);
        _scheduleTimeout();
      });
    });
  }

  void _scheduleTimeout() {
    _animationTimeoutTimer?.cancel();
    _animationTimeoutTimer = Timer(const Duration(seconds: 10), () {
      _logger.fine('timeout reached, stopping animation.');
      _controller.stop();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _logger.fine('didChangeDependencies');
    if (!_controller.isAnimating) {
      _controller.reset();
      _controller.forward(from: 0);
    }
  }

  @override
  void didUpdateWidget(AnimatedEmoji oldWidget) {
    super.didUpdateWidget(oldWidget);
    _logger.fine('didUpdateWidget ${_controller.isCompleted} ${_controller.value}');
    if (!_controller.isAnimating) {
//      _controller.reset();
//      _controller.forward(from: 0);
      _loadAsset();
    } else {
      _scheduleTimeout();
    }
  }

  @override
  void dispose() {
    _animationTimeoutTimer?.cancel();
    _logger.fine('Disposing animation controller.');
    _controller._dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const maxSize = Size(200.0, 200.0);
    return GestureDetector(
      onTap: () {
        _assetNr++;
        if (_assetNr >= _assets.length) {
          _assetNr = 0;
        }
        _loadAsset();
//        _controller.forward(from: 0);
      },
      child: Center(
        child: SizedBox(
          height: maxSize.height,
          width: maxSize.width,
          child: _composition == null
              ? Container()
              : Lottie(
                  composition: _composition,
                  size: _composition.bounds.size > maxSize ? maxSize : _composition.bounds.size,
                  controller: _controller,
                ),
        ),
      ),
    );
  }
}

class MyAnimationController extends AnimationController {
  MyAnimationController({
    Duration duration,
    @required TickerProvider vsync,
  }) : super(
          duration: duration,
          vsync: vsync,
        );
  bool _ignoreDispose = true;

  @override
  void dispose() {
    if (!_ignoreDispose) {
      _logger.fine('Proceeding with AnimationControler.dispose()');
      super.dispose();
    } else {
      _logger.fine('Ignoring AnimationControler.dispose()');
    }
  }

  void _dispose() {
    _ignoreDispose = false;
    dispose();
  }
}

Future<LottieComposition> loadAsset(String assetName) async {
  return await rootBundle
      .loadString(assetName)
      .then<Map<String, dynamic>>((String data) => json.decode(data) as Map<String, dynamic>)
      .then((Map<String, dynamic> map) => LottieComposition.fromMap(map));
}
