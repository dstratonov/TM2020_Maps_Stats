


void Update(float dt){
}

[Setting hidden]
bool S_WindowOpen = true;

void RenderMenu() {
    if (UI::MenuItem("Map Manager Plugin", "", S_WindowOpen))
        S_WindowOpen = !S_WindowOpen;
}

void Render(){
    if (!S_WindowOpen) return;
    if (UI::Begin("Map Manager", S_WindowOpen, UI::WindowFlags::AlwaysAutoResize)) {
        if (hideAuthorMedalMaps) RenderMapsStatsTable(all_maps_without_author_medal);
        else RenderMapsStatsTable(all_maps_for_search);
    }
    UI::End();
}

int currentPage = 0;
const int mapsPerPage = 23;
bool hideAuthorMedalMaps = false;
string searchInput = "";
bool searchMaps = false;

string RGBToHex(int r, int g, int b) {
    string hexChars = "0123456789abcdef";

    string hex = "$";

    hex += hexChars.SubStr(r >> 4, 1);

    hex += hexChars.SubStr(g >> 4, 1);

    hex += hexChars.SubStr(b >> 4, 1);

    return hex;
}

string GetColorBasedOnPercentage(int percent) {
    if (percent < 0) percent = 0;
    if (percent > 100) percent = 100;

    int red = (100 - percent) * 255 / 100;
    int green = percent * 255 / 100;

    return RGBToHex(red, green, 0);
}

void RenderMapsStatsTable(array<MapDataHolder::DataHolder@> maps_info) 
{
    int totalMaps = maps_info.get_Length();
    int totalPages = (totalMaps + mapsPerPage - 1) / mapsPerPage; // Calculate the total number of pages.
    int mapsWithAuthor = CountAuthorMedals(maps_info);
    float percentOfComplete = 0;
    if (totalMaps > 0) percentOfComplete = (float(mapsWithAuthor) / float(totalMaps)) * 100.0;
    string Color = GetColorBasedOnPercentage(int(percentOfComplete));

    if (currentPage < 0) currentPage = 0;
    if (currentPage > (totalPages - 1) && totalPages > 0) currentPage = totalPages - 1;

    // Table Begin
    if (UI::BeginTable("Maps stats", 7, UI::TableFlags::SizingFixedFit)) 
    {
        // Header
        UI::TableNextRow();
        
        // 1. Stats - maps with author medal / total maps
        UI::TableNextColumn();
        UI::Text(ColoredString("ATs: " + mapsWithAuthor + " / " + totalMaps + " " + Color + int(percentOfComplete)) + "%");

        UI::TableNextColumn();
        UI::SetNextItemWidth(searchInput.get_Length() * 6.1 + 40.0);
        searchInput = UI::InputText("Filter", searchInput);

        UI::TableNextColumn();
        if (UI::Button("Search")) 
        {
            if (!searchMaps){
                searchMaps = true;
            }
        }

        UI::TableNextColumn();

        UI::TableNextColumn();
        UI::TableNextColumn();
        if (UI::Button(hideAuthorMedalMaps ? "Show Author Medal Maps" : "Hide Author Medal Maps")) 
        {
            hideAuthorMedalMaps = !hideAuthorMedalMaps;
        }

        UI::TableNextRow();

        // 2. Column Headers
        UI::TableNextColumn();
        UI::Text("Map name");

        UI::TableNextColumn();
        UI::Text("AT");

        UI::TableNextColumn();
        UI::Text("Delta to AT");

        UI::TableNextColumn();
        UI::Text("PB");

        UI::TableNextColumn();
        UI::Text("Medal");

        UI::TableNextColumn();
        UI::Text("Timestamp of PB");

        // Data Rows
        int startIdx = currentPage * mapsPerPage;
        int endIdx = startIdx + mapsPerPage;
        if (endIdx > totalMaps) 
        {
            endIdx = totalMaps;
        }

        for (int i = startIdx; i < endIdx; i++) 
        {
            UI::TableNextRow();

            // 1. Map name
            UI::TableNextColumn();
            UI::Text(ColoredString(maps_info[i].mapName));

            UI::TableNextColumn();
            UI::Text("" + Text::Format("%.3f", maps_info[i].authorScore / 1000.0)); 

            // 2. Author time difference (Assuming a dummy value for now)
            UI::TableNextColumn();
            UI::Text("" + Text::Format("%.3f", (maps_info[i].recordTime - maps_info[i].authorScore) / 1000.0)); 

            // 4. Record score
            UI::TableNextColumn();
            UI::Text("" + Text::Format("%.3f", maps_info[i].recordTime / 1000.0));

            // 3. Author medal get
            UI::TableNextColumn();
            if (maps_info[i].medal == 4) UI::Text(ColoredString("$0f0Author"));
            else if (maps_info[i].medal == 3) UI::Text(ColoredString("$ff0Gold"));
            else if (maps_info[i].medal == 2) UI::Text(ColoredString("$999Silver"));
            else if (maps_info[i].medal == 1) UI::Text(ColoredString("$970Bronze"));
            else UI::Text(ColoredString("$888None"));

            // 5. Timestamp
            UI::TableNextColumn();
            UI::Text(maps_info[i].timestamp);

            // 6. Play button
            UI::TableNextColumn();
            if (UI::Button("Play" + "##" + maps_info[i].mapId)) 
            {
                if (!GoLoadMap)
                {
                    GoLoadMap = true;
                    mapUrl = maps_info[i].fileUrl;
                }
            }
        }

        UI::EndTable();
    }

    // Pagination Controls
    if (UI::Button("Left") && currentPage > 0) 
    {
        currentPage--;
    }
    
    UI::SameLine();

    if (UI::Button("Right") && currentPage < totalPages - 1) 
    {
        currentPage++;
    }

    UI::SameLine();

    UI::Text("Pages: " + (currentPage + 1) + " / " + totalPages); 

    if (Loading) {
        UI::SameLine();
        UI::Text("Maps are loading. Please wait; it might take some time."); 
    }
}

array<MapDataHolder::DataHolder@> GetFilteredMaps(array<MapDataHolder::DataHolder@> maps_info, const string searchTerm) 
{
    array<MapDataHolder::DataHolder@> result;
    auto lowerSearchTerm = searchTerm.ToLower();

    for (uint i = 0; i < maps_info.get_Length(); i++) 
    {
        if (Regex::Contains(maps_info[i].mapName.ToLower(), lowerSearchTerm, Regex::Flags::ECMAScript)) 
        {
            result.InsertLast(maps_info[i]);
        }
    }

    return result;
}

array<MapDataHolder::DataHolder@> GetMapsWithoutAuthorMedal(array<MapDataHolder::DataHolder@> maps_info) 
{
    array<MapDataHolder::DataHolder@> result;

    for (uint i = 0; i < maps_info.get_Length(); i++) 
    {
        if (maps_info[i].medal < 4) 
        {
            result.InsertLast(maps_info[i]);
        }
    }

    return result;
}

int CountAuthorMedals(array<MapDataHolder::DataHolder@> maps_info) 
{
    int count = 0;
    for (int i = 0; i < maps_info.get_Length(); ++i) 
    {
        if (maps_info[i].medal == 4) 
        {
            ++count;
        }
    }
    return count;
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

string UpdateUidIfNewPB() {
    auto app = cast<CTrackMania>(GetApp());
	auto network = cast<CTrackManiaNetwork>(app.Network);
    while(network.ClientManiaAppPlayground is null){
        yield();
    }
    string mapUid = "";
    int newPBTime = -1;

    auto map = app.RootMap;
    auto userMgr = network.ClientManiaAppPlayground.UserMgr;
    auto scoreMgr = network.ClientManiaAppPlayground.ScoreMgr;
    MwId userId;
    if (userMgr.Users.Length > 0) {
        userId = userMgr.Users[0].Id;
    } else {
        userId.Value = uint(-1);
    }
    mapUid = map.MapInfo.MapUid;
    if (currentPBMapUid != mapUid){
        currentPBTime = -1;
        currentPBMapUid = mapUid;
    }
    newPBTime = scoreMgr.Map_GetRecord_v2(userId, mapUid, "PersonalBest", "", "TimeAttack", "");
    // Compare new PB time with the current PB time
    if(newPBTime != currentPBTime) {
        currentPBMapUid = mapUid;
        currentPBTime = newPBTime;
        return mapUid;
    }
    return"";
}

void OnMapFinished() {
    sleep(1000);
    auto newUid = UpdateUidIfNewPB();
    if (newUid != ""){
        Json::Value newInfo = Helpers::GetMapInfoByUid(newUid).opIndex(0);
        string mapId = newInfo.Get("mapId");
        Json::Value recordInfo = Helpers::GetAccountRecordyMapId(mapId);
        if (mapsIndexByUid.Exists(mapId)){
            int idInList;
            mapsIndexByUid.Get(mapId, idInList);
            all_maps[idInList].UpdateData(newInfo, recordInfo);
            all_maps_for_search = GetFilteredMaps(all_maps, searchInput);
            all_maps_without_author_medal = GetMapsWithoutAuthorMedal(all_maps_for_search);
        }
        else{
            MapDataHolder::DataHolder mapData(newInfo, recordInfo);
            mapsIndexByUid.Set(mapId, all_maps.get_Length());
            all_maps.InsertLast(mapData);
            all_maps_for_search = GetFilteredMaps(all_maps, searchInput);
            all_maps_without_author_medal = GetMapsWithoutAuthorMedal(all_maps_for_search);
        }
    }
}

string currentPBMapUid = "";   // Stores UID of map for which the current PB was recorded
int currentPBTime = -1;        // Stores the current PB time

void AddAudiences(){
    NadeoServices::AddAudience("NadeoServices");
}
array<MapDataHolder::DataHolder@> all_maps;
array<MapDataHolder::DataHolder@> all_maps_without_author_medal;
array<MapDataHolder::DataHolder@> all_maps_for_search;
dictionary mapsIndexByUid = {};
bool showMedalMaps = true;
bool isResync = true;
bool stopHandling = false;
void Resync(){
    Json::Value@ allRecords = Helpers::GetAllAccountRecords();
    int mapCount = allRecords.get_Length();
    all_maps = {};
    Batch::Batch batches();
    for (int i = 0; i < mapCount; i++){
        Json::Value@ personalRecord = allRecords.opIndex(i);
        batches.AddMapId(personalRecord.Get("mapId"));
    }
    dictionary dict = {};
    array<Json::Value> all_map_infos;
    int globalID = 0;
    for (int i = 0; i < batches.batchHolders.get_Length(); i++){
        Json::Value@ mapInfoPerBatch = Helpers::GetMapInfoByArrayOfID(batches.batchHolders[i]);
        for (int j = 0; j < batches.batchHolders[i].get_Length(); j++){
                dict.Set(mapInfoPerBatch.opIndex(j).Get("mapId"),globalID);
                all_map_infos.InsertLast(mapInfoPerBatch.opIndex(j));
                globalID++;
        }

    }
    globalID = 0;
    for (int i = 0; i < batches.batchHolders.get_Length(); i++){
        Json::Value@ mapInfoPerBatch = Helpers::GetMapInfoByArrayOfID(batches.batchHolders[i]);
        for (int j = 0; j < batches.batchHolders[i].get_Length(); j++){
            Json::Value@ personalRecord = allRecords.opIndex(globalID);
            string mapId = personalRecord.Get("mapId");
            int idForMap;
            dict.Get(mapId, idForMap);
            Json::Value@ mapInfo = all_map_infos[idForMap];
            MapDataHolder::DataHolder mapData(mapInfo, personalRecord);
            mapsIndexByUid.Set(mapId, globalID);
            all_maps.InsertLast(mapData);
            globalID = globalID + 1;
        }
    }
    all_maps_for_search = GetFilteredMaps(all_maps, searchInput);
    all_maps_without_author_medal = GetMapsWithoutAuthorMedal(all_maps_for_search);

    Loading = false;
}

bool GoLoadMap = false;
string mapUrl = "";
bool audiencesAdded = false;
bool Loading = true;
void Main() {
    Resync();
    isResync = false;
    startnew(MainCoro);
}

void MainCoro() {
    auto app = cast<CTrackMania>(GetApp());
	auto network = cast<CTrackManiaNetwork>(app.Network);
    while (true) {
        yield();
        if (isResync){
            Resync();
            isResync = false;
        }
        if (searchMaps){
            all_maps_for_search = GetFilteredMaps(all_maps, searchInput);
            all_maps_without_author_medal = GetMapsWithoutAuthorMedal(all_maps_for_search);
            searchMaps = false;
        }
        if (GoLoadMap){
           // GetApp().ManiaTitleControlScriptAPI.PlayMap(mapUrl, "TrackMania/TM_PlayMap_Local", "");
            LoadMapNow(mapUrl, "TrackMania/TM_PlayMap_Local");
            GoLoadMap = false;
        }

        auto playground = app.CurrentPlayground;

        if (playground !is null && playground.GameTerminals.Length > 0) {
            auto terminal = playground.GameTerminals[0];
            auto gui_player = cast<CSmPlayer>(terminal.GUIPlayer);
            auto ui_sequence = terminal.UISequence_Current;
            
            if (gui_player !is null && ui_sequence == CGamePlaygroundUIConfig::EUISequence::Finish &&  !stopHandling) {
                stopHandling = true;
                OnMapFinished();
            } 
            else if (ui_sequence != CGamePlaygroundUIConfig::EUISequence::Finish){
                stopHandling = false;
            }
        }
    }
}
