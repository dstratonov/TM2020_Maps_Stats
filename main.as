


void Update(float dt){
}

void Render(){
     RenderMapsStatsTable(all_maps);
}

void RenderMapsStatsTable(array<MapDataHolder::DataHolder@> maps_info) 
{
    // Assumption: mapNames.size() == authorMedals.size()
    int totalMaps = maps_info.get_Length();

    // Table Begin
    if (UI::BeginTable("Maps stats", 11, UI::TableFlags::Borders | UI::TableFlags::Resizable)) 
    {
        UI::TableSetupColumn("Map name");
        UI::TableSetupColumn("Map author");
        UI::TableSetupColumn("Map Author Score");
        UI::TableSetupColumn("MapId");
        UI::TableSetupColumn("MapUid");

        UI::TableSetupColumn("Map Id From Record");
        UI::TableSetupColumn("Map Record Id");
        UI::TableSetupColumn("Medal");
        UI::TableSetupColumn("Record Time");
        UI::TableSetupColumn("Time Stamp");

        //UI::TableSetupColumn("Show Medal Maps");
        UI::TableSetupColumn("Resync");
        // Header
        UI::TableNextRow();
        
        // 1. Count of maps with author medal/all maps count
        UI::TableNextColumn();
        UI::Text("Mapname");

        UI::TableNextColumn();
        UI::Text("MapAuthor");

        UI::TableNextColumn();
        UI::Text("MapAuthorScore");

        UI::TableNextColumn();
        UI::Text("MapId");

        UI::TableNextColumn();
        UI::Text("MapUid");

        UI::TableNextColumn();
        UI::Text("MapIdFromRecord");

        UI::TableNextColumn();
        UI::Text("MapRecordId");

        UI::TableNextColumn();
        UI::Text("Medal");

        UI::TableNextColumn();
        UI::Text("RecordTime");

        UI::TableNextColumn();
        UI::Text("TimeStamp");
        
        
        // 2. Button to hide or show maps with author medal
        //UI::TableNextColumn();
        //if (UI::Button(showMedalMaps ? "Hide Medal Maps" : "Show Medal Maps")) 
        //{
        //    showMedalMaps = !showMedalMaps;
        //}

        // 3. Resync button
        UI::TableNextColumn();
        if (UI::Button("Resync")) 
        {
            if (!isResync) isResync = true;
        }

        // Content Rows
        for (int i = 0; i < maps_info.get_Length(); i++) 
        {
            // Check if we should show this map
            //if (!showMedalMaps && authorMedals[i]) 
            //{
            //    continue;
            //}

            UI::TableNextRow();

            // 1. Map name
            UI::TableNextColumn();
            UI::Text(ColoredString(maps_info[i].mapName));

            UI::TableNextColumn();
            UI::Text(maps_info[i].author);

            UI::TableNextColumn();
            UI::Text("" + maps_info[i].authorScore);

            UI::TableNextColumn();
            UI::Text(maps_info[i].mapId);

            UI::TableNextColumn();
            UI::Text(maps_info[i].mapUid);

            UI::TableNextColumn();
            UI::Text(maps_info[i].mapIdFromRecord);

            UI::TableNextColumn();
            UI::Text(maps_info[i].mapRecordId);

            UI::TableNextColumn();
            UI::Text("" + maps_info[i].medal);

            UI::TableNextColumn();
            UI::Text("" + maps_info[i].recordTime);

            UI::TableNextColumn();
            UI::Text(maps_info[i].timestamp);

            // 2. Green or red circle
            //UI::TableNextColumn();
            //string color = authorMedals[i] ? "Author" : "None"; 
            //UI::Text(color);

            // 3. Play button
            UI::TableNextColumn();
            if (UI::Button("Play".opAdd(i))) 
            {
                if (!GoLoadMap){
                    GoLoadMap = true;
                    mapUrl = maps_info[i].fileUrl;
                    
                }
            }
        }

        UI::EndTable();
    }
}

void NotifyError(const string &in msg) {
    warn(msg);
    UI::ShowNotification(Meta::ExecutingPlugin().Name + ": Error", msg, vec4(.9, .3, .1, .3), 15000);
}

void LoadMapNow(const string &in url, const string &in mode = "", const string &in settingsXml = "") {
    if (!Permissions::PlayLocalMap()) {
        NotifyError("Refusing to load map because you lack the necessary permissions. Standard or Club access required");
        return;
    }
    // change the menu page to avoid main menu bug where 3d scene not redrawn correctly (which can lead to a script error and `recovery restart...`)
    auto app = cast<CGameManiaPlanet>(GetApp());
    app.BackToMainMenu();
    while (!app.ManiaTitleControlScriptAPI.IsReady) yield();
    while (app.Switcher.ModuleStack.Length < 1 || cast<CTrackManiaMenus>(app.Switcher.ModuleStack[0]) is null) yield();
    yield();
    print(url);
    app.ManiaTitleControlScriptAPI.PlayMap(url, mode, settingsXml);
}


void AddAudiences(){
    NadeoServices::AddAudience("NadeoServices");
}
array<MapDataHolder::DataHolder@> all_maps;
bool showMedalMaps = true;
bool isResync = false;
void Resync(){
    Json::Value@ allRecords = Helpers::GetAllAccountRecords();
    int mapCount = allRecords.get_Length();
    int maximumCount = 200;
    mapCount = maximumCount < mapCount ? maximumCount : mapCount;
    all_maps = {};
    Batch::Batch batches();
    for (int i = 0; i < mapCount; i++){
        Json::Value@ personalRecord = allRecords.opIndex(i);
        batches.AddMapId(personalRecord.Get("mapId"));
    }
    int globalID = 0;
    for (int i = 0; i < batches.batchHolders.get_Length(); i++){
        Json::Value@ mapInfoPerBatch = Helpers::GetMapInfoByArrayOfID(batches.batchHolders[i]);
        for (int j = 0; j < batches.batchHolders[i].get_Length(); j++){
            Json::Value@ personalRecord = allRecords.opIndex(globalID);
            Json::Value@ mapInfo = mapInfoPerBatch.opIndex(j);
            MapDataHolder::DataHolder mapData(mapInfo, personalRecord);
            all_maps.InsertLast(mapData);
            print("");
            print("Map Name = " + ColoredString(all_maps[globalID].mapName));
            print("Author = " + all_maps[globalID].author);
            print("Author Score = " + all_maps[globalID].authorScore);
            print("Map Id = " + all_maps[globalID].mapId);
            print("Map Uid = " + all_maps[globalID].mapUid);
            print("File Url = " + all_maps[globalID].fileUrl);
            print("Map Id From Record = " + all_maps[globalID].mapIdFromRecord);
            print("Map Record Id = " + all_maps[globalID].mapRecordId);
            print("Medal = " + all_maps[globalID].medal);
            print("Record Score = " + all_maps[globalID].recordScore);
            print("Record Time = " + all_maps[globalID].recordTime);
            print("Scope Type = " + all_maps[globalID].scopeType);
            print("Time Stamp = " + all_maps[globalID].timestamp);
            print("Record Url = " + all_maps[globalID].recordUrl); 
            print("");
            globalID = globalID + 1;
        }
    }

    print(all_maps.get_Length());
}

bool GoLoadMap = false;
string mapUrl = "";
bool audiencesAdded = false;
void Main() {
    startnew(MainCoro);
}

void MainCoro() {
    while (true) {
        yield();
        if (!audiencesAdded){
            AddAudiences();
            audiencesAdded = true;
        }
        if (isResync){
            Resync();
            isResync = false;
        }
        if (GoLoadMap){
           // GetApp().ManiaTitleControlScriptAPI.PlayMap(mapUrl, "TrackMania/TM_PlayMap_Local", "");
            LoadMapNow(mapUrl, "TrackMania/TM_PlayMap_Local");
            GoLoadMap = false;
        }
    }
}
