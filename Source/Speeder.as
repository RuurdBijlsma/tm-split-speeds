// Checkpoint counting logic by Phlarx:
// https://github.com/Phlarx/tm-checkpoint-counter

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
    GUI gui = GUI();
    uint lastRaceTime = 0;
    uint64 showStartTime = 0;
    CGameCtnApp@ app = GetApp();

    void Tick(){
        auto playground = cast<CSmArenaClient>(app.CurrentPlayground);

        if(playground is null
            || playground.Arena is null
            || playground.Map is null
            || playground.GameTerminals.Length <= 0){
                inGame=false;
                return;
            }

        auto terminal = playground.GameTerminals[0];
        auto player = cast<CSmPlayer>(terminal.GUIPlayer);
        auto uiSequence = terminal.UISequence_Current;

        if(uiSequence == CGamePlaygroundUIConfig::EUISequence::Finish && !handledFinish && player !is null){
            // Show ui for 1s after finishing
            showStartTime = Time::get_Now() - 2000;
            auto pb = bestSpeeds.getPb();
            handledFinish = true;
            if(lastRaceTime < pb || pb == 0){
                currentSpeeds.ToFile(lastRaceTime);
                bestSpeeds = currentSpeeds;
                currentSpeeds = MapSpeeds(curMap, false);
                // print('New PB! time = ' + lastRaceTime);
            }
        }

        uint64 nowTime = Time::get_Now();
        gui.guiHidden = playground.Interface !is null && Dev::GetOffsetUint32(app.CurrentPlayground.Interface, 0x1C) == 0;
        gui.showDiff = showStartTime + 3000 > nowTime;

        if(uiSequence != CGamePlaygroundUIConfig::EUISequence::Finish){
            handledFinish = false;
        }

        if(uiSequence != CGamePlaygroundUIConfig::EUISequence::Playing || player is null) {
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
            print("[SplitSpeeds] Map change! Current PB = " + bestSpeeds.getPb());

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

            // print("CP YEP, " + preCPIdx);
            if(landmarks[preCPIdx].Waypoint is null) {
                curCP = 0;
            }else{
                curCP++;
            }

            auto vis = GetVehicleVis(app);
            if(vis is null){
                return;
            }
            float speed = vis.AsyncState.WorldVel.Length() * 3.6f;
            gui.currentSpeed = speed;
            if(bestSpeeds.HasCp(curCP)){
                auto pbSpeed = bestSpeeds.GetCp(curCP);
                gui.hasDiff = true;
                gui.difference = speed - pbSpeed;
                // print("cp = " + curCP + ", curspeed = " + speed + ", pb speed = " + pbSpeed);
            }else{
                gui.hasDiff = false;
                // print("cp = " + curCP + ", curspeed = " + speed + ", NO PB FOUND");
            }
            if(curCP != 0)
                showStartTime = nowTime;
            else
                showStartTime = 0;
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
            return null;
        }
        CSceneVehicleVis@ vis = null;

        auto player = GetViewingPlayer();
        if (player !is null) {
            @vis = Vehicle::GetVis(sceneVis, player);
        } else {
            @vis = Vehicle::GetSingularVis(sceneVis);
        }

        if (vis is null) {
            return null;
        }
        return vis;
    }
}