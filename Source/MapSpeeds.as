class MapSpeeds{
    string mapId = '';
    string jsonFile = '';
    string pbKey = 'pb';
    string finishedKey = 'finished';
    string cpCountKey = 'cps';
    Json::Value speeds = Json::Object();

    string folder = '';

    MapSpeeds(){

    }

    MapSpeeds(string mapIdentifier, bool loadFromFile = true){
        if(mapIdentifier == '') return;

        string baseFolder = IO::FromDataFolder('');
        folder = baseFolder + 'splitspeeds';
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

    bool GetFinished(){
        if(!speeds.HasKey(finishedKey))
            return false;
        bool finished = speeds[finishedKey];
        return finished;
    }

    void SetFinished(bool value){
        speeds[finishedKey] = value;
    }

    void Clear(){
        speeds = Json::Object();
        Json::ToFile(jsonFile, speeds);
    }

    uint CpCount(){
        if(!speeds.HasKey(cpCountKey))
            return 0;
        return speeds[cpCountKey];
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
            } else {
                speeds = Json::FromFile(jsonFile);
            }
        }
    }

    uint GetPb(){
        if(!speeds.HasKey(pbKey))
            return 0;
        return speeds[pbKey];
    }

    void ToFile(uint pbTime, uint cpCount){
        speeds[pbKey] = pbTime;
        speeds[cpCountKey] = cpCount;
        print("[SplitSpeeds] Saving new pb (" + pbTime + ") cp (" + cpCount + ") to file: " + jsonFile);
        Json::ToFile(jsonFile, speeds);
    }
}