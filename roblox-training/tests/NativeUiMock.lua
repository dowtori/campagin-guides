-- Lightweight Instance/event adapter for exercising native UI callbacks in Luau CLI.
-- This is not a Roblox rendering engine or a replacement for Studio play testing.
local Mock={width=820}
local function event()
    local e={listeners={}}
    function e:Connect(fn)
        local slot={fn=fn,connected=true};table.insert(self.listeners,slot)
        return {Disconnect=function()slot.connected=false end}
    end
    function e:Fire(...)
        for _,s in ipairs(self.listeners) do if s.connected then s.fn(...) end end
    end
    return e
end
local Methods={}
function Methods:GetChildren() return table.clone(self.children) end
function Methods:IsA(name) return self.props.ClassName==name or (name=='GuiObject' and table.find({'Frame','TextButton','TextLabel','TextBox'},self.props.ClassName)~=nil) end
function Methods:GetPropertyChangedSignal(key)
    if not self.changes[key] then self.changes[key]=event() end
    return self.changes[key]
end
function Methods:Destroy()
    self.events.Destroying:Fire()
    for _,c in ipairs(table.clone(self.children)) do c:Destroy() end
    if self.props.Parent then
        local siblings=self.props.Parent.children
        local i=table.find(siblings,self);if i then table.remove(siblings,i) end
    end
    self.props.Parent=nil
end
local MT={
 __index=function(self,k) return Methods[k] or self.events[k] or self.props[k] end,
 __newindex=function(self,k,v)
    if k=='Parent' and v then table.insert(v.children,self) end
    local old=self.props[k];self.props[k]=v
    if old~=v and self.changes[k] then self.changes[k]:Fire() end
 end
}
Mock.Instance={new=function(class)
    return setmetatable({props={ClassName=class,Name=class,AbsoluteSize={X=Mock.width,Y=300}},events={Activated=event(),Destroying=event()},children={},changes={}},MT)
end}
Mock.Color3={fromRGB=function(r,g,b)return {r,g,b}end,fromHex=function(s)return s end,new=function(r,g,b)return {r,g,b}end}
Mock.UDim={new=function(s,o)return {Scale=s,Offset=o}end}
Mock.UDim2={new=function(xs,xo,ys,yo)return {X={Scale=xs or 0,Offset=xo or 0},Y={Scale=ys or 0,Offset=yo or 0}}end}
function Mock.UDim2.fromOffset(x,y)return Mock.UDim2.new(0,x,0,y)end
function Mock.UDim2.fromScale(x,y)return Mock.UDim2.new(x,0,y,0)end
Mock.Enum=setmetatable({},{__index=function(_,k)return setmetatable({},{__index=function(_,v)return k..'.'..v end})end})
Mock.game={GetService=function()return {}end}
return Mock
