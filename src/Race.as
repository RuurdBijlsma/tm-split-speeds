
// Yoinked from AnfR82's plugin No-Respawn Timer
// Modified by RuteNL

namespace Race {
	bool finishHandled = false;
	bool retireHandled = false;
	int timeCheckTicks = -1;
	uint lastRaceTime = 0;
	uint lastPrevRaceTime = 3000000000;
	
#if TMNEXT
	// Get time since start of run, not as accurate as ghost time
	uint GetRunningTime() {
		auto playground = cast<CSmArenaClient>(GetApp().CurrentPlayground);
		auto player = cast<CSmPlayer>(playground.GameTerminals[0].GUIPlayer);
		auto scriptPlayer = player is null ? null : cast<CSmScriptPlayer>(player.ScriptAPI);
		auto playgroundScript = cast<CSmArenaRulesMode@>(GetApp().PlaygroundScript);

		if (playgroundScript is null)
			// Online 
			return GetApp().Network.PlaygroundClientScriptAPI.GameTime - scriptPlayer.StartTime;
		else
			// Solo
			return playgroundScript.Now - scriptPlayer.StartTime;
	}
#endif
	
	void Update() {

#if TMNEXT

		auto playground = cast<CSmArenaClient>(GetApp().CurrentPlayground);
		if(playground is null) return;
		auto sequence = playground.GameTerminals[0].UISequence_Current;
		auto playgroundScript = cast<CSmArenaRulesMode@>(GetApp().PlaygroundScript);

		// Detect run start
		auto player = cast<CSmPlayer>(playground.GameTerminals[0].GUIPlayer);
		if(player !is null) {
			auto scriptPlayer = cast<CSmScriptPlayer@>(player.ScriptAPI);
			auto post = scriptPlayer.Post;
			if(!retireHandled && post == CSmScriptPlayer::EPost::Char) {
				retireHandled = true;
			} else if(retireHandled && post == CSmScriptPlayer::EPost::CarDriver) {
				Map::HandleRunStart();
				retireHandled = false;
			}
		}

		// Detect run finish:
		if (sequence == CGamePlaygroundUIConfig::EUISequence::Finish && !finishHandled) {
			finishHandled = true;
			
			if (playgroundScript !is null)
				// Solo
				timeCheckTicks = 5;
			else
				// Online
				timeCheckTicks = 0;
			// If last ghost isn't loaded, or player is online, use running time instead of ghosts
			lastRaceTime = GetRunningTime();
			// print("ESTIMATED FINISH TIME: " + lastRaceTime);
		}

		if(timeCheckTicks > 0) timeCheckTicks--;
		if(timeCheckTicks == 0) {
			// Player just finished in offline, waited a few ticks for the newest ghost to appear
			timeCheckTicks = -1;
			bool online = true;
			if(playgroundScript !is null) {
				// Solo
				online = false;
				lastRaceTime = Ghost::GetLastRunTime();
			}
			// print("FINAL FINISH TIME: " + lastRaceTime + ", ONLINE = " + online);
			Map::HandleFinish(lastRaceTime, online);
		}

		// Make sure finish code triggers only once per finish
		if (sequence != CGamePlaygroundUIConfig::EUISequence::Finish)
			finishHandled = false;

#elif TURBO
		// Check for run start

		auto playground = cast<CGamePlayground@>(GetApp().CurrentPlayground);
		if(playground is null) return;
		auto terminal = playground.GameTerminals[0];
		if(terminal is null) return;
		auto player = cast<CTrackManiaPlayer@>(terminal.ControlledPlayer);

		auto raceState = player.RaceState;
		if(raceState == CTrackManiaPlayer::ERaceState::Running && !retireHandled) {
			print("Start!");
			Map::HandleRunStart();
			retireHandled = true;
		} else if(retireHandled && raceState != CTrackManiaPlayer::ERaceState::Running) {
			retireHandled = false;
		}

		// Check for run finish

		auto prevRecord = playground.PrevReplayRecord;
		if(prevRecord !is null && prevRecord.Ghosts.Length > 0) {
			auto ghost = prevRecord.Ghosts[0];
			if(player.RaceState == CTrackManiaPlayer::ERaceState::Finished
				&& lastPrevRaceTime != player.Score.LastRaceTime) {
				lastPrevRaceTime = player.Score.LastRaceTime;
				if(lastPrevRaceTime < 3000000000) {
					print("Finish!: " + lastPrevRaceTime);
					Map::HandleFinish(lastPrevRaceTime, false);
				}
			}
		}

#elif MP4
		// Check for run start

		auto app = cast<CTrackMania@>(GetApp());
		auto playground = cast<CGamePlayground@>(app.CurrentPlayground);
		if(playground is null) return;
		auto terminal = playground.GameTerminals[0];
		if(terminal is null) return;
		auto player = cast<CTrackManiaPlayer@>(terminal.ControlledPlayer);

		auto scriptPlayer = player.ScriptAPI;
		auto raceState = scriptPlayer.RaceState;
		if(raceState == CTrackManiaPlayer::ERaceState::Running && !retireHandled) {
			print("Start!");
			Map::HandleRunStart();
			retireHandled = true;
		} else if(retireHandled && raceState != CTrackManiaPlayer::ERaceState::Running) {
			retireHandled = false;
		}

		// Check for run finish
		
		auto prevRecord = playground.PrevReplayRecord;
		if(prevRecord !is null && prevRecord.Ghosts.Length > 0) {
			auto ghost = prevRecord.Ghosts[0];
			if(ghost.RaceTime != lastPrevRaceTime){ 
				lastPrevRaceTime = ghost.RaceTime;
				if(lastPrevRaceTime < 3000000000) {
					print("Finish!: " + ghost.RaceTime);
					Map::HandleFinish(ghost.RaceTime, false);
				}
			}
		}

#endif

	}

}