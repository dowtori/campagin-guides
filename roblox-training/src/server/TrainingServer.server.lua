-- All progress and answer validation run on the server. No HTTP or DataStore required.
local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ProximityPromptService = game:GetService('ProximityPromptService')
local HttpService = game:GetService('HttpService')
local Curriculum = require(script.Parent.Curriculum)
local Engine = require(script.Parent.TrainingEngine)
local remote = ReplicatedStorage:WaitForChild('TrainingEvent')
local map = workspace:WaitForChild('TrainingMap')
local stations = map:WaitForChild('Stations')
local sessions, terminals = {}, {}

for _, stage in ipairs(Curriculum.stages) do
    terminals[stage.id] = stations:WaitForChild(string.format('Station%02d', stage.id)):WaitForChild('Terminal')
end

local function getSession(player)
    if not sessions[player] then
        sessions[player] = {state = Engine.new(), token = '', checkpoint = 0, lastJump = -10, lastHello = -10}
    end
    return sessions[player]
end

local function notice(player, text)
    remote:FireClient(player, {kind = 'notice', text = text})
end

local function sync(player)
    local session = getSession(player)
    local snapshot = Engine.snapshot(session.state, Curriculum)
    local stats = player:FindFirstChild('leaderstats')
    if stats then stats:FindFirstChild('스탬프').Value = snapshot.completed end
    player:SetAttribute('TrainingComplete', snapshot.finished)
    remote:FireClient(player, {kind = 'state', snapshot = snapshot})
end

local function publicStages()
    local result = {}
    for _, stage in ipairs(Curriculum.stages) do
        table.insert(result, {id = stage.id, title = stage.title, subtitle = stage.subtitle, color = stage.color})
    end
    return result
end

local function teleport(player, id)
    local character = player.Character
    local root = character and character:FindFirstChild('HumanoidRootPart')
    if not root then return end
    local humanoid=character:FindFirstChildOfClass('Humanoid')
    if humanoid and humanoid.SeatPart then
        local seat=humanoid.SeatPart
        humanoid.Sit=false
        local weld=seat:FindFirstChild('SeatWeld')
        if weld and weld:IsA('Weld') and weld.Part1 and weld.Part1:IsDescendantOf(character) then weld:Destroy() end
    end
    local position, focus
    if id == 0 then
        position, focus = Vector3.new(0, 4, 42), Vector3.new(0, 4, -30)
    elseif id == 8 then
        position, focus = Vector3.new(0,4,-263), Vector3.new(-200,40,-615)
    elseif id == 7 then
        position, focus = Vector3.new(0, 4, -143), Vector3.new(0, 7, -158)
    else
        local p = Curriculum.stages[id].position
        position = Vector3.new(p[1], 4, p[3] + 13)
        focus = terminals[id].Position
    end
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
    character:PivotTo(CFrame.lookAt(position, Vector3.new(focus.X, position.Y, focus.Z)))
end

local function atTerminal(player, id)
    local root = player.Character and player.Character:FindFirstChild('HumanoidRootPart')
    return root and (root.Position - terminals[id].Position).Magnitude <= 27
end

local function openStage(player, id)
    if not atTerminal(player, id) then return end
    local session = getSession(player)
    local ok, reason = Engine.open(session.state, Curriculum, id)
    if not ok then notice(player, reason) return end
    session.checkpoint = id
    session.token = HttpService:GenerateGUID(false)
    remote:FireClient(player, {kind = 'question', question = Engine.question(session.state, Curriculum), token = session.token})
end

ProximityPromptService.PromptTriggered:Connect(function(prompt, player)
    if not prompt:IsDescendantOf(stations) then return end
    local station = prompt.Parent and prompt.Parent.Parent
    local id = station and tonumber(station.Name:match('Station(%d+)$'))
    if id and terminals[id] == prompt.Parent then openStage(player, id) end
end)

remote.OnServerEvent:Connect(function(player, packet)
    if type(packet) ~= 'table' or type(packet.kind) ~= 'string' then return end
    local session = getSession(player)
    if packet.kind == 'hello' then
        if os.clock() - session.lastHello < 1 then return end
        session.lastHello = os.clock()
        remote:FireClient(player, {kind = 'welcome', stages = publicStages(), snapshot = Engine.snapshot(session.state, Curriculum)})
        sync(player)
    elseif packet.kind == 'answer' then
        if type(packet.token) ~= 'string' or packet.token ~= session.token or not session.state.active then return end
        local activeId = session.state.active.stage
        if not atTerminal(player, activeId) then
            session.token = ''
            session.state.active = nil
            remote:FireClient(player, {kind = 'close', text = '단말기 가까이에서 다시 시작해주세요.'})
            return
        end
        session.token = '' -- consume nonce before processing the answer
        local result = Engine.answer(session.state, Curriculum, packet.answer)
        if not result then return end
        session.token = result.question and HttpService:GenerateGUID(false) or ''
        result.kind, result.token = 'result', session.token
        remote:FireClient(player, result)
        sync(player)
    elseif packet.kind == 'relax' then
        if os.clock() - session.lastJump < 0.8 then return end
        session.lastJump = os.clock()
        session.token, session.state.active = '', nil
        remote:FireClient(player, {kind='relax'})
        teleport(player, 8)
    elseif packet.kind == 'return' then
        if os.clock() - session.lastJump < 0.8 then return end
        session.lastJump = os.clock()
        session.token, session.state.active = '', nil
        remote:FireClient(player, {kind='close'})
        teleport(player, session.checkpoint)
    elseif packet.kind == 'jump' then
        local id = packet.stage
        if type(id) ~= 'number' or id % 1 ~= 0 or id < 0 or id > 7 then return end
        if os.clock() - session.lastJump < 0.8 then return end
        session.lastJump = os.clock()
        local snapshot = Engine.snapshot(session.state, Curriculum)
        if id == 7 and not snapshot.finished then notice(player, '6개 미션을 마치면 수료 데크로 이동할 수 있어요.') return end
        if id >= 1 and id <= 6 and id > session.state.progress then notice(player, '앞의 미션부터 완료해주세요 :)') return end
        session.token, session.state.active = '', nil
        if id >= 1 and id <= 6 then session.checkpoint = id end
        remote:FireClient(player, {kind = 'close'})
        teleport(player, id)
    elseif packet.kind == 'close' then
        session.token, session.state.active = '', nil
    elseif packet.kind == 'restart' then
        session.state, session.token, session.checkpoint = Engine.new(), '', 0
        remote:FireClient(player, {kind = 'close', text = '처음부터 다시 연습해요 :)'})
        sync(player)
        teleport(player, 0)
    end
end)

local function onPlayer(player)
    getSession(player)
    local stats = Instance.new('Folder')
    stats.Name, stats.Parent = 'leaderstats', player
    local stamps = Instance.new('IntValue')
    stamps.Name, stamps.Parent = '스탬프', stats
    player.CharacterAdded:Connect(function(character)
        local session = getSession(player)
        local returning = session.characterSeen == true
        session.characterSeen = true
        local root = character:WaitForChild('HumanoidRootPart', 15)
        if not root then return end
        task.wait(0.15)
        if not player.Parent then return end
        if returning then session.state.active, session.token = nil, '' end
        teleport(player, session.checkpoint)
        if returning then remote:FireClient(player, {kind = 'close'}) end
        sync(player)
    end)
end

Players.PlayerAdded:Connect(onPlayer)
Players.PlayerRemoving:Connect(function(player) sessions[player] = nil end)
for _, player in ipairs(Players:GetPlayers()) do onPlayer(player) end
print('[SIRIAI] Training Campus loaded: 6 stations / 18 activities')
