// todo 
// everything
// speed diff at every tick in the bottom corner or something :)

void Main() {
    GUI::Initialize();
}

void Render() {
    if(!UI::IsGameUIVisible() && !showWhenGuiHidden)
        return;
    GUI::Render();
}

CTrackMania@ app = null;
CSmArenaClient@ playground = null;
MapSpeeds@ mapSpeeds = null;
CGameTerminal@ terminal = null;
CSmPlayer@ player = null;
CGamePlaygroundScript@ playgroundScript = null;

bool retireHandled = false;
bool finishHandled = false;

void Update(float dt) {
    CP::Update();
    @app = cast<CTrackMania@>(GetApp());
    if(app is null) return;
    @playgroundScript = app.PlaygroundScript;
    @playground = cast<CSmArenaClient@>(app.CurrentPlayground);
    if(playground !is null) {
        @terminal = playground.GameTerminals[0];
        @player = cast<CSmPlayer>(terminal.ControlledPlayer);
    }
    if(playground is null 
        || terminal is null 
        || player is null 
        || player.ScriptAPI is null 
        || player.CurrentLaunchedRespawnLandmarkIndex == uint(-1)) {
        if(mapSpeeds !is null) 
            @mapSpeeds = null;
        return;
    }
    auto currentMap = playground.Map.IdName;
    if((mapSpeeds is null || currentMap != mapSpeeds.mapId) && currentMap != "") {
        @mapSpeeds = MapSpeeds(currentMap);
        mapSpeeds.InitializeFiles();
    }
    if(mapSpeeds is null) return;
    
    auto post = player.ScriptAPI.Post;
    if(!retireHandled && post == CSmScriptPlayer::EPost::Char) {
        retireHandled = true;
        mapSpeeds.Retire();
    } else if(retireHandled && post == CSmScriptPlayer::EPost::CarDriver) {
        mapSpeeds.StartDriving();
        // Driving
        retireHandled = false;
    }

    auto uiSequence = terminal.UISequence_Current;
    // Player finishes map
    if(uiSequence == CGamePlaygroundUIConfig::EUISequence::Finish && !finishHandled) {
        finishHandled = true;
        mapSpeeds.Finish();
    }
    if(uiSequence != CGamePlaygroundUIConfig::EUISequence::Finish && finishHandled)
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