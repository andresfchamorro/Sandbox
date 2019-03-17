import arcpy, arcinfo
from arcpy import env
from arcpy.sa import *
import os

arcpy.CheckOutExtension("Spatial")
print 'Check out extension complete'

# Set environment settings
env.workspace = "C:/Users/WB514197/Desktop/Data/HD/Geo/GriddedWorldPop"
g1 = "C:/Users/WB514197/Desktop/Data/HD/Geo/Master/g1_master.shp"
g2 = "C:/Users/WB514197/Desktop/Data/HD/Geo/Master/g2_master.shp"
p2 = "C:/Users/WB514197/Desktop/Data/HD/Geo/Master/p2_master.shp"
zoneObjectID = "OBJECTID"
outTable_g1 = "C:/Users/WB514197/Desktop/Data/HD/Geo/GriddedWorldPop/g1_output/"
outTable_g2 = "C:/Users/WB514197/Desktop/Data/HD/Geo/GriddedWorldPop/g2_output/"
outTable_p2 = "C:/Users/WB514197/Desktop/Data/HD/Geo/GriddedWorldPop/p2_output/"

#could use list rasters instead
gpw_2000 = "C:/Users/WB514197/Desktop/Data/HD/Geo/GriddedWorldPop/gpw-v4-population-count-adjusted-to-2015-unwpp-country-totals_2000.tif"
gpw_2005 = "C:/Users/WB514197/Desktop/Data/HD/Geo/GriddedWorldPop/gpw-v4-population-count-adjusted-to-2015-unwpp-country-totals_2005.tif"
gpw_2010 = "C:/Users/WB514197/Desktop/Data/HD/Geo/GriddedWorldPop/gpw-v4-population-count-adjusted-to-2015-unwpp-country-totals_2010.tif"
gpw_2015 = "C:/Users/WB514197/Desktop/Data/HD/Geo/GriddedWorldPop/gpw-v4-population-count-adjusted-to-2015-unwpp-country-totals_2015.tif"
gpw_2020 = "C:/Users/WB514197/Desktop/Data/HD/Geo/GriddedWorldPop/gpw-v4-population-count-adjusted-to-2015-unwpp-country-totals_2020.tif"

# Execute ZonalStatisticsAsTable
#i is only used to get the output name right

i = 1995
for var in [gpw_2000,gpw_2005,gpw_2010,gpw_2015,gpw_2020]:
    outZSaT = ZonalStatisticsAsTable(g1, "OBJECTID", var, outTable_g1 + "gpw_" + str(i+5) + ".dbf", "DATA", "SUM")
    i = i + 5

i = 1995
for var in [gpw_2000,gpw_2005,gpw_2010,gpw_2015,gpw_2020]:
    outZSaT = ZonalStatisticsAsTable(g2, "OBJECTID", var, outTable_g2 + "gpw_" + str(i+5) + ".dbf", "DATA", "SUM")
    i = i + 5

i = 1995
for var in [gpw_2000,gpw_2005,gpw_2010,gpw_2015,gpw_2020]:
    outZSaT = ZonalStatisticsAsTable(p2, "ZS_ID", var, outTable_p2 + "gpw_" + str(i+5) + ".dbf", "DATA", "SUM")
    i = i + 5
