class SpeedRecording {
    float[]@ ticks = {};
    float[]@ cps = {};
    int time = 0;
    bool isOnline = false;

    void ToFile(string path, int time, bool isOnline) {
        print("ToFile! time: " + time + ", " + path);
        Json::Value speeds = Json::Object();

        // version: 1
        speeds["version"] = 1;
        speeds["time"] = time;
        speeds["isOnline"] = isOnline;

        speeds["cps"] = Json::Array();
        for(uint i = 0; i < cps.Length; i++) {
            speeds["cps"].Add(cps[i]);
        }

        speeds["ticks"] = Json::Array();
        for(uint i = 0; i < ticks.Length; i++) {
            speeds["ticks"].Add(ticks[i]);
        }

        Json::ToFile(path, speeds);
    }
};

namespace SpeedRecording {
    SpeedRecording@ FromFile(string path) {
        if(!IO::FileExists(path)) return null;
        auto json = Json::FromFile(path);
        if(json.GetType() != Json::Type::Object) return null;

        auto result = SpeedRecording();
        int version = json["version"].GetType() == Json::Type::Number ? json["version"] : 0;
        if(version == 0) {
            result.time = json['pb'];
            result.isOnline = false;
            int i = 1;
            while(true) {
                auto val = json[tostring(i++)];
                if(val.GetType() == Json::Type::Number) {
                    result.cps.InsertLast(val);
                } else {
                    break;
                }
            }
        } else if(version == 1) {
            result.time = json["time"];
            result.isOnline = json["isOnline"];
            if(json['cps'].GetType() != Json::Type::Array) return null;
            for(uint i = 0; i < json['cps'].Length; i++) {
                result.cps.InsertLast(json['cps'][i]);
            }
            if(json['ticks'].GetType() == Json::Type::Array) {
                for(uint i = 0; i < json['ticks'].Length; i++) {
                    result.ticks.InsertLast(json['ticks'][i]);
                }
            }
        } else {
            warn("Unsupported recorded speeds json version: " + path);
        }

        return result;

        // check for version, if tag doesn't exist use old parsing and set ticks array to null
    }
}