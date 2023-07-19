#if MP4

void Main() {
    GUI::Initialize();
}

void Render() {
    auto player = GetPlayer();
    GUI::visible = false;
    if(player !is null) {
        auto scriptPlayer = player.ScriptAPI;
        if(scriptPlayer !is null && scriptPlayer.RaceState == CTrackManiaPlayer::ERaceState::Running)
            GUI::Render();
    }
}


bool retireHandled = false;
bool finishHandled = false;
MapSpeedsMP4@ mapSpeeds = null;

uint lastPrevRaceTime = 3000000000;


void Update(float dt) {
    CP::Update();
    auto app = cast<CTrackMania@>(GetApp());
    if(app is null) return;
    auto playground = cast<CGamePlayground@>(app.CurrentPlayground);
    auto player = GetPlayer();
    if(playground is null 
        || player is null 
        || player.ScriptAPI is null) {
        if(mapSpeeds !is null) 
            @mapSpeeds = null;
        return;
    }
    auto currentMap = app.RootMap.MapInfo.MapUid;
    auto scriptPlayer = player.ScriptAPI;
    auto raceState = scriptPlayer.RaceState;
    if((mapSpeeds is null || currentMap != mapSpeeds.mapId) && currentMap != "" && raceState == CTrackManiaPlayer::ERaceState::Running) {
        @mapSpeeds = MapSpeedsMP4(currentMap);
        mapSpeeds.InitializeFiles();
        retireHandled = true;
    }
    if(mapSpeeds is null) return;
    
    if(!retireHandled && raceState == CTrackManiaPlayer::ERaceState::BeforeStart) {
        retireHandled = true;
        mapSpeeds.Retire();
    } else if(retireHandled && raceState == CTrackManiaPlayer::ERaceState::Running) {
        mapSpeeds.StartDriving();
        // Driving
        retireHandled = false;
    }

    // Check for map finish then call mapspeed.finish()
    auto prevRecord = playground.PrevReplayRecord;
    if(prevRecord !is null && prevRecord.Ghosts.Length > 0) {
        auto ghost = prevRecord.Ghosts[0];
        if(ghost.RaceTime != lastPrevRaceTime){ 
            lastPrevRaceTime = ghost.RaceTime;
            if(lastPrevRaceTime < 3000000000) {
                print("Finish!: " + ghost.RaceTime);
                mapSpeeds.HandleFinish(ghost.RaceTime);
            }
        }
    }


    mapSpeeds.Tick();
}

void RenderMenu() {
	if (UI::MenuItem("\\$f70" + Icons::Registered + "\\$z Speed Splits", "", GUI::enabled)) {
		GUI::enabled = !GUI::enabled;
	}
}

[SettingsTab name="Advanced"]
void RenderSettingsFontTab() {
    AdvSettings::Render();
}

void OnSettingsChanged(){
    // Show ui for 3 seconds to see effect of settings changes
    GUI::showTime = Time::Now;
}

CTrackManiaPlayer@ GetPlayer() {
    auto app = cast<CTrackMania@>(GetApp());
    if(app is null) return null;
    auto playground = cast<CGamePlayground@>(app.CurrentPlayground);
    if(playground is null) return null;
    if(playground.GameTerminals.Length < 1) return null;
    auto terminal = playground.GameTerminals[0];
    if(terminal is null) return null;
    return cast<CTrackManiaPlayer@>(terminal.ControlledPlayer);
}

#endif