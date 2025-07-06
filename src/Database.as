namespace Database {
    const string tableName = "SplitSpeeds";
    const string dbName = tableName + ".db";
    const string file = IO::FromStorageFolder(dbName);
    bool migrating = false;

    const string tableColumns = """ (
        cps       TEXT,
        isOnline  BOOL,
        lastSaved INT,
        mapUid    VARCHAR(27) PRIMARY KEY,
        time      INT,
        version   INT
    ); """;

    [Setting hidden]
    bool migrated = false;

    void Clear() {
        warn("clearing database of all times!");

        SQLite::Database@ db = Get();
        try {
            db.Execute("DELETE FROM " + tableName);
        } catch {
            error("failed to clear database: " + getExceptionInfo());
        }
    }

    void Delete(const string&in uid) {
        if (uid.Length == 0) {
            return;
        }

        warn("deleting times for map '" + uid + "'");

        SQLite::Database@ db = Get();
        try {
            db.Execute("DELETE FROM " + tableName + " WHERE mapUid = '" + uid + "'");
        } catch {
            error("failed to delete row for map '" + uid + "': " + getExceptionInfo());
        }
    }

    SQLite::Database@ Get() {
        return SQLite::Database(file);
    }

    void Init() {
        SQLite::Database@ db = Get();
        db.Execute("CREATE TABLE IF NOT EXISTS " + tableName + tableColumns);

        if (!migrated) {
            startnew(MigrateFromJsonAsync);
        }
    }

    void MigrateFromJsonAsync() {
        migrating = true;

        const string storageFolder = IO::FromStorageFolder("");

        string[]@ files = IO::IndexFolder(storageFolder, false);
        if (files.Length == 0 || (files.Length == 1 && files[0].EndsWith(dbName))) {
            migrated = true;
            migrating = false;
            return;
        }

        string msg = "migrating from json files to a database, this could take a while...";
        print(msg);
        UI::ShowNotification("Split Speeds", msg);

        SQLite::Database@ db = Get();

        Json::Value@ map;
        Json::Value@[] maps;

        for (uint i = 0; i < files.Length; i++) {
            if (Path::GetExtension(files[i]) == ".json") {
                try {
                    @map = Json::FromFile(files[i]);
                    map["lastSaved"] = IO::FileModifiedTime(files[i]);
                    map["mapUid"] = Path::GetFileNameWithoutExtension(files[i]);
                    maps.InsertLast(map);
                } catch {
                    error("bad json file: " + files[i]);
                }
            }

            if (i > 0 && i % 100 == 0) {
                trace("read json file " + i + " / " + files.Length);
                yield();
            }
        }

        trace("read all json files");

        uint filesToAdd;
        string group;
        string[] groups;
        const uint groupSize = 1000;
        uint version;

        while (maps.Length > 0) {
            filesToAdd = Math::Min(maps.Length, groupSize);

            for (uint i = 0; i < filesToAdd; i++) {
                group += "(";

                version = maps[i].HasKey("version") && maps[i]["version"].GetType() == Json::Type::Number
                    ? uint(maps[i]["version"])
                    : 0;
                switch (version) {
                    case 0: {
                        Json::Value@ cps = Json::Array();
                        int j = 1;
                        Json::Value@ val;
                        while (true) {
                            @val = maps[i][tostring(j)];
                            if (val.GetType() == Json::Type::Number) {
                                cps.Add(Math::Round(float(val), 3));
                            } else {
                                break;
                            }
                        }
                        group += "'" + Json::Write(maps[i]["cps"]) + "',";

                        group += "1,";  // isOnline

                        group += int64(maps[i]["lastSaved"]) + ",";

                        group += "'" + string(maps[i]["mapUid"]) + "',";

                        try {
                            group += int(maps[i]["pb"]) + ",";
                        } catch {
                            error("error with 'pb': " + Json::Write(maps[i]));
                            group += "-1,";
                        }

                        break;
                    }

                    case 1:
                    case 2: {
                        try {
                            for (uint j = 0; j < maps[i]["cps"].Length; j++) {
                                maps[i]["cps"][j] = Math::Round(float(maps[i]["cps"][j]), 3);
                            }
                            group += "'" + Json::Write(maps[i]["cps"]) + "',";
                        } catch {
                            error("error with 'cps': " + Json::Write(maps[i]));
                            group += "'[]',";
                        }

                        try {
                            group += (bool(maps[i]["isOnline"]) ? 1 : 0) + ",";
                        } catch {
                            error("error with 'isOnline': " + Json::Write(maps[i]));
                            group += "0,";
                        }

                        group += int64(maps[i]["lastSaved"]) + ",";

                        group += "'" + string(maps[i]["mapUid"]) + "',";

                        try {
                            group += int(maps[i]["time"]) + ",";
                        } catch {
                            error("error with 'time': " + Json::Write(maps[i]));
                            group += "-1,";
                        }

                        break;
                    }

                    default:
                        warn("Unsupported recorded speeds json version: " + Json::Write(maps[i]));
                        continue;
                }

                try {
                    group += version + ")";
                } catch {
                    error("error with 'version': " + Json::Write(maps[i]));
                    group += "-1)";
                }

                if (i < filesToAdd - 1) {
                    group += ",";
                }
            }

            maps.RemoveRange(0, filesToAdd);
            groups.InsertLast(group);
            group = "";
            yield();
        }

        for (uint i = 0; i < groups.Length; i++) {
            db.Execute("REPLACE INTO " + tableName + " (cps, isOnline, lastSaved, mapUid, time, version) VALUES " + groups[i]);
            trace("executed db statement " + (i + 1) + " / " + groups.Length);
            yield();
        }

        print("moving old files...");
        const string oldFolder = IO::FromStorageFolder("old/");
        if (!IO::FolderExists(oldFolder)) {
            IO::CreateFolder(oldFolder);
        }
        for (uint i = 0; i < files.Length; i++) {
            if (i % 100 == 0) {
                yield();
            }
            if (Path::GetExtension(files[i]) == ".json" && IO::FileExists(files[i])) {
                IO::Move(files[i], oldFolder + Path::GetFileName(files[i]));
            }
        }

        migrated = true;
        migrating = false;
        msg = "migration done!";
        print(msg);
        UI::ShowNotification("Split Speeds", msg);
    }

    SpeedRecording@ Read() {
#if TMNEXT || MP4
        auto RootMap = GetApp().RootMap;
#elif TURBO
        auto RootMap = GetApp().Challenge;
#endif
        if (RootMap is null) {
            return null;
        }

        return Read(RootMap.EdChallengeId);
    }

    SpeedRecording@ Read(const string&in uid) {
        SQLite::Database@ db = Get();
        SQLite::Statement@ s;

        try {
            @s = db.Prepare("SELECT * FROM " + tableName + " WHERE mapUid = '" + uid + "'");
        } catch {
            error("error reading database for map '" + uid + "': " + getExceptionInfo());
            return null;
        }

        if (!s.NextRow()) {
            return null;
        }

        auto result = SpeedRecording();
        try {
            const uint version = s.GetColumnInt("version");

#if MP4
            if (version < 2 && RootMap.TMObjective_NbLaps > 1) {
                print("Old splits version on MultiLap map found! Deleting splits for this map.");
                Delete(uid);
                return null;
            }
#elif TURBO
            auto playgroundScript = cast<CTrackManiaRaceRules>(GetApp().PlaygroundScript);
            if (playgroundScript is null) {
                return null;
            }
            if (version < 2 && playgroundScript.MapNbLaps > 1) {
                print("Old splits version on MultiLap map found! Deleting splits for this map.");
                Delete(uid);
                return null;
            }
#endif

            Json::Value@ cps = Json::Parse(s.GetColumnString("cps"));
            if (cps.GetType() == Json::Type::Array) {
                for (uint i = 0; i < cps.Length; i++) {
                    result.cps.InsertLast(float(cps[i]));
                }
            }

            result.isOnline = s.GetColumnInt("isOnline") > 0;
            result.time = s.GetColumnInt("time");

            print("V" + version + ": Loaded splits from file, online: " + result.isOnline
                + ", time: " + result.time + ", cp count: " + result.cps.Length);
            return result;

        } catch {
            error("error reading from row for map '" + uid + "': " + getExceptionInfo());
            return null;
        }
    }

    void Write(SpeedRecording@ result, const string&in uid) {
        if (result is null) {
            return;
        }

        print("ToFile! time: " + result.time + ", " + uid);

        SQLite::Database@ db = Get();
        try {
            string statement = "REPLACE INTO " + tableName + "(cps, isOnline, lastSaved, mapUid, time, version) VALUES (";

            auto cps = Json::Array();
            for (uint i = 0; i < result.cps.Length; i++) {
                cps.Add(Math::Round(result.cps[i], 3));
            }
            statement += "'" + Json::Write(cps) + "',";
            statement += result.isOnline ? "1," : "0,";
            statement += Time::Stamp + ",";  // lastSaved
            statement +=  "'" + uid + "',";
            statement += result.time + ",";
            statement += 3 + ")";  // version

            db.Execute(statement);

        } catch {
            error("error writing to database: " + result.ToString() + ", " + getExceptionInfo());
        }
    }
}
