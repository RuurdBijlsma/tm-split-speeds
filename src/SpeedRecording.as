class SpeedRecording {

    float[]@ cps = {};
    uint lastCpTime = 0; // Only used for unfinished runs and not written to file
    uint time = 0;
    bool isOnline = false;

    void ToFile(const string &in path) {
        print("ToFile! time: " + time + ", " + path);
        Json::Value speeds = Json::Object();

        // version: 2
        speeds["version"] = 2;
        speeds["time"] = time;
        speeds["isOnline"] = isOnline;

        speeds["cps"] = Json::Array();
        for (uint i = 0; i < cps.Length; i++) {
            speeds["cps"].Add(cps[i]);
        }

        Json::ToFile(path, speeds);
    }

    string ToString() {
        string[] cpsStr = {};
        for (uint i = 0; i < cps.Length; i++) {
            cpsStr.InsertLast(tostring(cps[i]));
        }
        return "SpeedRecording < time = " + Time::Format(time) + ", cps = { " + (string::Join(cpsStr, " / ")) + " } >";
    }

    void DrawDebugInfo() {
        string[] cpsStr = {};
        for (uint i = 0; i < cps.Length; i++) {
            cpsStr.InsertLast(tostring(cps[i]));
        }
        UI::TextWrapped("SpeedRecording < time = " + Time::Format(time) + ", cps = { " + (string::Join(cpsStr, " / ")) + " }" + ", lastCpTime = " + Time::Format(lastCpTime) + " >");
    }

}
