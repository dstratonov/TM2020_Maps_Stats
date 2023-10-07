


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
    if (UI::Begin("Map Manager Plugin", S_WindowOpen, UI::WindowFlags::AlwaysAutoResize)) {
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

void RenderMapsStatsTable(array<MapDataHolder::DataHolder@> maps_info) 
{
    int totalMaps = maps_info.get_Length();
    int totalPages = (totalMaps + mapsPerPage - 1) / mapsPerPage; // Calculate the total number of pages.

    // Table Begin
    if (UI::BeginTable("Maps stats", 6, UI::TableFlags::SizingFixedFit)) 
    {
        // Header
        UI::TableNextRow();
        
        // 1. Stats - maps with author medal / total maps
        UI::TableNextColumn();
        UI::Text("Map stats: " + CountAuthorMedals(maps_info) + " / " + totalMaps);

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
        if (UI::Button("Resync")) 
        {
            if (!isResync){
                isResync = true;
            }
        }

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
        UI::Text("Distance");

        UI::TableNextColumn();
        UI::Text("Medal");

        UI::TableNextColumn();
        UI::Text("Score");

        UI::TableNextColumn();
        UI::Text("Timestamp");

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

            // 2. Author time difference (Assuming a dummy value for now)
            UI::TableNextColumn();
            UI::Text("" + (maps_info[i].recordTime - maps_info[i].authorScore) / 1000.0); 

            // 3. Author medal get
            UI::TableNextColumn();
            UI::Text(maps_info[i].medal >= 4 ? ColoredString("$0f0Author Medal")  : ColoredString("$f00Lower medal"));

            // 4. Record score
            UI::TableNextColumn();
            UI::Text("" + maps_info[i].recordTime / 1000.0);

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
}

array<MapDataHolder::DataHolder@> GetFilteredMaps(array<MapDataHolder::DataHolder@> maps_info, const string searchTerm) 
{
    array<MapDataHolder::DataHolder@> result;

    for (uint i = 0; i < maps_info.get_Length(); i++) 
    {
        if (Regex::Contains(maps_info[i].mapName, searchTerm, Regex::Flags::ECMAScript)) 
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


void AddAudiences(){
    NadeoServices::AddAudience("NadeoServices");
}
array<MapDataHolder::DataHolder@> all_maps;
array<MapDataHolder::DataHolder@> all_maps_without_author_medal;
array<MapDataHolder::DataHolder@> all_maps_for_search;
bool showMedalMaps = true;
bool isResync = true;
void Resync(){
    Json::Value@ allRecords = Helpers::GetAllAccountRecords();
    int mapCount = allRecords.get_Length();
    //int maximumCount = 200;
    //mapCount = maximumCount < mapCount ? maximumCount : mapCount;
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
            all_maps.InsertLast(mapData);
            globalID = globalID + 1;
        }
    }
    all_maps_for_search = GetFilteredMaps(all_maps, searchInput);
    all_maps_without_author_medal = GetMapsWithoutAuthorMedal(all_maps_for_search);

    print(all_maps.get_Length());
}

bool GoLoadMap = false;
string mapUrl = "";
bool audiencesAdded = false;
void Main() {
    Resync();
    isResync = false;
    startnew(MainCoro);
}

void MainCoro() {
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
    }
}
