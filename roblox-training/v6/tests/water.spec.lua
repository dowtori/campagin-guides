local H=require('./WaterHarness')
local run=require('./WaterServer')
local n=0
local function expect(v,m)n+=1;assert(v,m)end
for _,modern in ipairs({true,false})do
 H.reset(modern,false);run()
 expect(H.attributes.SiriaiOceanReady==true,'real terrain initialized')
 expect(#H.fills==40,'twenty bounded water edits and twenty seabed edits')
 for _,fill in ipairs(H.fills)do expect(fill.size.X*fill.size.Y*fill.size.Z/64<4194304,'region under terrain API limit')end
 expect(H.chunks>60,'native high ridges and coast written')
 expect(H.previewParts[1].CanCollide==false,'preview replaced by actual terrain')
 H.root.Position=H.Vector3.new(0,-39,-500);H.run.Heartbeat:Fire(.2)
 expect(H.returns==1 and H.humanoid.Health==100,'rescue does not damage player')
end
H.reset(true,true);run()
expect(H.attributes.SiriaiOceanReady==false and H.warning~=nil,'terrain API failure is visible')
expect(H.previewParts[1].CanCollide==true,'safe ground remains on failure')
H.root.Position=H.Vector3.new(0,-50,-500);H.run.Heartbeat:Fire(.2);expect(H.returns==1 and H.humanoid.Health==100,'rescue works even if terrain API fails')
print('PASS: '..n..' actual water-server API/startup/fallback/failure/rescue checks')
