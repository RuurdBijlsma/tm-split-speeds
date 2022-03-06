class MapSpeeds {
    string mapId;
    string jsonFile;
    SpeedRecording@ bestSpeeds = null;
    SpeedRecording@ currentSpeeds = null;

    float cpSpeed = 0;
    float tickSpeed = 0;
    int startDrivingTime = 0;
    int pbTime = 0;
    int lastRaceTime = 0;
    int checkingForPB = 0;

    MapSpeeds(string mapId) {
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
                        warn("Mismatch between pb and stored speeds time, pb time: " + pbTime + ", stored speeds time: " + bestSpeeds.time);
                        ClearPB();
                    }
                }
                if(!UseGhosts() && bestSpeeds.time != 0) {
                    // Online we can't get pb time from ghost, so we just have to trust the json file is correct
                    pbTime = bestSpeeds.time;
                }
            }
        }
        print("Enter map: " + mapId + ", pb = " + pbTime);
    }

    // ----------- EVENTS -------------

    void StartDriving() {
        @currentSpeeds = SpeedRecording();
        startDrivingTime = app.Network.PlaygroundClientScriptAPI.GameTime;
    }

    void Retire() {}

    void Checkpoint() {
        if(currentSpeeds is null) return;
        auto state = VehicleState::ViewingPlayerState();
        if(state is null) return;
        cpSpeed = state.WorldVel.Length() * 3.6;
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
        if(currentSpeeds is null) return;
        lastRaceTime = app.Network.PlaygroundClientScriptAPI.GameTime - startDrivingTime;
        // in offline it can take a few ticks for the pb ghost to update
        if(UseGhosts()){
            checkingForPB = 30;
        }
        CheckForPB();
    }

    void Tick() {
        if(checkingForPB > 0) {
            checkingForPB--;
            CheckForPB();
        }

        if(player !is null 
            && player.ScriptAPI !is null
            && player.ScriptAPI.Post == CSmScriptPlayer::EPost::CarDriver
            && currentSpeeds !is null
            && terminal !is null
            && terminal.UISequence_Current == CGamePlaygroundUIConfig::EUISequence::Playing) {
            // driving
            auto state = VehicleState::ViewingPlayerState();
            if(state is null) return;
            tickSpeed = state.WorldVel.Length() * 3.6;
            currentSpeeds.ticks.InsertLast(tickSpeed);
        }
    }

    // ------------- METHODS --------------

    bool UseGhosts() {
        // only use ghosts in single player and not editor
        bool ghost = playgroundScript !is null && app.Editor is null;
        print("Use ghost? " + ghost);
        return ghost;
    }

    void ClearPB() {
        print("Deleting pb: " + jsonFile);
        IO::Delete(jsonFile);
        @bestSpeeds = null;
    }

    void CheckForPB() {
        bool pb = false;
        if(!UseGhosts()) {
            if(lastRaceTime < pbTime) {
                pb = true;
                pbTime = lastRaceTime;
            }
        } else {
            auto updatedPB = GetMapPB();
            if(updatedPB < pbTime) {
                pb = true;
                pbTime = updatedPB;
            }
        }
        if(pb) {
            checkingForPB = 0;
            print("PB!: " + pbTime);
            @bestSpeeds = currentSpeeds;
            bestSpeeds.ToFile(jsonFile, pbTime, !UseGhosts());
        }
    }

    int GetMapPB() {
        // online works in offline, otherwise returns 0
        auto ghost = GetPBGhost();
        return ghost is null || ghost.Result is null ? 2147483647 : ghost.Result.Time;
    }

    CGameGhostScript@ GetPBGhost() {
        // Unfinished ghosts have a time of uint(-1), so they won't be picked if the bestTime is
        // initialized to uint(-1)
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
};