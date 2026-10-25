"""A walk-in challenge room with world-space posters and three answer NPCs."""
def add_room(world,part,obj,sign,actor):
    model=obj('AdvancedRoom','Model');world.append(model);c=model['Children']
    part(c,'Challenge floor',(60,.67,-80),(92,.5,68),'C5B9A1','WoodPlanks')
    part(c,'Challenge back wall',(60,14.5,-114),(92,28,1),'34303D')
    for x in [14,106]:part(c,'Challenge side wall',(x,14.5,-80),(1,28,68),'E2DCD0')
    # Open front and a skylight keep third-person navigation and sight lines clear.
    for x in [20,100]:part(c,'Challenge canopy',(x,28.5,-80),(12,.6,68),'4B4552')
    for z in [-112,-48]:part(c,'Challenge roof beam',(60,28.5,z),(92,.8,1.0),'4B4552')
    for x in [16,104]:part(c,'Challenge edge light',(x,27.9,-80),(.15,.2,62),'FFE2A3','Neon',collide=False)
    sign(c,'Challenge entry title',(60,20,-47),(54,4,.4),'따봉 챌린지','FFFFFF','34303D')
    board=part(c,'ConditionBoard',(60,23,-112.8),(82,5,.3),'27242F',collide=False);board['Properties']['CanQuery']=True
    for i,x in enumerate([31,60,89],1):
        panel=part(c,'ChoiceBoard'+str(i),(x,13.2,-112.6),(25,13.5,.35),'F5F1E8',collide=False);panel['Properties']['CanQuery']=True
        sign(c,'Choice floor number '+str(i),(x,1.2,-102),(7,4,.2),str(i),'FFFFFF','DF1940',rot=(-90,0,0))
        npc=actor('AnswerNPC'+str(i),x,-105,['6F8F8B','B5997E','A78F9E'][i-1],['51444A','242632','6C594C'][i-1])
        for p in npc['Children']:
            if p['ClassName'] in ['Part','WedgePart']:p['Properties']['CanCollide']=False
    console=part(c,'ChallengeConsole',(24,5.4,-74),(24,8,.4),'27242F',rot=(0,55,0),collide=False);console['Properties']['CanQuery']=True
    # Connect the entrance to the existing route; no detour through a flower bed.
    for x in range(-32,61,2):part(c,'Challenge approach',(x,.83,-43),(2.1,.32,11),'B39770','WoodPlanks')
    for z in [-46,-49]:part(c,'Challenge approach',(60,.83,z),(11,.32,3.1),'B39770','WoodPlanks')
    return model
