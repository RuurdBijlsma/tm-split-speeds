namespace Map {
    string mapId = "";
    SpeedRecording@ pbRecord = null;
    SpeedRecording@ sessionRecord = null;
    SpeedRecording@ currentRecord = null;

    uint CurrentPB = 0;

    string get_FilePath() {
        return IO::FromStorageFolder(mapId + ".json");
    }

    uint GetMapPB() {
        uint pb = 0;
        print("FILEPATH: " + FilePath);

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

        CurrentPB = GetMapPB();
        print("Map switched to " + mapId + ", pb = " + CurrentPB);
    }

    void HandleRunStart() {
        print("Run starts now");
        @currentRecord = SpeedRecording();
    }

    void HandleCheckpoint() {
        auto state = VehicleState::ViewingPlayerState();
        if(state is null) return;
        auto speed = true ? state.WorldVel.Length() : state.FrontSpeed;
        speed *= 3.6;
        GUI::currentSpeed = speed;
        float compareSpeed = -1;
        if(pbRecord !is null && pbRecord.cps.Length > currentRecord.cps.Length) {
            compareSpeed = pbRecord.cps[currentRecord.cps.Length];
        }
        currentRecord.cps.InsertLast(speed);
        if(compareSpeed == -1) {
            GUI::hasDiff = false;
            print("No pb speed, current speed = " + speed);
        } else {
            GUI::hasDiff = true;
            GUI::difference = speed - compareSpeed;
            print("speed = " + speed + ", diff = " + (speed - compareSpeed));
        }
        GUI::showTime = Time::Now;
    }

    void HandleFinish(uint time, bool isOnline) {
        currentRecord.time = time;
        currentRecord.isOnline = isOnline;
        print("Map handle finish: " + time + ", online = " + isOnline);

        if(time <= CurrentPB || CurrentPB == 0) {
            CurrentPB = time;
            currentRecord.ToFile(FilePath);
            @pbRecord = currentRecord;
        }
    }

    void ClearPB() {
        print("Deleting pb: " + FilePath);
        IO::Delete(FilePath);
        @pbRecord = null;
        @sessionRecord = null;
    }

}