local Engine = require('./TrainingEngine')
local Curriculum = require('./Curriculum')
local checks = 0
local function expect(condition, message)
    checks += 1
    assert(condition, message)
end
local state = Engine.new()
expect(Engine.snapshot(state,Curriculum).completed == 0,'fresh progress')
expect(not Engine.open(state,Curriculum,2),'future station must stay locked')
expect(not Engine.open(state,Curriculum,-1),'negative station')
expect(not Engine.open(state,Curriculum,1.5),'fractional station')
expect(not Engine.open(state,Curriculum,'1'),'string station')
expect(Engine.answer(state,Curriculum,'a') == nil,'answer without opening')
for _,stage in ipairs(Curriculum.stages) do
    expect(Engine.open(state,Curriculum,stage.id),'current station opens')
    for index,q in ipairs(stage.questions) do
        local public=Engine.question(state,Curriculum)
        expect(public.stage==stage.id and public.step==index,'correct public cursor')
        expect(public.answer==nil and public.explanation==nil,'answer key stays on server')
        local invalids=q.mode=='sequence' and {{}, {q.answer[1]}, {'duplicate','duplicate'}, 'wrong', {true,1,{}}} or {false,1,{},'unknown'}
        for _,bad in ipairs(invalids) do
            local result=Engine.answer(state,Curriculum,bad)
            expect(not result.correct,'malformed or wrong input must fail')
            expect(Engine.question(state,Curriculum).step==index,'wrong answer must not advance')
        end
        local result=Engine.answer(state,Curriculum,q.answer)
        expect(result.correct,'correct answer accepted')
        if index<#stage.questions then
            state.active=nil -- close modal and open again, as server does
            expect(Engine.open(state,Curriculum,stage.id),'reopen station')
            expect(Engine.question(state,Curriculum).step==index+1,'partial progress resumes')
        else
            expect(result.stageComplete,'station completes only after all steps')
            expect(result.snapshot.completed==stage.id,'one stamp per station')
        end
    end
    if stage.id<6 then expect(not Engine.open(state,Curriculum,stage.id+2),'skip locked stage') end
end
local completed=Engine.snapshot(state,Curriculum)
expect(completed.finished and completed.completed==6,'full course completion')
expect(Engine.answer(state,Curriculum,'a')==nil,'completed answer cannot duplicate stamp')
for _,stage in ipairs(Curriculum.stages) do
    expect(Engine.open(state,Curriculum,stage.id),'completed station can be replayed')
    expect(Engine.question(state,Curriculum).review,'replay mode')
    for _,q in ipairs(stage.questions) do
        local result=Engine.answer(state,Curriculum,q.answer)
        expect(result.snapshot.completed==6,'replay cannot duplicate or remove stamps')
    end
end
local fresh=Engine.new()
expect(Engine.snapshot(fresh,Curriculum).completed==0,'restart clears personal progress')
local question=Curriculum.stages[2].questions[2]
local extra=table.clone(question.answer); extra.extra=true
expect(not Engine.isCorrect(question,extra),'sequence rejects unexpected dictionary keys')
local reversed=table.clone(question.answer); reversed[1],reversed[2]=reversed[2],reversed[1]
expect(not Engine.isCorrect(question,reversed),'sequence must follow actual order')
for _,stage in ipairs(Curriculum.stages) do for _,q in ipairs(stage.questions) do
    local s=Engine.new();s.progress=stage.id;Engine.open(s,Curriculum,stage.id);s.active.index=table.find(stage.questions,q)
    local public=Engine.question(s,Curriculum)
    expect(public.visual and public.visual.kind,'every activity has visual metadata')
    if q.mode=='form' then
        local extra=table.clone(q.answer);extra.unexpected=true
        expect(not Engine.isCorrect(q,extra),'form rejects unexpected fields')
        for key in pairs(q.answer) do
            local missing=table.clone(q.answer);missing[key]=nil
            expect(not Engine.isCorrect(q,missing),'form requires every field')
        end
    end
end end
print(string.format('PASS: %d assertions; 18 activities; gating, retries, resume, replay, completion, malformed input',checks))
