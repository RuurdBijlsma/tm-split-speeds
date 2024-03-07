/*
 * author: Phlarx
 * Modified by RuteNL to use as waypoint detector (start / finish / multilap / checkpoint)
 */

namespace Waypoint {
	uint _curCP = 0;
	uint _preCPIdx = 0;
	
	uint get_curCP() property { return _curCP; }
	
	void Update() {
		if(!Detector::InGame) return;
		
#if TMNEXT
		auto playground = cast<CSmArenaClient>(GetApp().CurrentPlayground);
		auto player = cast<CSmPlayer>(playground.GameTerminals[0].GUIPlayer);
		
		// Detect waypoints
		MwFastBuffer<CGameScriptMapLandmark@> landmarks = playground.Arena.MapLandmarks;
		if(_preCPIdx != player.CurrentLaunchedRespawnLandmarkIndex && landmarks.Length > player.CurrentLaunchedRespawnLandmarkIndex) {
			_preCPIdx = player.CurrentLaunchedRespawnLandmarkIndex;
			auto landmark = landmarks[_preCPIdx];
			if (landmark.Waypoint is null) {
				// print("START BLOCK TMNEXT");
			} else if (landmark.Waypoint.IsFinish || landmark.Waypoint.IsMultiLap) {
				Map::HandleCheckpoint();
				// print("FINISH or MULTILAP BLOCK TMNEXT");
			} else {
				Map::HandleCheckpoint();
			}
		}
		
#elif TURBO

		/* Detect checkpoints */
		auto player = cast<CTrackManiaPlayer>(playground.GameTerminals[0].ControlledPlayer);
		if(player.CurLap.Checkpoints.Length != _curCP) {
			Map::HandleCheckpoint();
		}
		_curCP = player.CurLap.Checkpoints.Length;
		
#elif MP4

		/* Detect checkpoints */
		auto playground = cast<CTrackManiaRaceNew>(GetApp().CurrentPlayground);
		auto scriptPlayer = cast<CTrackManiaPlayer>(playground.GameTerminals[0].GUIPlayer).ScriptAPI;
		if(scriptPlayer.CurLap.Checkpoints.Length != _curCP && scriptPlayer.CurLap.Checkpoints.Length > 0) {
			Map::HandleCheckpoint();
		}
		_curCP = scriptPlayer.CurLap.Checkpoints.Length;

#endif

	}
}
