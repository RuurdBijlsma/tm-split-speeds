class MapSpeeds{
    string mapId = '';
    string jsonFile = '';
    string pbKey = 'pb';
    Json::Value speeds = Json::Object();

    MapSpeeds(){

    }

    MapSpeeds(string mapIdentifier, bool loadFromFile = true){
        if(mapIdentifier == '') return;


        string baseFolder = IO::FromDataFolder('');
        string folder = baseFolder + '/' + 'splitspeeds';
        if(!IO::FolderExists(folder)){
            IO::CreateFolder(folder);
            print("[SplitSpeeds] Created folder: " + folder);
        }

        mapId = mapIdentifier;
        jsonFile = folder + '/' + mapId + ".json";
        if(loadFromFile){
            // print("Reading map speeds from file: " + jsonFile);
            FromFile();
        }
    }

    float GetCp(uint cpId){
        return speeds['' + cpId];
    }

    void SetCp(uint cpId, float speed){
        speeds['' + cpId] = speed;
    }

    bool HasCp(uint cpId){
        return speeds.HasKey('' + cpId);
    }

    void FromFile(){
        if(IO::FileExists(jsonFile)){
            // check validity of existing file
            IO::File f(jsonFile);
            f.Open(IO::FileMode::Read);
            auto content = f.ReadToEnd();
            f.Close();
            if(content == "" || content == "null"){
                warn("[SplitSpeeds] Invalid SplitSpeeds file detected");
                speeds = Json::Object();
            }else{
                speeds = Json::FromFile(jsonFile);
            }
        }
    }

    uint getPb(){
        if(!speeds.HasKey(pbKey))
            return 0;
        return speeds[pbKey];
    }

    void ToFile(uint pbTime){
        speeds[pbKey] = pbTime;
        print("[SplitSpeeds] Saving new pb to file: " + jsonFile);
        Json::ToFile(jsonFile, speeds);
    }
}