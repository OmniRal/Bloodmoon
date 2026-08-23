-- OmniRal

local ServerGlobalValues = {}

ServerGlobalValues["AdminList"] = {
    {Name = "OmniRal", ID = 267421},
    {Name = "Blotnik", ID = 266280},
    {Name = "bennult", ID = 424583710},
}

ServerGlobalValues["PlayerTestList"] = {
    {Name = "Player1", ID = -1},
    {Name = "Player2", ID = -2},
}

local List_1 = {ServerGlobalValues.AdminList[1]}
local List_2 = {ServerGlobalValues.AdminList[1], ServerGlobalValues.AdminList[2]}
local List_3 = ServerGlobalValues.AdminList
local List_4 = ServerGlobalValues.PlayerTestList

--------------------------------------------------------------------------------------------

ServerGlobalValues["CleanupAssetDump"] = true



--------------------------------------------------------------------------------------------

return ServerGlobalValues