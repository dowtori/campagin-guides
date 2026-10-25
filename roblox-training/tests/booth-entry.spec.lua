local H=require('./ServerHarness')
local Curriculum=require('./Curriculum')
require('./TrainingServer')
local n=0
local function expect(v,m)n+=1 assert(v,m)end
H.players.PlayerAdded:Emit(H.player)
local future=Curriculum.stages[6].position;H.root.Position=H.Vector3.new(future[1],4,future[3])
H.send({kind='open',stage=6});expect(H.last('notice')~=nil,'future booth explains its gate')
for id,stage in ipairs(Curriculum.stages)do
    local x,z=stage.position[1],stage.position[3]
    for _,corner in ipairs({{-24,-22},{24,-22},{-24,22},{24,22}})do
        H.root.Position=H.Vector3.new(x+corner[1],4,z+corner[2]);H.send({kind='open',stage=id})
        expect(H.last('question').question.stage==id,'whole booth can start stage '..id)
    end
    for i,q in ipairs(stage.questions)do
        local token=i==1 and H.last('question').token or H.last('result').token
        H.send({kind='answer',token=token,answer=q.answer})
        expect(H.last('result').correct,'stage '..id..' activity '..i..' completes')
    end
    expect(H.last('state').snapshot.completed==id,'stamp retained stage '..id)
end
H.root.Position=H.Vector3.new(500,4,500)
local before=#H.packets;H.send({kind='open',stage=1});expect(#H.packets==before,'remote start outside booth rejected')
for _,id in ipairs({'1',-1,99,.5})do H.send({kind='open',stage=id})end
expect(#H.packets==before,'malformed stage ids rejected')
print(string.format('PASS: %d booth entry/server checks; all 6 booths x 4 corners, all 18 activities, gates and distance validation',n))
