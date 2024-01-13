
// Yoinked from AnfR82's plugin No-Respawn Timer
// Modified by RuteNL

namespace Race {
	bool finishHandled = false;
	bool retireHandled = false;
	int timeCheckTicks = -1;
	uint lastRaceTime = 0;

	// Get exact last run time from a ghost 👻
	// Only works in solo
	uint GetOfflineRaceTime(CSmArenaRulesMode@ playgroundScript) {
		uint result = 0;
		string playerName = GetApp().LocalPlayerInfo.Name;
		auto ghosts = playgroundScript.DataFileMgr.Ghosts;
		CGameGhostScript@ ghost = null;
		for(int i = ghosts.Length - 1; i >= 0; i--) {
			if (ghosts[i].Nickname == playerName) {
				@ghost = ghosts[i];
				break;
			}
		}
		if (ghost !is null) 
			result = ghost.Result.Time;
		return result;
	}
	
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
	
	void Update() {
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
			print("FINISH!");
			
			if (playgroundScript !is null)
				// Solo
				timeCheckTicks = 5;
			else
				// Online
				timeCheckTicks = 0;
			// If last ghost isn't loaded, or player is online, use running time instead of ghosts
			lastRaceTime = GetRunningTime();
			print("ESTIMATED FINISH TIME: " + lastRaceTime);
		}

		if(timeCheckTicks > 0) timeCheckTicks--;
		if(timeCheckTicks == 0) {
			// Player just finished in offline, waited a few ticks for the newest ghost to appear
			timeCheckTicks = -1;
			bool online = true;
			if(playgroundScript !is null) {
				online = false;
				lastRaceTime = GetOfflineRaceTime(playgroundScript);
			}
			print("FINAL FINISH TIME: " + lastRaceTime + ", ONLINE = " + online);
			Map::HandleFinish(lastRaceTime, online);
		}

		// Make sure finish code triggers only once per finish
		if (sequence != CGamePlaygroundUIConfig::EUISequence::Finish)
			finishHandled = false;
	}

}