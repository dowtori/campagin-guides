"""Native lighting settings. Solar direction follows the Roblox lighting axes."""
import math
CLOCK_TIME=15.6
LATITUDE=-56.0
lat=math.radians(LATITUDE-23.5);lon=math.radians((CLOCK_TIME-6)*15)
SUN_DIRECTION=[math.cos(lat)*math.cos(lon),math.cos(lat)*math.sin(lon),math.sin(lat)]
SUN_POSITION=[v*1250 for v in SUN_DIRECTION]
def lighting(rgb):
    return {'$properties':{'LightingStyle':'Realistic','PrioritizeLightingQuality':True,
      'Ambient':rgb('82748C'),'OutdoorAmbient':rgb('B0A0B9'),'Brightness':2.8,
      'ExposureCompensation':.12,'ClockTime':CLOCK_TIME,'GeographicLatitude':LATITUDE,
      'GlobalShadows':True,'ShadowSoftness':.25,'ColorShift_Top':rgb('FFC681'),
      'EnvironmentDiffuseScale':1,'EnvironmentSpecularScale':1},
      'Atmosphere':{'$className':'Atmosphere','$properties':{'Density':.30,'Offset':.12,'Color':rgb('F0CCA0'),'Decay':rgb('89778F'),'Haze':1.6,'Glare':.38}},
      'Sky':{'$className':'Sky','$properties':{'CelestialBodiesShown':True,'StarCount':0,'SunAngularSize':2.8,'MoonAngularSize':0}},
      'Bloom':{'$className':'BloomEffect','$properties':{'Intensity':.24,'Size':36,'Threshold':1.25}},
      'SunRays':{'$className':'SunRaysEffect','$properties':{'Intensity':.075,'Spread':.78}},
      'SunsetGrade':{'$className':'ColorCorrectionEffect','$properties':{'Brightness':.015,'Contrast':.06,'Saturation':-.03,'TintColor':rgb('FFE9D2')}}}
