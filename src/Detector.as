/*
 * author: Phlarx
 * Modified by RuteNL to use as in game detector
 */

namespace Detector {
    
    bool _inGame = false;
    bool get_InGame() property { return _inGame; }

    void Update() {
        _inGame = DetectInGame();
    }

    bool DetectInMenu() {
#if TMNEXT
        auto playground = cast<CSmArenaClient>(GetApp().CurrentPlayground);
        return playground is null or playground.Map is null;
#elif MP4
        return GetApp().RootMap is null;
#elif TURBO
        return false;
#endif
    }

    bool DetectInGame() {
#if TMNEXT

        // Check if we're in game
        auto playground = cast<CSmArenaClient>(GetApp().CurrentPlayground);
        if(playground is null
            || playground.Arena is null
            || playground.Map is null
            || playground.GameTerminals.Length <= 0
            || (
                playground.GameTerminals[0].UISequence_Current != CGamePlaygroundUIConfig::EUISequence::Playing
                && playground.GameTerminals[0].UISequence_Current != CGamePlaygroundUIConfig::EUISequence::Finish
            )
            || cast<CSmPlayer>(playground.GameTerminals[0].GUIPlayer) is null) {
            return false;
        }
        auto player = cast<CSmPlayer>(playground.GameTerminals[0].GUIPlayer);
        auto scriptPlayer = cast<CSmPlayer>(playground.GameTerminals[0].GUIPlayer).ScriptAPI;
        if(player is null || scriptPlayer is null || player.CurrentLaunchedRespawnLandmarkIndex == uint(-1)) {
            return false;
        }
            
#elif TURBO

        // Check if we're in game
        auto playground = cast<CTrackManiaRaceNew>(GetApp().CurrentPlayground);
        auto playgroundScript = cast<CTrackManiaRaceRules>(GetApp().PlaygroundScript);
        if(playground is null
            || playgroundScript is null
            || playground.GameTerminals.Length <= 0
            || cast<CTrackManiaPlayer>(playground.GameTerminals[0].ControlledPlayer) is null) {
            return false;
        }
        auto player = cast<CTrackManiaPlayer>(playground.GameTerminals[0].ControlledPlayer);
        if(player is null
            || player.CurLap is null
            || player.RaceState != CTrackManiaPlayer::ERaceState::Running) {
            return false;
        }

#elif MP4

        // Check if we're in game
        auto playground = cast<CTrackManiaRaceNew>(GetApp().CurrentPlayground);
        auto rootMap = GetApp().RootMap;
        if(playground is null
            || rootMap is null
            || playground.GameTerminals.Length <= 0
            || cast<CTrackManiaPlayer>(playground.GameTerminals[0].GUIPlayer) is null) {
            return false;
        }
        auto scriptPlayer = cast<CTrackManiaPlayer>(playground.GameTerminals[0].GUIPlayer).ScriptAPI;
        if(scriptPlayer is null
            || scriptPlayer.CurLap is null
            || scriptPlayer.RaceState != CTrackManiaPlayer::ERaceState::Running) {
            return false;
        }

#endif
        return true;
    }
        
}