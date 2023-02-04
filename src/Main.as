#if TMNEXT

void Main() {
    GUI::Initialize();
}

void Render() {
    auto player = GetPlayer();
    GUI::visible = false;
    if(player !is null) {
        auto scriptPlayer = cast<CSmScriptPlayer@>(player.ScriptAPI);
        if(scriptPlayer !is null && scriptPlayer.Post == CSmScriptPlayer::EPost::CarDriver)
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
    auto playground = cast<CSmArenaClient@>(app.CurrentPlayground);
    auto player = GetPlayer();
    if(playground is null 
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
    
    auto scriptPlayer = cast<CSmScriptPlayer@>(player.ScriptAPI);
    auto post = scriptPlayer.Post;
    if(!retireHandled && post == CSmScriptPlayer::EPost::Char) {
        retireHandled = true;
        mapSpeeds.Retire();
    } else if(retireHandled && post == CSmScriptPlayer::EPost::CarDriver) {
        mapSpeeds.StartDriving();
        // Driving
        retireHandled = false;
    }

    auto terminal = playground.GameTerminals[0];
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

CSmPlayer@ GetPlayer() {
    auto app = cast<CTrackMania@>(GetApp());
    if(app is null) return null;
    auto playground = cast<CSmArenaClient@>(app.CurrentPlayground);
    if(playground is null) return null;
    if(playground.GameTerminals.Length < 1) return null;
    auto terminal = playground.GameTerminals[0];
    if(terminal is null) return null;
    return cast<CSmPlayer@>(terminal.ControlledPlayer);
}

#endif
