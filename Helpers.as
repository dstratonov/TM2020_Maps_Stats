namespace Helpers{
    Json::Value@ GetMapInfoByID(string id){
        string mapLink = "https://prod.trackmania.core.nadeo.online/maps/?mapIdList=" + id;
        Net::HttpRequest@ map_request = NadeoServices::Get("NadeoServices", mapLink);
        map_request.Start();
        while(!map_request.Finished()){
            yield();
        }
        return map_request.Json();
    }

    Json::Value@ GetMapInfoByArrayOfID(array<string> idOfMaps){
        string ids = idOfMaps[0];
        for (int i = 1; i < idOfMaps.get_Length(); i++){
            ids = ids + "," + idOfMaps[i];
        }

        string mapLink = "https://prod.trackmania.core.nadeo.online/maps/?mapIdList=" + ids + "&" + "seasonId=Personal_Best";
        Net::HttpRequest@ map_request = NadeoServices::Get("NadeoServices", mapLink);
        map_request.Start();
        while(!map_request.Finished()){
            yield();
        }
        return map_request.Json();
    }

    Json::Value@ GetAllAccountRecords(){
        string accountID = GetApp().LocalPlayerInfo.WebServicesUserId;
        string requestLink = "https://prod.trackmania.core.nadeo.online/mapRecords/?accountIdList=" + accountID + "&addPersonalBest=true";
        Net::HttpRequest@ request = NadeoServices::Get("NadeoServices", requestLink);
        request.Start();
        while (!request.Finished()) {
            yield();
        }
        return request.Json();
    }
}