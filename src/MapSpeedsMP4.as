#if MP4
class MapSpeedsMP4 {
    string mapId;
    string jsonFile;
    SpeedRecording@ currentSpeeds = null;
    // PB speeds
    SpeedRecording@ bestSpeeds = null;
    // Best speeds since map load
    SpeedRecording@ sessionBest = SpeedRecording();

    float cpSpeed = 0;
    int startDrivingTime = 0;
    int pbTime = 0;
    int lastRaceTime = 0;
    int checkingForPB = 0;
    int maxInt = 2147483647;

    MapSpeedsMP4(const string &in mapId) {
        // set map id, load speeds / speed pb for current map, find checkpoints
        this.mapId = mapId;
        pbTime = GetMapPB();
    }

    void InitializeFiles() {
        string baseFolder = IO::FromDataFolder('');
        string folder = baseFolder + 'splitspeeds\\';
        jsonFile = folder + mapId + '.json';
        if(!IO::FolderExists(folder)) {
            IO::CreateFolder(folder);
            print("Created folder: " + folder);
        }
        if(IO::FileExists(jsonFile)) {
            @bestSpeeds = SpeedRecording::FromFile(jsonFile);
            if(bestSpeeds is null) {
                warn("Something went wrong while loading " + jsonFile);
            } else {
                if(bestSpeeds.time == 0) ClearPB();
                if(keepSync && UseGhosts() && pbTime != 0) {
                    if((bestSpeeds.isOnline && Math::Abs(bestSpeeds.time - pbTime) > 50) || (!bestSpeeds.isOnline && bestSpeeds.time != pbTime)) {
                        // mismatch between best speeds and pb time
                        // warn("Mismatch between pb and stored speeds time, pb time: " + (pbTime == maxInt ? "NO PB" : tostring(pbTime)) + ", stored speeds time: " + bestSpeeds.time);
                        // ClearPB();
                        warn("Mismatch between ghost and stored speeds time, pb time: " + (pbTime == maxInt ? "NO PB" : tostring(pbTime)) + ", stored speeds time: " + bestSpeeds.time);
                        print("Not loading best speed splits");
                        @bestSpeeds = null;
                    }
                }
                if(!UseGhosts() && bestSpeeds.time != 0) {
                    // Online we can't get pb time from ghost, so we just have to trust the json file is correct
                    pbTime = bestSpeeds.time;
                }
            }
        }
        print("Enter map: " + mapId + ", map pb = " + pbTime + ", stored speeds time: " + (bestSpeeds is null ? "not stored yet" : tostring(bestSpeeds.time)));
    }

    // ----------- EVENTS -------------

    void StartDriving() {
        auto app = cast<CTrackMania@>(GetApp());
        if(app.Network is null || app.Network.PlaygroundClientScriptAPI is null) return;
        @currentSpeeds = SpeedRecording();
        startDrivingTime = app.Network.PlaygroundClientScriptAPI.GameTime;
    }

    void Retire() {
        GUI::showTime = 0;
    }

    void Checkpoint() {
        if(currentSpeeds is null) return;
        auto state = VehicleState::ViewingPlayerState();
        if(state is null) return;
        if(useWorldSpeed) {
            cpSpeed = state.WorldVel.Length() * 3.6;
        } else {
            cpSpeed = state.FrontSpeed * 3.6;
        }
        currentSpeeds.cps.InsertLast(cpSpeed);
        GUI::currentSpeed = cpSpeed;

        auto compareTo = useSessionBestNotPB ? sessionBest : bestSpeeds;

        if(compareTo !is null && compareTo.cps.Length >= currentSpeeds.cps.Length) {
            // speed diff is available
            int lastIndex = currentSpeeds.cps.Length - 1;
            GUI::difference = currentSpeeds.cps[lastIndex] - compareTo.cps[lastIndex];
            GUI::hasDiff = true;
        } else {
            GUI::hasDiff = false;
        }
        GUI::showTime = Time::Now;
    }

    void Tick() {
        if(checkingForPB > 0) {
            checkingForPB--;
            HandleFinish(123123123);
        }
        // print("Map PB" + GetMapPB());
    }

    // ------------- METHODS --------------

    bool UseGhosts() {
        // only use ghosts in single player and not editor, if keepsync is false also dont use ghosts, because otherwise we can't get proper last race time
        if(!keepSync) return false;
        auto app = cast<CTrackMania@>(GetApp());
        bool ghost = app.PlaygroundScript !is null && app.Editor is null;
        return ghost;
    }

    void ClearPB() {
        print("Deleting pb: " + jsonFile);
        IO::Delete(jsonFile);
        @bestSpeeds = null;
    }

    void HandleFinish(int finishTime) {
        bool newPb = false;
        int pb = keepSync ? GetMapPB() : (bestSpeeds is null ? maxInt : bestSpeeds.time);

        lastRaceTime = finishTime;
        UpdateSBSplits();

        if(finishTime <= pb) {
            newPb = true;
            pbTime = finishTime;
        }

        if(newPb) {
            checkingForPB = 0;
            print("NEW PB!: " + pbTime);
            if(currentSpeeds !is null) {
                @bestSpeeds = currentSpeeds;
                bestSpeeds.time = pbTime;
                bestSpeeds.ToFile(jsonFile, pbTime, !UseGhosts());
            }
        }
    }

    void UpdateSBSplits() {
        if (sessionBest.time <= 0 || lastRaceTime < sessionBest.time) {
            // new session best
            @sessionBest = currentSpeeds;
            sessionBest.time = lastRaceTime;
        }
    }

    int GetMapPB() {
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
};
#endif
