import 'package:anlage_app_game/api/api_caller.dart';
import 'package:anlage_app_game/api/dtos.generated.dart';

class ApiChallenge {
  final ApiCaller _apiCaller;

  ApiChallenge(this._apiCaller);

  Future<GameChallengeInviteResponse> createChallengeInvite(GameChallengeInviteType type,
      {String displayName = '', String gameUserToken}) {
    return _apiCaller.post(
        GameChallengeInviteLocation(), GameChallengeInviteCreateRequest(displayName, gameUserToken, type));
  }

  Future<GameChallengeInviteInfoResponse> getChallengeInviteInfo(String inviteToken) {
    return _apiCaller.get(GameChallengeInviteInfoLocation(inviteToken));
  }

  Future<GameChallengeDto> acceptChallengeInvite(String inviteToken) {
    return _apiCaller.put(GameChallengeInviteInfoLocation(inviteToken), GameChallengeInviteInfoAcceptRequest());
  }

  Future<GameChallengeListResponse> listChallenges() {
    return _apiCaller.get(GameChallengeListLocation());
  }

  Future<GameChallengeDto> startChallenge(String challengeId,
      {GameChallengeAction action = GameChallengeAction.Start}) {
    return _apiCaller.put(GameChallengeLocation(challengeId), new GameChallengeRequest(action));
  }

  Future<GameChallengeDetailsResponse> getGameChallengeDetails(String challengeId) =>
      _apiCaller.get(GameChallengeLocation(challengeId));

  Future<void> logShortLink(String challengeInviteToken, String shortLink) =>
      _apiCaller.post(LogShortLinkLocation(), LogShortLinkRequest(challengeInviteToken, shortLink));
}
