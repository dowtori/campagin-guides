-- This tiny entry point renders status immediately, before loading any training modules.
local Players=game:GetService('Players')
local ReplicatedStorage=game:GetService('ReplicatedStorage')
local Prompts=game:GetService('ProximityPromptService')
local player=Players.LocalPlayer
local playerGui=player:WaitForChild('PlayerGui')
local gui=Instance.new('ScreenGui');gui.Name='SiriaiBoot';gui.ResetOnSpawn=false;gui.DisplayOrder=100;gui.Parent=playerGui
local status=Instance.new('TextButton');status.Size=UDim2.new(.9,0,0,62);status.Position=UDim2.new(.05,0,0,64);status.BackgroundColor3=Color3.fromRGB(37,36,56);status.TextColor3=Color3.new(1,1,1);status.Font=Enum.Font.GothamBold;status.TextSize=15;status.TextWrapped=true;status.Text='SIRIAI v4 · 교육 화면을 준비하고 있어요…';status.Parent=gui
local retrying=false
local function start()
    if retrying then return end
    retrying=true;status.Text='SIRIAI v4 · 교육 화면을 준비하고 있어요…';status.Visible=true
    local ok,message=xpcall(function()
        local shared=ReplicatedStorage:WaitForChild('TrainingShared',30);assert(shared,'TrainingShared를 찾지 못했습니다.')
        local module=shared:WaitForChild('ClientMain',30);assert(module,'ClientMain을 찾지 못했습니다.')
        require(module).start()
    end,debug.traceback)
    retrying=false
    if ok then gui:Destroy() else
        Prompts.Enabled=true
        status.Text='교육 화면 준비에 실패했어요. 여기를 눌러 다시 시도해주세요.\n'..tostring(message):sub(1,150)
        warn('[SIRIAI Client Startup] '..tostring(message))
    end
end
status.Activated:Connect(start)
start()
