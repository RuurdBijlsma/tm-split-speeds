// Checkpoint counting logic by Phlarx:
// https://github.com/Phlarx/tm-checkpoint-counter

[Setting name="Delete speeds when out of sync with PB ghost" category="General"]
bool keepSync = true;

class Speeder{
    bool inGame = false;
    bool strictMode = false;

    string curMap = "";
    uint preCPIdx = 0;
    uint curCP = 0;
    uint maxCP = 0;
    bool handledFinish = false;
    
    MapSpeeds@ currentSpeeds = MapSpeeds();
    MapSpeeds@ bestSpeeds = MapSpeeds();
    GUI gui = GUI();
    uint64 showStartTime = 0;
    CGameCtnApp@ app = GetApp();
    uint pbTime = 0;
    bool isOnline = false;
    bool isEditor = false;
    string playerName = '';
    uint checkingForPb = 0;
    bool retireHandled = false;
    uint raceStartTime = 0;

    void ClearPB(){
        bestSpeeds.Clear();
        @bestSpeeds = MapSpeeds(curMap);
    }

    void Tick() {
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
                inGame = false;
                return;
            }

        auto terminal = playground.GameTerminals[0];
        auto player = cast<CSmPlayer>(terminal.GUIPlayer);
        auto uiSequence = terminal.UISequence_Current;

        // Player finishes map
        if(uiSequence == CGamePlaygroundUIConfig::EUISequence::Finish && !handledFinish && player !is null) {
            handledFinish = true;
            // Show ui for 1s after finishing
            showStartTime = Time::get_Now() - 2000;
            // check the next 1500 ticks every 10th tick if new pb gets registered
            currentSpeeds.SetFinished(true);
            checkingForPb = 10;
        }

        if(checkingForPb > 0) {
            checkingForPb--;
            if(player !is null) {
                CheckForPb(player, true);
            } else {
                print("Player is null while checking for pb!");
            }
        }

        if(uiSequence != CGamePlaygroundUIConfig::EUISequence::Finish) {
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
            @bestSpeeds = MapSpeeds(curMap);

            TriggerRestart(player);
            isOnline = app.PlaygroundScript is null;
            playerName = player.User.Name;
            if(isOnline || isEditor){
                auto pb = bestSpeeds.GetPb();
                if(pb == 0)
                    print("Map change ("+curMap+")! No PB yet!");
                else
                    print("Map change ("+curMap+")! PB = " + pb);
            } else {
                auto pbGhost = GetPbGhost();
                pbTime = pbGhost is null || pbGhost.Result is null ? 0 : pbGhost.Result.Time;
                if(pbGhost is null)
                    print("Map change ("+curMap+")! No PB yet!");
                else
                    print("Map change ("+curMap+")! Current PB = " + pbTime);
                if(pbTime != bestSpeeds.GetPb()){
                    print("Stored speeds ("+bestSpeeds.GetPb()+") out of sync with personal best ghost ("+pbTime+")");
                    if(keepSync){
                        print("Removing stored speeds to keep speed splits in sync with PB");
                        ClearPB();
                    }
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
                        warn("The current map, " + string(playground.Map.MapName) + " (" + playground.Map.IdName + "), is not compliant with checkpoint naming rules.");
                    }
                    maxCP++;
                    strictMode = false;
                }
            }
        }

        auto post = player.ScriptAPI.Post;
        if(!retireHandled && post == CSmScriptPlayer::EPost::Char){
            retireHandled = true;
            TriggerRestart(player);
        }else if(retireHandled && post == CSmScriptPlayer::EPost::CarDriver){
            // Driving
            retireHandled = false;
        }

        inGame = true;
        if(preCPIdx != player.CurrentLaunchedRespawnLandmarkIndex && 
            landmarks.Length > player.CurrentLaunchedRespawnLandmarkIndex) {
            preCPIdx = player.CurrentLaunchedRespawnLandmarkIndex;
            auto isStart = landmarks[preCPIdx].Waypoint is null;
            if(isStart){
                return;
            }
            if(landmarks[preCPIdx].Waypoint !is null) 
                curCP++;

            auto vis = GetVehicleVis(app);
            if(vis is null)
                return;

            float speed = vis.AsyncState.WorldVel.Length() * 3.6f;
            gui.currentSpeed = speed;
            if(bestSpeeds.HasCp(curCP)){
                auto pbSpeed = bestSpeeds.GetCp(curCP);
                gui.hasDiff = true;
                gui.difference = speed - pbSpeed;
            } else {
                gui.hasDiff = false;
            }
            if(curCP != 0)
                showStartTime = nowTime;
            else
                showStartTime = 0;
            currentSpeeds.SetCp(curCP, speed);
        }
    }

    uint GetRaceTime(CSmPlayer@ player){
        if(player !is null){
            auto now = app.Network.PlaygroundClientScriptAPI.GameTime;
            return now - raceStartTime;
        }
        return 0;
    }

    void TriggerRestart(CSmPlayer@ player){
        // Waiting at start
        if(curCP <= maxCP) {
            currentSpeeds.SetFinished(false);
            CheckForPb(player);
            @currentSpeeds = MapSpeeds(curMap, false);
        }
        
        raceStartTime = player.ScriptAPI.StartTime;
        curCP = 0;
    }

    void CheckForPb(CSmPlayer@ player, bool onlyFinishedGhosts = false){
        if(curCP == 0) 
            return;

        auto compareCps = !bestSpeeds.GetFinished() || !currentSpeeds.GetFinished();
        auto playground = cast<CSmArenaClient>(app.CurrentPlayground);
        auto isRightMap = playground !is null && playground.Map !is null && currentSpeeds.mapId == playground.Map.IdName;
        if(isOnline || isEditor){
            uint filePb = bestSpeeds.GetPb();
            uint lastRaceTime = GetRaceTime(player);
            // If finished use pb time to check for pb, else use cp count to check for pb
            if(!compareCps && (lastRaceTime < filePb || filePb == 0)
             || (compareCps && curCP >= bestSpeeds.CpCount())
             ){
                currentSpeeds.ToFile(lastRaceTime, curCP);
                if(isRightMap)
                    @bestSpeeds = currentSpeeds;
                @currentSpeeds = MapSpeeds(curMap, false);
                checkingForPb = 0;
            }
        } else {
            bool pbIsSyncedWithPlugin = pbTime == bestSpeeds.GetPb();
            if(keepSync && !pbIsSyncedWithPlugin){
                // dont use cps for pb check if pb was driven without plugin
                compareCps = false;
            }
            auto lastGhost = GetPbGhost(onlyFinishedGhosts);
            auto actualPbTime = keepSync ? pbTime : bestSpeeds.GetPb();
            // If finished use pb time to check for pb, else use cp count to check for pb
            if(lastGhost !is null && 
                 (!compareCps && (lastGhost.Result.Time < actualPbTime || actualPbTime == 0) || 
                (compareCps && curCP >= bestSpeeds.CpCount()))){
                pbTime = lastGhost.Result.Time;
                currentSpeeds.ToFile(lastGhost.Result.Time, curCP);
                if(isRightMap)
                    @bestSpeeds = currentSpeeds;
                @currentSpeeds = MapSpeeds(curMap, false);
                checkingForPb = 0;
            }
        }
    }

    CGameGhostScript@ GetPbGhost(bool onlyFinishedGhosts = false){
        auto pgScript = cast<CSmArenaRulesMode@>(app.PlaygroundScript);
        // Unfinished ghosts have a time of uint(-1), so they won't be picked if the bestTime is
        // initialized to uint(-1)
        uint bestTime = onlyFinishedGhosts ? uint(-1) : 0;
        if(pgScript !is null && pgScript.DataFileMgr !is null){
            auto ghosts = pgScript.DataFileMgr.Ghosts;
            CGameGhostScript@ bestGhost = null;
            for(uint i = 0; i < ghosts.Length; i++){
                auto ghostTime = ghosts[i].Result.Time;
                auto trigram = ghosts[i].Trigram;
                if(trigram == '|' && (ghostTime < bestTime || bestTime == 0)){
                    bestTime = ghostTime;
                    @bestGhost = ghosts[i];
                }
            }
            if(bestGhost is null){
                return null;
            }
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