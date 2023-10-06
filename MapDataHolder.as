namespace MapDataHolder{
    class DataHolder
    {
        // Maps Info
        string mapName;
        string author;
        int authorScore;
        string mapId;
        string mapUid;
        string fileUrl;

        // record Info
        string mapIdFromRecord;
        string mapRecordId;
        int medal;
        int recordScore;
        int recordTime;
        string scopeType;
        string timestamp;
        string recordUrl;
        DataHolder(Json::Value@ mapInfo, Json::Value@ recordInfo){
            mapId = recordInfo.Get("mapId");
            mapUid = mapInfo.Get("mapUid");
            mapName = mapInfo.Get("name");
            authorScore = mapInfo.Get("authorScore");
            fileUrl = mapInfo.Get("fileUrl");
            author = mapInfo.Get("author");

            mapIdFromRecord = recordInfo.Get("mapId");
            mapRecordId = recordInfo.Get("mapRecordId");
            medal = recordInfo.Get("medal");
            recordScore = recordInfo.Get("recordScore").Get("score");
            recordTime = recordInfo.Get("recordScore").Get("time");
            scopeType = recordInfo.Get("scopeType");
            timestamp = recordInfo.Get("timestamp");
            recordUrl = recordInfo.Get("url");
        }
    }

}