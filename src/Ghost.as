namespace Ghost {

#if TMNEXT

	// Get exact last run time from a ghost 👻
	// Only works in solo
	uint GetLastRunTime() {
		uint result = 0;
		auto playgroundScript = cast<CSmArenaRulesMode@>(GetApp().PlaygroundScript);
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

	// PB ghost has trigram |
    uint GetPB() {
        uint pb = 0;
        auto playgroundScript = cast<CSmArenaRulesMode@>(GetApp().PlaygroundScript);
        if(playgroundScript !is null) {
            auto ghosts = playgroundScript.DataFileMgr.Ghosts;
            CGameGhostScript@ ghost = null;
            for(uint i = 0; i < ghosts.Length; i++) {
                if (ghosts[i].Trigram == "|") {
                    @ghost = ghosts[i];
                    break;
                }
            }
            if (ghost !is null) 
                pb = ghost.Result.Time;
        }
        return pb;
    }

#elif MP4

	uint GetLastRunTime() {
        return 0;
    }

    int maxInt = 2147483647;
    uint GetPB() {
        // print("Getting map pb");
        auto app = cast<CTrackMania>(GetApp());
        CGameCtnPlayground@ playground = cast<CGameCtnPlayground@>(app.CurrentPlayground);
        int time = maxInt;
        if (playground.PlayerRecordedGhost !is null){
            time = playground.PlayerRecordedGhost.RaceTime;
        }
        // print("JFDJFJDFJDFJDFJ");
        if(app.PlaygroundScript !is null){
            auto ghosts = app.PlaygroundScript.DataFileMgr.Ghosts;
            for(uint i = 0; i < ghosts.Length; i++){
                auto ghost = ghosts[i];
                if(ghost.Result.Time < time){
                    time = ghost.Result.Time;
                }
            }
            print("LOWEST TIME FROM SCRIPT: " + tostring(time));
        }
        return time;
    }

#endif

}