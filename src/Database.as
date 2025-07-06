namespace Database {
    const string tableName = "SplitSpeeds";
    const string dbName = tableName + ".db";
    const string file = IO::FromStorageFolder(dbName);
    bool migrating = false;

    const string tableColumns = """ (
        cps       TEXT,
        isOnline  BOOL,
        lastSaved INT,
        mapName   TEXT,
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

        Json::Value@[] maps;

        for (uint i = 0; i < files.Length; i++) {
            if (files[i].EndsWith(".json")) {
                try {
                    Json::Value@ map = Json::FromFile(files[i]);
                    map["mapUid"] = files[i].Replace(storageFolder, "").Replace(".json", "");
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

        while (maps.Length > 0) {
            filesToAdd = Math::Min(maps.Length, groupSize);

            for (uint i = 0; i < filesToAdd; i++) {
                group += "(";

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

                group += "'" + string(maps[i]["mapUid"]) + "',";

                try {
                    group += int(maps[i]["time"]) + ",";
                } catch {
                    error("error with 'time': " + Json::Write(maps[i]));
                    group += "-1,";
                }

                try {
                    group += int(maps[i]["version"]) + ")";
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
            db.Execute("REPLACE INTO " + tableName + " (cps, isOnline, mapUid, time, version) VALUES " + groups[i]);
            trace("executed db statement " + (i + 1) + " / " + groups.Length);
            yield();
        }

        // migrated = true;  // uncomment when testing is done
        migrating = false;
        msg = "migration done!";
        print(msg);
        UI::ShowNotification("Split Speeds", msg);
    }
}
