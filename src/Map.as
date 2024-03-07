namespace Map {
    string mapId = "";
    SpeedRecording@ pbRecord = null;
    SpeedRecording@ sessionRecord = null;
    SpeedRecording@ currentRecord = null;

    uint sessionPB = 0;
    uint currentPB = 0;

    string get_FilePath() {
        return IO::FromStorageFolder(mapId + ".json");
    }

    uint GetMapPB() {
        uint pb = 0;

        if(IO::FileExists(FilePath)) {
            // First try get PB from speedsplit file:
            @pbRecord = SpeedRecording::FromFile(FilePath);
            pb = pbRecord.time;
        } else {
            @pbRecord = null;
            // Otherwise try from pb ghost
            pb = Ghost::GetPB();
        }
        return pb;
    }

    void Main() {
        Map::HandleRunStart();
    }

    void Update() {
        if(!Detector::InGame) return;

        auto currentMapId = GetApp().RootMap.MapInfo.MapUid;
        if(mapId == currentMapId) return;

        // Map switch
        mapId = currentMapId;

        @sessionRecord = null;
        currentPB = GetMapPB();
        sessionPB = 0;
        print("Map switched to " + mapId + ", pb = " + currentPB);
    }

    void HandleRunStart() {
        @currentRecord = SpeedRecording();
    }

    void HandleCheckpoint() {
        auto state = VehicleState::ViewingPlayerState();
        if(state is null) return;
        auto speed = useWorldSpeed ? state.WorldVel.Length() : state.FrontSpeed;
        speed *= 3.6;
        // print("WORLD SPEED = " + state.WorldVel.Length());
        // print("FRONT SPEED = " + state.FrontSpeed);
        GUI::currentSpeed = speed;

        float compareSpeed = -1;
        if(compareType == CompareType::PersonalBest) {
            if(pbRecord !is null && pbRecord.cps.Length > currentRecord.cps.Length) {
                compareSpeed = pbRecord.cps[currentRecord.cps.Length];
            }
        } else if(compareType == CompareType::SessionBest) {
            if(sessionRecord !is null && sessionRecord.cps.Length > currentRecord.cps.Length) {
                compareSpeed = sessionRecord.cps[currentRecord.cps.Length];
            }
        }
        currentRecord.cps.InsertLast(speed);
        if(compareSpeed == -1) {
            GUI::hasDiff = false;
        } else {
            GUI::hasDiff = true;
            GUI::difference = speed - compareSpeed;
        }
        GUI::showTime = Time::Now;
    }

    void HandleFinish(uint time, bool isOnline) {
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
    }

}