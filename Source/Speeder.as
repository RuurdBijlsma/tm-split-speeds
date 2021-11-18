// Checkpoint counting logic by Phlarx:
// https://github.com/Phlarx/tm-checkpoint-counter

[Setting name="Keep synced with pb ghost" category="General"]
bool keepSync = true;

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
    uint checkForNewPb = 0;
    uint64 showStartTime = 0;
    CGameCtnApp@ app = GetApp();
    uint pbTime = 0;
    bool isOnline = false;
    bool isEditor = false;
    uint lastRaceTime = 0;
    string playerName = '';

    void Tick(){
        auto playground = cast<CSmArenaClient>(app.CurrentPlayground);

        uint64 nowTime = Time::get_Now();
        gui.guiHidden = playground is null || 
            playground.Interface is null || 
            Dev::GetOffsetUint32(playground.Interface, 0x1C) == 0;
        gui.showDiff = showStartTime + 3000 > nowTime;

        if(playground is null
            || playground.Arena is null
            || playground.Map is null
            || playground.GameTerminals.Length <= 0){
                checkForNewPb = 0;
                inGame = false;
                return;
            }

        auto terminal = playground.GameTerminals[0];
        auto player = cast<CSmPlayer>(terminal.GUIPlayer);
        auto uiSequence = terminal.UISequence_Current;

        // Player finishes map
        if(uiSequence == CGamePlaygroundUIConfig::EUISequence::Finish && !handledFinish && player !is null){
            handledFinish = true;
            // Show ui for 1s after finishing
            showStartTime = Time::get_Now() - 2000;
            // check the next 1500 ticks every 10th tick if new pb gets registered
            checkForNewPb = 150;
        }

        if(checkForNewPb > 0){
            checkForNewPb--;
            if(isOnline || isEditor){
                uint filePb = bestSpeeds.GetPb();
                if(lastRaceTime < filePb || filePb == 0){
                    currentSpeeds.ToFile(lastRaceTime);
                    bestSpeeds = currentSpeeds;
                    currentSpeeds = MapSpeeds(curMap, false);
                    checkForNewPb = 0;
                }
            }else{
                auto lastGhost = GetPbGhost();
                auto actualPbTime = keepSync ? pbTime : bestSpeeds.GetPb();
                if(lastGhost !is null && (lastGhost.Result.Time < actualPbTime || actualPbTime == 0)){
                    pbTime = lastGhost.Result.Time;
                    currentSpeeds.ToFile(lastGhost.Result.Time);
                    bestSpeeds = currentSpeeds;
                    currentSpeeds = MapSpeeds(curMap, false);
                    checkForNewPb = 0;
                }
            }
        }

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

        isEditor = app.Editor !is null;
        if(!inGame && (curMap != playground.Map.IdName || isEditor)) {
            // keep the previously-determined CP data, unless in the map editor
            curMap = playground.Map.IdName;
            bestSpeeds = MapSpeeds(curMap);
            currentSpeeds = MapSpeeds(curMap, false);
            isOnline = app.PlaygroundScript is null;
            playerName = player.User.Name;
            if(isOnline || isEditor){
                auto pb = bestSpeeds.GetPb();
                if(pb == 0)
                    print("[SplitSpeeds] Map change! No PB yet!");
                else
                    print("[SplitSpeeds] Map change! PB = " + pb);
            }else{
                auto pbGhost = GetPbGhost();
                pbTime = pbGhost is null || pbGhost.Result is null ? 0 : pbGhost.Result.Time;
                if(pbGhost is null)
                    print("[SplitSpeeds] Map change! No PB yet!");
                else
                    print("[SplitSpeeds] Map change! Current PB = " + pbTime);
                if(pbTime != bestSpeeds.GetPb() && keepSync){
                    print("[SplitSpeeds] Stored speeds out of sync with personal best ghost, removing stored speeds");
                    bestSpeeds.Clear();
                }
            }

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
            } else {
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
            } else {
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

    CGameGhostScript@ GetPbGhost(){
        auto pgScript = cast<CSmArenaRulesMode@>(app.PlaygroundScript);
        uint bestTime = 4000000000;
        if(pgScript !is null && pgScript.DataFileMgr !is null){
            auto ghosts = pgScript.DataFileMgr.Ghosts;
            CGameGhostScript@ bestGhost = null;
            for(uint i = 0; i < ghosts.Length; i++){
                auto ghostTime = ghosts[i].Result.Time;
                auto name = ghosts[i].Nickname;
                if(name.EndsWith("Personal best") && ghostTime < bestTime){
                    bestTime = ghostTime;
                    @bestGhost = ghosts[i];
                }
            }
            if(bestGhost is null){
                // print("pb ghost = null");
                return null;
            }
            // print("pb (" + bestGhost.Id.Value + ") = " + bestGhost.Nickname + " t = " + bestGhost.Result.Time + " rslt id = " + bestGhost.Result.Id.Value + " spwn landmark id = " + bestGhost.Result.SpawnLandmarkId.Value);
            return bestGhost;
        }
        return null;
    }

#if TMNEXT
	CSmPlayer@ GetViewingPlayer()
	{
		auto playground = GetApp().CurrentPlayground;
		if (playground is null || playground.GameTerminals.Length != 1) {
			return null;
		}
		return cast<CSmPlayer>(playground.GameTerminals[0].GUIPlayer);
	}
#elif TURBO
	CGameMobil@ GetViewingPlayer()
	{
		auto playground = cast<CTrackManiaRace>(GetApp().CurrentPlayground);
		if (playground is null) {
			return null;
		}
		return playground.LocalPlayerMobil;
	}
#elif MP4
	CGamePlayer@ GetViewingPlayer()
	{
		auto playground = GetApp().CurrentPlayground;
		if (playground is null || playground.GameTerminals.Length != 1) {
			return null;
		}
		return playground.GameTerminals[0].GUIPlayer;
	}
#endif

    CSceneVehicleVis@ GetVehicleVis(CGameCtnApp@ app) {
#if !MP4
		auto sceneVis = app.GameScene;
		if (sceneVis is null) {
			return null;
		}
		CSceneVehicleVis@ vis = null;
#else
		CGameScene@ sceneVis = null;
		CSceneVehicleVisInner@ vis = null;
#endif

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