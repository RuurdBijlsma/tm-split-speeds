class SpeedRecording {

    float[]@ cps = {};
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
        for(uint i = 0; i < cps.Length; i++) {
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
        UI::TextWrapped("SpeedRecording < time = " + Time::Format(time) + ", cps = { " + (string::Join(cpsStr, " / ")) + " } >");
    }

}

namespace SpeedRecording {

    SpeedRecording@ FromFile(const string &in path) {
        if(!IO::FileExists(path)) return null;
        auto json = Json::FromFile(path);
        if(json.GetType() != Json::Type::Object) return null;

        int version = json["version"].GetType() == Json::Type::Number ? json["version"] : 0;

#if MP4
        if(version < 2 && GetApp().RootMap.TMObjective_NbLaps > 1) {
            print("Old splits version on MultiLap map found! Deleting splits for this map.");
            IO::Delete(path);
            return null;
        }
#elif TURBO
        auto playground = cast<CTrackManiaRaceNew>(GetApp().CurrentPlayground);
        auto playgroundScript = cast<CTrackManiaRaceRules>(GetApp().PlaygroundScript);
        if(version < 2 && playgroundScript.MapNbLaps > 1) {
            print("Old splits version on MultiLap map found! Deleting splits for this map.");
            IO::Delete(path);
            return null;
        }
#endif

        if(version == 0) {
            return Version0(json);
        } else if(version == 1) {
            return Version1(json);
        } else if(version == 2) {
            return Version2(json);
        } else {
            warn("Unsupported recorded speeds json version: " + path);
        }

        return null;
    }

    SpeedRecording@ Version0(Json::Value json) {
        auto result = SpeedRecording();
        if(json['pb'].GetType() != Json::Type::Number) {
            warn("Speedsplits file V0 has invalid pb time!");
            return null;
        }
        result.time = json['pb'];
        result.isOnline = true;
        int i = 1;
        while(true) {
            auto val = json[tostring(i++)];
            if(val.GetType() == Json::Type::Number) {
                result.cps.InsertLast(val);
            } else {
                break;
            }
        }
        print("V0: Loaded splits from file, online: " + result.isOnline + ", time: " + result.time + ", cp count: " + result.cps.Length);
        return result;
    }

    SpeedRecording@ Version1(Json::Value json) {
        auto result = SpeedRecording();
        result.time = json["time"];
        result.isOnline = json["isOnline"];
        if(json['cps'].GetType() != Json::Type::Array) return null;
        for(uint i = 0; i < json['cps'].Length; i++) {
            result.cps.InsertLast(json['cps'][i]);
        }
        print("V1: Loaded splits from file, online: " + result.isOnline + ", time: " + result.time + ", cp count: " + result.cps.Length);
        return result;
    }

    SpeedRecording@ Version2(Json::Value json) {
        auto result = SpeedRecording();
        result.time = json["time"];
        result.isOnline = json["isOnline"];
        if(json['cps'].GetType() != Json::Type::Array) return null;
        for(uint i = 0; i < json['cps'].Length; i++) {
            result.cps.InsertLast(json['cps'][i]);
        }
        print("V2: Loaded splits from file, online: " + result.isOnline + ", time: " + result.time + ", cp count: " + result.cps.Length);
        return result;
    }

}