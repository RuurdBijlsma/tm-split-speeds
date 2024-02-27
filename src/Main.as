// TODO 
// Test other games
// edit campaign map is stuk ofzo? sometimes n editor validation of maps that are/are modified campaign maps, the split will save as 0


void Main() {
    GUI::Main();
    Map::Main();
}

void Render() {
    GUI::Render();
}

void Update(float dt) {
    Detector::Update();
    Waypoint::Update();
    Race::Update();
    Map::Update();
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