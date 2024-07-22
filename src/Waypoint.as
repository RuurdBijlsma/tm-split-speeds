/*
 * author: Phlarx
 * Modified by RuteNL to use as waypoint detector (start / finish / multilap / checkpoint)
 */

namespace Waypoint {
	uint _curLap = 0;
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
		auto currentLap = player.CurrentNbLaps;
		auto currentCP = player.CurLap.Checkpoints.Length;

		if(currentLap > _curLap || currentCP > _curCP) {
			Map::HandleCheckpoint();
		}

		_curLap = currentLap;
		_curCP = currentCP;
		
#elif MP4

		/* Detect checkpoints */
		auto playground = cast<CTrackManiaRaceNew>(GetApp().CurrentPlayground);
		auto player = cast<CTrackManiaPlayer>(playground.GameTerminals[0].GUIPlayer);
		uint currentLap = player.CurrentNbLaps;
		uint currentCP = player.ScriptAPI.CurLap.Checkpoints.Length;

		if(currentLap > _curLap || currentCP > _curCP) {
			Map::HandleCheckpoint();
		}

		_curLap = currentLap;
		_curCP = currentCP;

#endif

	}
}
