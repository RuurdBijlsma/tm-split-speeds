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
        for (int i = ghosts.Length - 1; i >= 0; i--) {
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
        if (playgroundScript !is null && playgroundScript.DataFileMgr !is null) {
            auto ghosts = playgroundScript.DataFileMgr.Ghosts;
            CGameGhostScript@ ghost = null;
            for (uint i = 0; i < ghosts.Length; i++) {
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

#elif TURBO

    uint GetLastRunTime() {
        return 0;
    }

    int maxInt = 2147483647;
    uint GetPB() {
        // print("Getting map pb");
        auto app = cast<CTrackMania>(GetApp());
        CGameCtnPlayground@ playground = cast<CGameCtnPlayground@>(app.CurrentPlayground);
        auto terminal = playground.GameTerminals[0];
        if (terminal is null) return maxInt;
        auto player = cast<CTrackManiaPlayer>(terminal.ControlledPlayer);
        int time = maxInt;

        if (app.PlaygroundScript !is null) {
            auto records = app.PlaygroundScript.DataMgr.Records;
            // See https://github.com/Phlarx/tm-ultimate-medals/blob/76bf469aa3979c90b78a4ecb87c3a7423b635647/UltimateMedals.as#L581
            for (uint i = 0; i < records.Length; i++) {
                // print("i=" + i + ", GhostName: " + records[i].GhostName + ", Time: " + records[i].Time);
                // TODO: identify game mode, and then load arcade or dual-driver best instead? only loads for campaign maps right now
                // if (records[i].GhostName == "Duo_BestGhost") {
                if (records[i].GhostName == "Solo_BestGhost") {
                        time = records[i].Time;
                        break;
                }
                // this shouldn't loop more than a few times, since each entry is a different record type
            }
        }

        print("LOWEST TIME FROM SCRIPT: " + tostring(time));
        return time;
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
        if (playground.PlayerRecordedGhost !is null) {
            time = playground.PlayerRecordedGhost.RaceTime;
        }

        if (app.PlaygroundScript !is null) {
            auto ghosts = app.PlaygroundScript.DataFileMgr.Ghosts;
            for (uint i = 0; i < ghosts.Length; i++) {
                auto ghost = ghosts[i];
                if (ghost.Result.Time < time) {
                    time = ghost.Result.Time;
                }
            }
            print("LOWEST TIME FROM SCRIPT: " + tostring(time));
        }
        return time;
    }

#endif

}