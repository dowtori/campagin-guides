local folder=script.Parent:WaitForChild('RasterData')
local allowed={sky=true,skySides=true,logo=true,logoWhite=true,wordmark=true,settings=true,options=true,profile=true,booth1=true,booth2=true,booth3=true,booth4=true,booth5=true,booth6=true}
return setmetatable({},{__index=function(self,key)
 if not allowed[key]then return nil end
 local data=require(folder:WaitForChild(key))
 rawset(self,key,data)
 return data
end})
