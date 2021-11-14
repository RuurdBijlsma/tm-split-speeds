class Speeder{
    bool inGame = false;
    bool strictMode = false;

    string curMap = "";

    uint preCPIdx = 0;
    uint curCP = 0;
    uint maxCP = 0;
    bool handledFinish = false;
    
    MapSpeeds currentSpeeds = MapSpeeds();
    MapSpeeds bestSpeeds = MapSpeeds();
    uint bestTime = 0;
    uint lapCount = 0;
    uint lastRaceTime = 0;

    void Init(){
        print("Initialize speeder");
    }

    void Tick(){
        auto app = GetApp();
        auto playground = cast<CSmArenaClient>(app.CurrentPlayground);
        auto terminal = playground.GameTerminals[0];
        auto uiSequence = terminal.UISequence_Current;

        if((uiSequence == CGamePlaygroundUIConfig::EUISequence::Finish) && !handledFinish){
            auto pb = bestSpeeds.getPb();
            handledFinish = true;
            if(lastRaceTime < pb || pb == 0){
                bestSpeeds = currentSpeeds;
                currentSpeeds.ToFile(lastRaceTime);
                print('New PB! time = ' + lastRaceTime);
            }
        }
        if(uiSequence != CGamePlaygroundUIConfig::EUISequence::Finish){
            handledFinish = false;
        }

        auto player = cast<CSmPlayer>(terminal.GUIPlayer);

        if(playground is null
            || playground.Arena is null
            || playground.Map is null
            || playground.GameTerminals.Length <= 0
            || uiSequence != CGamePlaygroundUIConfig::EUISequence::Playing
            || player is null) {
            inGame = false;
            return;
        }

        if(player.ScriptAPI is null) {
            inGame = false;
            return;
        }

        lastRaceTime = player.ScriptAPI.CurrentRaceTime;

        if(player.CurrentLaunchedRespawnLandmarkIndex == uint(-1)) {
            // sadly, can't see CPs of spectated players any more
            inGame = false;
            return;
        }

        MwFastBuffer<CGameScriptMapLandmark@> landmarks = playground.Arena.MapLandmarks;

        if(!inGame && (curMap != playground.Map.IdName || GetApp().Editor !is null)) {
            // keep the previously-determined CP data, unless in the map editor
            curMap = playground.Map.IdName;
            bestSpeeds = MapSpeeds(curMap);
            currentSpeeds = MapSpeeds(curMap, false);
            print("Map change! Current PB = " + bestSpeeds.getPb());
            if(playground.Map.TMObjective_IsLapRace)
                lapCount = playground.Map.TMObjective_NbLaps;
            else
                lapCount = 1;

            preCPIdx = player.CurrentLaunchedRespawnLandmarkIndex;
            curCP = 0;
            maxCP = 0;
            strictMode = true;

            array<int> links = {};
            for(uint i = 0; i < landmarks.Length; i++) {
                // if(waypoint is start or finish or multilap, it's not a checkpoint)
                if(landmarks[i].Waypoint is null || landmarks[i].Waypoint.IsFinish || landmarks[i].Waypoint.IsMultiLap)
                    continue;
                // we have a CP, but we don't know if it is Linked or not
                if(landmarks[i].Tag == "Checkpoint") {
                    maxCP++;
                } else if(landmarks[i].Tag == "LinkedCheckpoint") {
                    if(links.Find(landmarks[i].Order) < 0) {
                        maxCP++;
                        links.InsertLast(landmarks[i].Order);
                    }
                } else {
                    // this waypoint looks like a CP, acts like a CP, but is not called a CP.
                    if(strictMode) {
                        warn("The current map, " + string(playground.Map.MapName) + " (" + playground.Map.IdName + "), is not compliant with checkpoint naming rules."
                        + " If the CP count for this map is inaccurate, please report this map to Phlarx#1765 on Discord.");
                    }
                    maxCP++;
                    strictMode = false;
                }
            }
        }

        inGame = true;

        if(preCPIdx != player.CurrentLaunchedRespawnLandmarkIndex && 
            landmarks.Length > player.CurrentLaunchedRespawnLandmarkIndex) {
            preCPIdx = player.CurrentLaunchedRespawnLandmarkIndex;

            // total cp count is all cps + the start/finish counts as 1 per lap
            auto totalCpCount = lapCount * (maxCP + 1);
            print("YEP CP");

            auto vis = GetVehicleVis(app);
            if(vis is null)
                return;
            float speed = vis.AsyncState.FrontSpeed* 3.6f;

            if(landmarks[preCPIdx].Waypoint is null) {
                curCP = 0;
                print("Start");
            }else{
                curCP++;
            }
            auto pbSpeed = bestSpeeds.GetCp(curCP);
            print("CP " + curCP + ", speed = " + speed + ", pb speed = " + pbSpeed + ', diff = ' + (speed - pbSpeed));
            currentSpeeds.SetCp(curCP, speed);
        }
    }

    CSmPlayer@ GetViewingPlayer() {
        auto playground = GetApp().CurrentPlayground;
        if (playground is null || playground.GameTerminals.Length != 1) {
            return null;
        }
        return cast<CSmPlayer>(playground.GameTerminals[0].GUIPlayer);
    }

    CSceneVehicleVis@ GetVehicleVis(CGameCtnApp@ app) {
        auto sceneVis = app.GameScene;
        if (sceneVis is null) {
            print("Scene vis is null");
            return null;
        }
        // print("Scene vis is not null");
        CSceneVehicleVis@ vis = null;

        auto player = GetViewingPlayer();
        if (player !is null) {
            @vis = Vehicle::GetVis(sceneVis, player);
        } else {
            @vis = Vehicle::GetSingularVis(sceneVis);
        }

        if (vis is null) {
            print("Vis is null");
            return null;
        }
        // print("Vis is not null");
        return vis;
    }
}