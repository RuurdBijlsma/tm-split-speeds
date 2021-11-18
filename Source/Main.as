Speeder speeder;

// todo:
// save splits also when retiring and there's no pb yet!
// stop shwoing splits when escape is presseed

void Main(){
    speeder = Speeder();
}

void Update(float dt){
    if(speeder !is null)
        speeder.Tick();
}

void Render(){
    if(speeder !is null)
        speeder.gui.Render();
}

[Setting category="Advanced Settings"]
void RenderSettings(){
    AdvSettings::Render(speeder);
}

void RenderMenu()
{
	if (UI::MenuItem("\\$f70" + Icons::Registered + "\\$z Speed Splits", "", speeder.gui.visible)) {
		speeder.gui.visible = !speeder.gui.visible;
	}
}

void OnSettingsChanged(){
    // Show ui for 3 seconds to see effect of settings changes
    speeder.showStartTime = Time::get_Now();
}