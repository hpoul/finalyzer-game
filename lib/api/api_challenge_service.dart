

import 'package:anlage_app_game/api/api_caller.dart';
import 'package:anlage_app_game/api/dtos.generated.dart';

class ApiChallenge {
  final ApiCaller _apiCaller;

  ApiChallenge(this._apiCaller);

  Future<GameChallengeInviteResponse> createChallengeInvite(String displayName) {
    return _apiCaller.post(GameChallengeInviteLocation(), GameChallengeInviteCreateRequest(displayName));
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

  Future<GameChallengeDto> startChallenge(String challengeId) {
    return _apiCaller.put(GameChallengeLocation(challengeId), new GameChallengeRequest(GameChallengeAction.Start));
  }

  Future<GameChallengeDetailsResponse> getGameChallengeDetails(String challengeId) =>
    _apiCaller.get(GameChallengeLocation(challengeId));
}