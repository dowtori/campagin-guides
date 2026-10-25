-- Pure training state machine. No Roblox services; exercised by tests/engine.spec.lua.
local Engine = {}

function Engine.new()
    return {progress = 1, completed = {}, cursors = {}, active = nil}
end

function Engine.snapshot(state, curriculum)
    local completed, flags = 0, {}
    for id = 1, #curriculum.stages do
        flags[id] = state.completed[id] == true
        if flags[id] then completed += 1 end
    end
    return {
        progress = math.min(state.progress, #curriculum.stages),
        completed = completed,
        flags = flags,
        total = #curriculum.stages,
        finished = completed == #curriculum.stages,
    }
end

function Engine.open(state, curriculum, stageId)
    if type(stageId) ~= 'number' or stageId % 1 ~= 0 or not curriculum.stages[stageId] then
        return false, '미션을 찾을 수 없어요.'
    end
    if stageId > state.progress then
        return false, '앞의 미션부터 차근차근 완료해주세요 :)'
    end
    local review = state.completed[stageId] == true
    state.active = {stage = stageId, index = review and 1 or (state.cursors[stageId] or 1), review = review}
    return true
end

function Engine.question(state, curriculum)
    if not state.active then return nil end
    local active = state.active
    local stage = curriculum.stages[active.stage]
    local source = stage.questions[active.index]
    local choices = {}
    for i, choice in ipairs(source.options or {}) do
        choices[i] = {id = choice.id, text = choice.text}
    end
    -- Never send the answer key to the client.
    return {
        id = source.id, mode = source.mode, title = source.title,
        context = source.context, options = choices, visual = source.visual,
        stage = stage.id, stageTitle = stage.title, stageIntro = stage.intro,
        step = active.index, steps = #stage.questions, review = active.review,
    }
end

function Engine.isCorrect(question, answer)
    if question.mode == 'form' then
        if type(answer) ~= 'table' then return false end
        local expectedCount,actualCount = 0,0
        for key,value in pairs(question.answer) do
            expectedCount += 1
            if answer[key] ~= value then return false end
        end
        for _ in pairs(answer) do actualCount += 1 end
        return actualCount == expectedCount
    end
    if question.mode == 'sequence' then
        if type(answer) ~= 'table' or #answer ~= #question.answer then return false end
        local count = 0
        for key in pairs(answer) do
            if type(key) ~= 'number' or key % 1 ~= 0 or key < 1 or key > #question.answer then
                return false
            end
            count += 1
        end
        if count ~= #question.answer then return false end
        for i, expected in ipairs(question.answer) do
            if answer[i] ~= expected then return false end
        end
        return true
    end
    return type(answer) == 'string' and answer == question.answer
end

function Engine.answer(state, curriculum, answer)
    if not state.active then return nil end
    local active = state.active
    local stage = curriculum.stages[active.stage]
    local question = stage.questions[active.index]
    local correct = Engine.isCorrect(question, answer)
    local result = {correct = correct, explanation = question.explanation, stage = stage.id, review = active.review}
    if correct then
        active.index += 1
        if not active.review then state.cursors[stage.id] = active.index end
        if active.index > #stage.questions then
            result.stageComplete = true
            if not active.review then
                state.completed[stage.id] = true
                state.progress = stage.id + 1
            end
            state.active = nil
        end
    end
    result.snapshot = Engine.snapshot(state, curriculum)
    result.question = Engine.question(state, curriculum)
    return result
end

return Engine
