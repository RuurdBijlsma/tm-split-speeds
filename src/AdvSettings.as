namespace AdvSettings{
    void Render(){
        if (UI::Button("Clear current map pb speeds")){
            UI::ShowNotification("Cleared pb speeds for current map", 5000);
            mapSpeeds.ClearPB();
        }
        if (UI::Button("Clear all stored pb speeds")){
            string baseFolder = IO::FromDataFolder('');
            string folder = baseFolder + 'splitspeeds';
            if(IO::FolderExists(folder))
                DeleteFiles();
            mapSpeeds.ClearPB();
            UI::ShowNotification("Cleared pb speeds for all maps", 5000);
        }
    }

    void DeleteFiles(){
        string baseFolder = IO::FromDataFolder('');
        string folder = baseFolder + 'splitspeeds';
        auto files = IO::IndexFolder(folder, true);
        for(uint i = 0; i < files.Length; i++){
            IO::Delete(files[i]);
        }
    }
}