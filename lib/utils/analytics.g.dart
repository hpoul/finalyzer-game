// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analytics.dart';

// **************************************************************************
// AnalyticsEventGenerator
// **************************************************************************

class AnalyticsEventImpl implements AnalyticsEvent {
  AnalyticsEventImpl(this.tracker);

  final TrackAnalytics tracker;

  @override
  void trackResultVerify() => tracker('trackResultVerify', <String, dynamic>{});
  @override
  void trackTurnVerify({GameType gameType, int score}) =>
      tracker('trackTurnVerify', <String, dynamic>{
        'gameType': gameType?.toString()?.substring(9),
        'score': score
      });
}
