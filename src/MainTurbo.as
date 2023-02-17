#if TURBO

void Main() {
    GUI::Initialize();
}

void Render() {
    auto player = GetPlayer();
    GUI::visible = false;
    if(player !is null) {
        if(player.RaceState == CTrackManiaPlayer::ERaceState::Running)
            GUI::Render();
    }
}


bool retireHandled = false;
bool finishHandled = false;
MapSpeeds@ mapSpeeds = null;

int loadedTimer = 0;
uint lastPrevRaceTime = 3000000000;


void Update(float dt) {
    CP::Update();
    auto app = cast<CTrackMania@>(GetApp());
    if(app is null) return;
    auto playground = cast<CGamePlayground@>(app.CurrentPlayground);
    auto player = GetPlayer();
    if(playground is null 
        || player is null) {
        if(mapSpeeds !is null) 
            @mapSpeeds = null;
        return;
    }
    auto currentMap = app.Challenge.MapInfo.MapUid;
    if((mapSpeeds is null || currentMap != mapSpeeds.mapId) && currentMap != "") {
        print("waiting some ticks: " + loadedTimer);
        loadedTimer += 1;
        // wait 30 ticks after ghosts seem to be loaded in case the pb ghost isnt loaded yet
        // takes ~20 ticks for to load ghosts for me
        if(loadedTimer > 50) {
            loadedTimer = 0;
            @mapSpeeds = MapSpeeds(currentMap);
            mapSpeeds.InitializeFiles();
        }
    }
    if(mapSpeeds is null) return;
    
    auto raceState = player.RaceState;
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