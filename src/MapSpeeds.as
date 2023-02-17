class MapSpeeds {
    string mapId;
    string jsonFile;
    SpeedRecording@ bestSpeeds = null;
    SpeedRecording@ currentSpeeds = null;

    float cpSpeed = 0;
    int startDrivingTime = 0;
    int pbTime = 0;
    int lastRaceTime = 0;
    int checkingForPB = 0;
    int maxInt = 2147483647;

    MapSpeeds(const string &in mapId) {
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
                        warn("Mismatch between pb and stored speeds time, pb time: " + (pbTime == maxInt ? "NO PB" : tostring(pbTime)) + ", stored speeds time: " + bestSpeeds.time);
                        ClearPB();
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
#if MP4
        cpSpeed = state.FrontSpeed * 3.6;
#else
        cpSpeed = state.WorldVel.Length() * 3.6;
#endif
        currentSpeeds.cps.InsertLast(cpSpeed);
        GUI::currentSpeed = cpSpeed;
        if(bestSpeeds !is null && bestSpeeds.cps.Length >= currentSpeeds.cps.Length) {
            // speed diff is available
            int lastIndex = currentSpeeds.cps.Length - 1;
            GUI::difference = currentSpeeds.cps[lastIndex] - bestSpeeds.cps[lastIndex];
            GUI::hasDiff = true;
        } else {
            GUI::hasDiff = false;
        }
        GUI::showTime = Time::Now;
    }

    void Finish() {
        warn("FINISH");
        auto app = cast<CTrackMania@>(GetApp());
        if(currentSpeeds is null || app.Network is null || app.Network.PlaygroundClientScriptAPI is null) {
            return;
        }
        lastRaceTime = app.Network.PlaygroundClientScriptAPI.GameTime - startDrivingTime;
        // in offline it can take a few ticks for the pb ghost to update
        if(UseGhosts()) {
            checkingForPB = 100;
        }
        CheckForPB();
    }

    void Tick() {
        if(checkingForPB > 0) {
            checkingForPB--;
            CheckForPB();
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

    void CheckForPB() {
        bool newPb = false;
        int pb = keepSync ? pbTime : (bestSpeeds is null ? maxInt : bestSpeeds.time);
        if(!UseGhosts()) {
            if(lastRaceTime < pb) {
                newPb = true;
                pbTime = lastRaceTime;
            }
        } else {
            auto updatedPB = GetMapPB();       
            if(updatedPB < pb) {
                newPb = true;
                pbTime = updatedPB;
            }
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

    int GetMapPB() {
#if TMNEXT
        auto ghost = GetPBGhost();
        return ghost is null || ghost.Result is null ? maxInt : ghost.Result.Time;
#elif TURBO
        return GetGhostTime();
#else
        // print("Getting map pb");
        auto app = cast<CTrackMania>(GetApp());
        CGameCtnPlayground@ playground = cast<CGameCtnPlayground@>(app.CurrentPlayground);
        int time = maxInt;
        if (playground.PlayerRecordedGhost !is null){
            time = playground.PlayerRecordedGhost.RaceTime;
        }
        return time;
#endif
    }

#if TMNEXT
    CGameGhostScript@ GetPBGhost() {
        // Unfinished ghosts have a time of uint(-1), so they won't be picked if the bestTime is
        // initialized to uint(-1)
        auto app = cast<CTrackMania@>(GetApp());
        auto playgroundScript = app.PlaygroundScript;
        if(playgroundScript is null || playgroundScript.DataFileMgr is null) return null;
        uint bestTime = uint(-1);
        CGameGhostScript@ bestGhost = null;
        auto ghosts = playgroundScript.DataFileMgr.Ghosts;
        for(uint i = 0; i < ghosts.Length; i++) {
            auto ghostTime = ghosts[i].Result.Time;
            auto trigram = ghosts[i].Trigram;
            if(trigram == '|' && (ghostTime < bestTime)) {
                bestTime = ghostTime;
                @bestGhost = ghosts[i];
            }
        }
        return bestGhost;
    }
#endif
#if TURBO
    int GetRecordTime() {
        auto playgroundScript = GetApp().PlaygroundScript;
        if(playgroundScript is null || playgroundScript.DataMgr is null) return maxInt;
        auto ghosts = playgroundScript.DataMgr.Records;
        auto lastGhost = ghosts[ghosts.Length - 1];
        if(lastGhost.Medal != CGameHighScore::EMedal::None) {
            return maxInt;
        }
        return lastGhost.Time;
    }
    int GetGhostTime() {
        auto playgroundScript = GetApp().PlaygroundScript;
        if(playgroundScript is null || playgroundScript.DataMgr is null) {
            warn("no pgs or datamgr yet");
            return maxInt;
        }
        auto ghosts = playgroundScript.DataMgr.Ghosts;
        if(ghosts.Length == 0) {
            warn("No ghosts yet");
            return maxInt;
        }
        auto lastGhost = ghosts[ghosts.Length - 1];
        print("Last ghost data state: " + lastGhost.DataState);
        if(lastGhost.Nickname.EndsWith("Medal")) {
            return maxInt;
        }
        auto result = lastGhost.RaceResult.Time;
        if(result == -1) {
            return maxInt;
        }
        return result;
    }
#endif
};