-- Shared content-driven dialog geometry. Native text/layout measurements are inputs.
local Layout={}
function Layout.measure(viewWidth,viewHeight,titleHeight,contentHeight,hasSecondary)
 local width=math.min(560,math.max(240,viewWidth-32))
 local maxHeight=math.max(240,math.min(780,viewHeight-32))
 local heading=math.max(36,titleHeight or 0)
 local bodyY=56+heading+20
 local footer=24+52+(hasSecondary and 64 or 0)
 local content=math.max(0,math.ceil(contentHeight or 0))
 local gap=content>0 and 20 or 0
 local bodyHeight=math.max(0,math.min(content,maxHeight-bodyY-footer-gap))
 local height=bodyY+bodyHeight+gap+footer
 return {width=width,height=height,bodyY=bodyY,bodyHeight=bodyHeight,
  primaryY=height-76,secondaryY=height-140,scrolls=bodyHeight<content,
  centered=viewWidth<700 or viewHeight<500}
end
return Layout
