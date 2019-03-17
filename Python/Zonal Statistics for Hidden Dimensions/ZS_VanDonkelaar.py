import arcpy, arcinfo
from arcpy import env
from arcpy.sa import *
import os
import time, subprocess

arcpy.CheckOutExtension("Spatial")
print 'Check out extension complete'

# Set environment settings
outRaster = "F:/WorldBank/VanDonk/mask_urban.gdb/"
pdBoolean = "F:/WorldBank/WorldPop/PopulationDensity/pd_bool"
g1 = "C:/Users/WB514197/Desktop/Data/HD/Geo/GIS/Master/g1_master.shp"
g2 = "F:/WorldBank/VanDonk/Indonesia/g2.shp"
outTable = "F:/WorldBank/VanDonk/Indonesia/tables/"

env.workspace = "F:/WorldBank/VanDonk/pm25.gdb"
rasters = arcpy.ListRasters("*", "All")
rasters.sort()
i = 1999
a = datetime.datetime.now()
for raster in rasters:
    print "calculating " + raster
    outZSaT = ZonalStatisticsAsTable(g2, "OBJECTID", raster, outTable + "pm25_" + str(i) + ".dbf", "DATA", "MEAN")
    print "joining " + raster + " to shapefile"
    arcpy.JoinField_management(g2,"OBJECTID",outZSaT,"OBJECTID")
    i = i + 1
    print "     elapsed time: " + str(datetime.datetime.now() - a)
