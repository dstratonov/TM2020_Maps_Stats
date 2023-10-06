namespace Batch{
    class Batch
    {
        array<array<string>> batchHolders;
        Batch(){
            batchHolders.InsertLast(array<string>());
        }
        void AddMapId(string mapId)
        {
            int lastIndex = batchHolders.get_Length() - 1;
            if (batchHolders[lastIndex].get_Length() < 200){
                batchHolders[lastIndex].InsertLast(mapId);
            }
            else{
                batchHolders.InsertLast(array<string>());
                batchHolders[lastIndex + 1].InsertLast(mapId);
            }
        }
    }
}