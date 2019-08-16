// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analytics.dart';

// **************************************************************************
// AnalyticsEventGenerator
// **************************************************************************

class AnalyticsEventImpl implements AnalyticsEvent {
  AnalyticsEventImpl(this.tracker);

  final TrackAnalytics tracker;

  @override
  void trackResultVerify() => tracker('resultVerify', <String, dynamic>{});
  @override
  void trackTurnVerify({GameType gameType, int score}) =>
      tracker('turnVerify', <String, dynamic>{
        'gameType': gameType?.toString()?.substring(9),
        'score': score
      });
  @override
  void trackCloseResultOverlay() =>
      tracker('closeResultOverlay', <String, dynamic>{});
  @override
  void trackDrawerOpen({String source}) =>
      tracker('drawerOpen', <String, dynamic>{'source': source});
}
