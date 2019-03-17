import os
import arcpy, arcinfo
from arcpy import env
from arcpy.sa import *
from GOSTRocks.arcpyMisc import *
import time, subprocess
arcpy.CheckOutExtension("Spatial")
print 'Check out extension complete'


# 1. Set paths to shapefile and environmental datasets

access = r'E:\Andres_Data\Poverty_Economics\MarketAccess\accessibility_to_cities_2015_v1.0.tif'
gdp = r'F:\WorldBank\GDP\GDP.tif'
pollution = r'F:\WorldBank\Brauer\FusedCal2013_v2.tif'
soil_erosion = r'E:\Andres_Data\Environment\SoilErosion\Erosion_RUSLE_adjusted_5min.tif'
ruggedness = r'F:\WorldBank\Rug\rugg_index.tif'
road_density = r'F:\WorldBank\RoadDensity\GRIP_v3_total_SetNull.tif'
infant_mort_rate = r'F:\WorldBank\IMR\imrq.asc'
npp_trend = r'E:\Andres_Data\Environment\NPP_Slope\npp_slope_world.tif'
ndvi_trend = r'E:\Andres_Data\Environment\NPP_Slope\ndvi_slope_world.tif'
length_growing_period = r'F:\WorldBank\FAO\land_use_sytems\lgp.tif'
occurrence_pasture = r'F:\WorldBank\FAO\OccurrencePasture\pasture_re.tif'
# gpw = r'F:\WorldBank\GPW'
# pop weighted access Separate!

# rasters = dict([
# 	("nppt",npp_trend),
# 	("ndvit",ndvi_trend)
# 	])

rasters = dict([
	("acc",access),
	("gdp",gdp),
	("pm25",pollution),
	("soil",soil_erosion),
	("rugg",ruggedness),
	("road",road_density),
	("imr",infant_mort_rate),
	("nppt",npp_trend),
	("ndvit",ndvi_trend),
	("lgp",length_growing_period),
	("pas",occurrence_pasture)
	])

artemis = r'C:\Users\WB514197\OneDrive - WBG\FCV_Famine\Sources\Context_HD\artemis_countries.shp'
yemen = r'C:\Users\WB514197\OneDrive - WBG\FCV_Famine\Sources\Context_HD\Yemen_gadm2.shp'

outputFolder = 'C:/Users/WB514197/OneDrive - WBG/FCV_Famine/Sources/Context_HD/output_yem/'
if not os.path.exists(outputFolder):
    os.mkdir(outputFolder)

for raster in rasters:
    zs = ZonalStatisticsAsTable(yemen, "OBJECTID", rasters[raster], outputFolder + str(raster) + ".dbf", "DATA")
    if raster == "gdp":
        arcpy.JoinField_management(yemen,"OBJECTID",outputFolder + str(raster) + ".dbf","OBJECTID",["MEAN","MAX","SUM","STD"])
        renameField(yemen,"MEAN",raster+"_mean")
        renameField(yemen,"SUM",raster+"_sum")
        renameField(yemen,"MAX",raster+"_max")
        renameField(yemen,"STD",raster+"_std")
    else:
        arcpy.JoinField_management(yemen,"OBJECTID",outputFolder + str(raster) + ".dbf","OBJECTID",["MEAN","MIN","MAX","STD"])
        renameField(yemen,"MEAN",raster+"_mean")
        renameField(yemen,"MIN",raster+"_min")
        renameField(yemen,"MAX",raster+"_max")
        renameField(yemen,"STD",raster+"_std")
    print "finished " + raster