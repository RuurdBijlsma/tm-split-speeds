void Main() {
    GUI::Initialize();
}

void Render() {
    if(!UI::IsGameUIVisible() && !showWhenGuiHidden)
        return;
    auto player = GetPlayer();
    if(player !is null) {
        auto scriptPlayer = player.ScriptAPI;
        if(scriptPlayer !is null && scriptPlayer.RaceState == CTrackManiaPlayer::ERaceState::Running)
            GUI::Render();
    }
}


bool retireHandled = false;
bool finishHandled = false;
MapSpeeds@ mapSpeeds = null;

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
    auto currentMap = app.RootMap.IdName;
    if((mapSpeeds is null || currentMap != mapSpeeds.mapId) && currentMap != "") {
        @mapSpeeds = MapSpeeds(currentMap);
        mapSpeeds.InitializeFiles();
    }
    if(mapSpeeds is null) return;
    
    auto scriptPlayer = player.ScriptAPI;
    auto raceState = scriptPlayer.RaceState;
    if(!retireHandled && raceState == CTrackManiaPlayer::ERaceState::BeforeStart) {
        retireHandled = true;
        mapSpeeds.Retire();
    } else if(retireHandled && raceState == CTrackManiaPlayer::ERaceState::Running) {
        mapSpeeds.StartDriving();
        // Driving
        retireHandled = false;
    }

    // Player finishes map
    if(raceState == CTrackManiaPlayer::ERaceState::Finished && !finishHandled) {
        finishHandled = true;
        mapSpeeds.Finish();
    }
    if(raceState != CTrackManiaPlayer::ERaceState::Finished && finishHandled)
        finishHandled = false;

    mapSpeeds.Tick();
}

void RenderMenu() {
	if (UI::MenuItem("\\$f70" + Icons::Registered + "\\$z Speed Splits", "", GUI::visible)) {
		GUI::visible = !GUI::visible;
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