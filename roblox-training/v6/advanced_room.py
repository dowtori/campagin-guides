"""Compact three-bay pavilion; scene and native boards have identical proportions."""
def add_room(world,part,obj,sign,actor):
    model=obj('AdvancedRoom','Model');world.append(model);c=model['Children']
    part(c,'Challenge floor',(60,.67,-73),(56,.5,36),'C5AD8D','WoodPlanks')
    part(c,'Challenge back wall',(60,13,-91),(56,24.5,1),'34343B')
    for x in [32,88]:
        part(c,'Challenge side wall',(x,8,-73),(.65,14.5,36),'F5F4F0')
        part(c,'Challenge timber post',(x,13,-56),(.7,24.5,.7),'786B60','Wood')
        part(c,'Challenge canopy',(x,25.5,-73),(4,.6,36),'494653','Slate')
    for z in [-90,-55]:part(c,'Challenge roof beam',(60,25.5,z),(56,.65,.7),'494653','Slate')
    sign(c,'Challenge entry title',(60,24,-55),(19,2.4,.25),'따봉 챌린지','FFFFFF','34343B')
    board=part(c,'ConditionBoard',(60,20.5,-89.8),(52,6.5,.3),'27242F',collide=False);board['Properties']['CanQuery']=True
    for i,x in enumerate([42,60,78],1):
        part(c,'Answer bay frame',(x,12.04,-90.2),(17,10.92,.45),'B39770','Wood')
        panel=part(c,'ChoiceBoard'+str(i),(x,12.04,-89.6),(16,9.92,.35),'F5F1E8',collide=False);panel['Properties']['CanQuery']=True
        part(c,'Answer bay plinth',(x,1.05,-85),(12,.35,6),'D8C9B1','Sandstone')
        sign(c,'Choice floor number '+str(i),(x,1.26,-80.5),(3,3,.10),str(i),'FFFFFF','34343B',rot=(-90,0,0))
        npc=actor('AnswerNPC'+str(i),x,-85,['6F8F8B','B5997E','A78F9E'][i-1],['51444A','242632','6C594C'][i-1])
        for p in npc['Children']:
            if p['ClassName'] in ['Part','WedgePart']:p['Properties']['CanCollide']=False
    # A low desk is visible on arrival, below the answer buttons and NPC faces.
    part(c,'Challenge console pedestal',(60,1.9,-76),(12,2.0,2.2),'786B60','Wood')
    console=part(c,'ChallengeConsole',(60,3.35,-74.8),(13.5,4.5,.4),'27242F',collide=False);console['Properties']['CanQuery']=True
    for x in range(-32,61,2):part(c,'Challenge approach',(x,.83,-43),(2.1,.32,11),'B39770','WoodPlanks')
    for z in range(-46,-56,-2):part(c,'Challenge approach',(60,.83,z),(11,.32,2.1),'B39770','WoodPlanks')
    return model
