local shared=game:GetService('ReplicatedStorage'):WaitForChild('CampusShared')
local ok,reason=xpcall(function()require(shared:WaitForChild('CampusClient')).start(script.Parent)end,debug.traceback)
if not ok then
    script.Parent:WaitForChild('Status').Text='교육 화면을 준비하지 못했어요. 다시 플레이해주세요.'
    warn('[SIRIAI v6 UI] '..tostring(reason))
end
