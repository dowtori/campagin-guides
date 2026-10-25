local H=require('./ServerHarness')
local Curriculum=require('./Curriculum')
require('./TrainingServer')
local n=0
local function expect(value,message)n+=1 assert(value,message)end
H.players.PlayerAdded:Emit(H.player)
H.send({kind='hello'})
expect(H.last('state').snapshot.completed==0,'fresh player')
H.send({kind='jump',stage=1});H.prompt(1)
for _,q in ipairs(Curriculum.stages[1].questions)do
    local packet=H.last('result') or H.last('question')
    H.send({kind='answer',token=packet.token,answer=q.answer})
end
expect(H.last('state').snapshot.completed==1,'first stamp earned')
H.send({kind='jump',stage=2});H.prompt(2)
H.send({kind='answer',token=H.last('question').token,answer=Curriculum.stages[2].questions[1].answer})
local stale=H.last('result').token
H.send({kind='relax'})
expect(H.last('relax')~=nil,'rest acknowledged')
expect(H.root.Position.Z==-263,'rest lookout reached')
expect(H.last('state').snapshot.completed==1,'rest preserves stamps')
local packets=#H.packets
H.send({kind='answer',token=stale,answer=Curriculum.stages[2].questions[2].answer})
expect(#H.packets==packets,'old active answer is invalidated')
-- Returning while seated releases only the character's own seat weld.
local seat=H.Instance.new('Seat');H.humanoid.SeatPart=seat;H.humanoid.Sit=true
local weld=H.Instance.new('Weld');weld.Name='SeatWeld';weld.Part1=H.root;weld.Parent=seat
H.send({kind='return'})
expect(H.humanoid.Sit==false and weld.Destroyed,'stand before return')
expect(H.root.Position.X==38 and H.root.Position.Z==21,'return to last station')
H.prompt(2)
expect(H.last('question').question.step==2,'partial lesson resumes')
H.send({kind='hello'})
expect(H.last('state').snapshot.completed==1,'stamp survives return')
H.send({kind='jump',stage=6})
expect(H.last('notice').text:find('앞의 미션')~=nil,'rest does not unlock future missions')
H.send({kind='jump',stage=8})
expect(H.root.Position.X==38,'out-of-range jump is rejected')
print(string.format('PASS: %d real server rest/return checks; stamp retention, partial resume, nonce rejection, seat release, gates',n))
