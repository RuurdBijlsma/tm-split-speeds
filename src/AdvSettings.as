bool unlockButtons = false;

namespace AdvSettings{
    void Render() {
        unlockButtons = UI::Checkbox("Unlock buttons to clear speeds", unlockButtons);
        UI::BeginDisabled(!unlockButtons);
        UI::BeginDisabled(Map::pbRecord is null);
        if (UI::Button("Clear current map pb speeds")) {
            Map::ClearPB();
            UI::ShowNotification("Cleared pb speeds for current map", 5000);
            unlockButtons = false;
        }
        UI::EndDisabled();
        if (UI::Button("Clear all stored pb speeds")) {
            Database::Clear();
            Map::ClearPB();
            UI::ShowNotification("Cleared pb speeds for all maps", 5000);
            unlockButtons = false;
        }
        UI::EndDisabled();

        UI::Separator();

        UI::TextWrapped("Map UID: " + Map::mapId);

        if (Map::mapId == "") {
            UI::TextWrapped("No map speeds loaded.");
            return;
        }

        DrawSpeedRecDebug("Current Speeds", Map::currentRecord);
        DrawSpeedRecDebug("Unfinished Speeds", Map::unfinishedRun);
        DrawSpeedRecDebug("Session Record", Map::sessionRecord);
        DrawSpeedRecDebug("PB Record", Map::pbRecord);
    }

    void DrawSpeedRecDebug(const string &in name, SpeedRecording@ sr) {
        UI::Text(name + ": ");
        UI::SameLine();
        if (sr !is null) {
            sr.DrawDebugInfo();
        } else {
            UI::Text("null");
        }
    }
}