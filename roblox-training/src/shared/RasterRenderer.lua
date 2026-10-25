-- Decode the actual company/generated pixels embedded in this place.
local R={}
local Data=require(script.Parent:WaitForChild('RasterAssets'))
local cache={}
local imageAvailable=true
local function color(hex)return Color3.fromHex(hex:sub(1,6))end
function R.editable(key)
    if cache[key] then return cache[key] end
    if not imageAvailable then return nil end
    local a=Data[key];if not a then return nil end
    local ok,image=pcall(function()
        local img=game:GetService('AssetService'):CreateEditableImage({Size=Vector2.new(a.width,a.height)})
        assert(img,'No editable image memory available')
        local pixels=buffer.create(a.width*a.height*4);local offset=0
        for _,run in ipairs(a.runs) do
            local hex=a.palette[run[1]+1]
            local rgba=string.char(tonumber(hex:sub(1,2),16),tonumber(hex:sub(3,4),16),tonumber(hex:sub(5,6),16),tonumber(hex:sub(7,8),16))
            local bytes=buffer.fromstring(string.rep(rgba,run[2]));buffer.copy(pixels,offset,bytes);offset+=run[2]*4
        end
        img:WritePixelsBuffer(Vector2.zero,Vector2.new(a.width,a.height),pixels)
        return img
    end)
    if not ok then imageAvailable=false return nil end
    cache[key]=image;return image
end
function R.draw(parent,key,position,size)
    local a=Data[key];assert(a,'Unknown image '..tostring(key))
    local root=Instance.new('Frame');root.Name='Image_'..key;root.Position=position or UDim2.fromScale(0,0);root.Size=size or UDim2.fromScale(1,1);root.BackgroundTransparency=1;root.BorderSizePixel=0;root.ClipsDescendants=true;root.Parent=parent
    local img=R.editable(key)
    local success=false
    if img then
        success=pcall(function()
            local label=Instance.new('ImageLabel');label.Name='FullImage';label.Size=UDim2.fromScale(1,1);label.BackgroundTransparency=1
            label.ImageContent=Content.fromObject(img);label.ResampleMode=Enum.ResamplerMode.Pixelated;label.Parent=root
        end)
    end
    if not success then
        for _,p in ipairs(a.rects) do
            local f=Instance.new('Frame');f.Position=UDim2.fromScale(p[1]/a.fallbackWidth,p[2]/a.fallbackHeight);f.Size=UDim2.fromScale(p[3]/a.fallbackWidth,p[4]/a.fallbackHeight);f.BackgroundColor3=color(a.fallbackPalette[p[5]+1]);f.BorderSizePixel=0;f.Parent=root
        end
    end
    return root
end
function R.upgrade(surface,key)
    local img=R.editable(key);if not img then
        local fallback=surface:FindFirstChild('Pixels')
        if not fallback or #fallback:GetChildren()==0 then R.draw(surface,key) end
        return false
    end
    local ok,label=pcall(function()
        local l=Instance.new('ImageLabel');l.Name='FullImage';l.Size=UDim2.fromScale(1,1);l.BackgroundTransparency=1;l.ImageContent=Content.fromObject(img);l.ResampleMode=Enum.ResamplerMode.Pixelated;return l
    end)
    if not ok then
        local fallback=surface:FindFirstChild('Pixels')
        if not fallback or #fallback:GetChildren()==0 then R.draw(surface,key) end
        return false
    end
    local fallback=surface:FindFirstChild('Pixels');if fallback then fallback.Visible=false end
    label.Parent=surface;return true
end
return R
