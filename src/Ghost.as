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

    uint GetPB() {
        uint pb = 0;

        print("Hello mp4");
        
        return pb;
    }

#endif

}