namespace Map {
    string mapId = "";
    SpeedRecording@ pbRecord = null;
    SpeedRecording@ sessionRecord = null;
    SpeedRecording@ unfinishedRun = null;
    SpeedRecording@ currentRecord = null;

    uint sessionPB = 0;
    uint currentPB = 0;

    string get_FilePath() {
        return IO::FromStorageFolder(mapId + ".json");
    }

    uint GetMapPB() {
        uint pb = 0;

        if(mapId == "") {
            return pb;
        }

        @pbRecord = SpeedRecording::FromFile(FilePath);
        if(pbRecord !is null) {
            // First try get PB from speedsplit file:
            pb = pbRecord.time;
        } else {
            // Otherwise try from pb ghost
            pb = Ghost::GetPB();
        }
        return pb;
    }

    void _UpdateUnfinishedRun() {
        if(currentRecord is null) return;
        if(currentRecord.cps.Length == 0) return;
        if(pbRecord !is null) return;
        if(sessionRecord !is null) return;
        if(unfinishedRun !is null && unfinishedRun.cps.Length > currentRecord.cps.Length) return;
        if(unfinishedRun !is null
            && unfinishedRun.cps.Length == currentRecord.cps.Length
            && unfinishedRun.lastCpTime < currentRecord.lastCpTime)
            return;

        // print("saving unfinished run with length=" + currentRecord.cps.Length);
        @unfinishedRun = @currentRecord;
    }

    uint _GetRaceStart() {
        uint raceStart = 0;

        auto terminal = GetApp().CurrentPlayground.GameTerminals[0];
#if TMNEXT
        auto smPlayer = cast<CSmPlayer>(terminal.GUIPlayer);
        auto smScriptPlayer = cast<CSmScriptPlayer>(smPlayer.ScriptAPI);
        raceStart = smScriptPlayer.StartTime;
#elif MP4
        auto scriptPlayer = cast<CTrackManiaPlayer>(terminal.GUIPlayer).ScriptAPI;
        raceStart = scriptPlayer.RaceStartTime;
#elif TURBO
        auto player = cast<CTrackManiaPlayer>(terminal.ControlledPlayer);
        raceStart = player.RaceStartTime;
#endif
        return raceStart;
    }

    uint _GetNow() {
        return GetApp().Network.PlaygroundClientScriptAPI.GameTime;
    }

    uint _GetRaceTime() {
        uint raceStart = _GetRaceStart();
        uint now = _GetNow();

        // print("racetime: " + (now - raceStart));
        return now - raceStart;
    }

    bool _IsBeforeRaceStart() {
        return _GetNow() < _GetRaceTime();
    }

    void Main() {
        Map::HandleRunStart();
    }

    float lastSpeed = 0;
    void Update() {
        if(!Detector::InGame) return;

#if TMNEXT

        // Remember last speed to apply fix when it breaks in snow car switch
        auto state = VehicleState::ViewingPlayerState();
        if(state is null) return;
        auto speed = useWorldSpeed ? state.WorldVel.Length() : state.FrontSpeed;
        speed *= 3.6;
        if(speed != 0)
            lastSpeed = speed;

#endif

#if TMNEXT || MP4
        auto currentMapId = GetApp().RootMap.MapInfo.MapUid;
#elif TURBO
        auto currentMapId = GetApp().Challenge.MapInfo.MapUid;
#endif
        if(mapId == currentMapId) return;

        // Map switch
        mapId = currentMapId;

        @currentRecord = null;
        @unfinishedRun = null;
        @sessionRecord = null;
        currentPB = GetMapPB();
        sessionPB = 0;
        HandleRunStart();
        print("Map switched to " + mapId + ", pb = " + currentPB);
    }

    void HandleRunStart() {
        _UpdateUnfinishedRun();
        @currentRecord = SpeedRecording();
    }

    void HandleCheckpoint() {
#if TMNEXT
        if(_IsBeforeRaceStart()) {
            // print("raceStart: " + _GetRaceTime());
            // print("now: " + _GetNow());
            return;
        }
#endif
        auto state = VehicleState::ViewingPlayerState();
        if(state is null) return;
        auto speed = useWorldSpeed ? state.WorldVel.Length() : state.FrontSpeed;
        speed *= 3.6;
        if(speed == 0) {
            print("Zero speed detected at CP, fixing using last known speed: " + lastSpeed);
            speed = lastSpeed;
        }
        // print("WORLD SPEED = " + state.WorldVel.Length());
        // print("FRONT SPEED = " + state.FrontSpeed);
        GUI::currentSpeed = speed;
        currentRecord.cps.InsertLast(speed);
        currentRecord.lastCpTime = _GetRaceTime();

        float compareSpeed = -1;
        if(pbRecord !is null
            && pbRecord.cps.Length >= currentRecord.cps.Length
            && (compareType == CompareType::PersonalBest
                || compareType == CompareType::PBFallbackSession)) {
            // print("using pb record");
            compareSpeed = pbRecord.cps[currentRecord.cps.Length - 1];
        } else if(sessionRecord !is null
            && sessionRecord.cps.Length >= currentRecord.cps.Length
            && (compareType == CompareType::SessionBest
                || compareType == CompareType::PBFallbackSession)) {
            // print("using session record");
            compareSpeed = sessionRecord.cps[currentRecord.cps.Length - 1];
        } else if(useUnfinishedRuns
            && unfinishedRun !is null
            && unfinishedRun.cps.Length >= currentRecord.cps.Length) {
            // print("using unfinished run");
            compareSpeed = unfinishedRun.cps[currentRecord.cps.Length - 1];
        }

        if(compareSpeed == -1) {
            GUI::hasDiff = false;
        } else {
            GUI::hasDiff = true;
            GUI::difference = speed - compareSpeed;
        }
        GUI::showTime = Time::Now;
    }

    void HandleFinish(uint time, bool isOnline) {
        if(mapId == "") return;
        currentRecord.time = time;
        currentRecord.isOnline = isOnline;
        auto isPB = time <= currentPB || currentPB == 0;
        // print("Map handle finish: " + time + ", online = " + isOnline + ", is PB = " + isPB);

        if(isPB) {
            currentPB = time;
            currentRecord.ToFile(FilePath);
            @pbRecord = currentRecord;
            @unfinishedRun = null;
        }
        if(time <= sessionPB || sessionPB == 0) {
            sessionPB = time;
            @sessionRecord = currentRecord;
            @unfinishedRun = null;
        }
    }

    void ClearPB() {
        Database::Delete(mapId);
        @pbRecord = null;
        @sessionRecord = null;
        @unfinishedRun = null;
    }

}