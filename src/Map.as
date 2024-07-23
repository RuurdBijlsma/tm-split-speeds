namespace Map {
    string mapId = "";
    SpeedRecording@ pbRecord = null;
    SpeedRecording@ sessionRecord = null;
    SpeedRecording@ currentRecord = null;
    SpeedRecording@ unfinishedRun = null;

    uint sessionPB = 0;
    uint currentPB = 0;

    string get_FilePath() {
        return IO::FromStorageFolder(mapId + ".json");
    }

    uint GetMapPB() {
        uint pb = 0;

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

        @unfinishedRun = null;
        @sessionRecord = null;
        currentPB = GetMapPB();
        sessionPB = 0;
        print("Map switched to " + mapId + ", pb = " + currentPB);
    }

    void HandleRunStart() {
        if(currentRecord !is null
            && currentRecord.cps.Length > 0
            && pbRecord is null
            && sessionRecord is null
            && (unfinishedRun is null || unfinishedRun.cps.Length < currentRecord.cps.Length)) {
            // print("saving unfinished run with lenght=" + currentRecord.cps.Length);
            @unfinishedRun = @currentRecord;
        }
        @currentRecord = SpeedRecording();
    }

    void HandleCheckpoint() {
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

        float compareSpeed = -1;
        if(pbRecord !is null
            && pbRecord.cps.Length >= currentRecord.cps.Length
            && (compareType == CompareType::PersonalBest
                || compareType == CompareType::PBFallbackSession)) {
            print("using pb record");
            compareSpeed = pbRecord.cps[currentRecord.cps.Length - 1];
        } else if(sessionRecord !is null
            && sessionRecord.cps.Length >= currentRecord.cps.Length
            && (compareType == CompareType::SessionBest
                || compareType == CompareType::PBFallbackSession)) {
            print("using session record");
            compareSpeed = sessionRecord.cps[currentRecord.cps.Length - 1];
        } else if(useUnfinishedRuns
            && unfinishedRun !is null
            && unfinishedRun.cps.Length >= currentRecord.cps.Length) {
            print("using unfinished run");
            compareSpeed = unfinishedRun.cps[currentRecord.cps.Length - 1];
        }

        if(compareSpeed == -1) {
            GUI::hasDiff = false;
        } else {
            GUI::hasDiff = true;
            GUI::difference = speed - compareSpeed;
        }
        GUI::showTime = Time::Now;

        // auto cps = "" + currentRecord.cps[0];
        // for(uint i = 1; i < currentRecord.cps.Length; i++){
        //     cps = cps + ", " + currentRecord.cps[i];
        // }
        // print("cps: " + cps);
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
        }
        if(time <= sessionPB || sessionPB == 0) {
            sessionPB = time;
            @sessionRecord = currentRecord;
        }
    }

    void ClearPB() {
        print("Deleting pb: " + FilePath);
        IO::Delete(FilePath);
        @pbRecord = null;
        @sessionRecord = null;
        @unfinishedRun = null;
    }

}