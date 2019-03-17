####Tabulate Area process which calculates the area of land use type per polygon.
##arcpy.gp.TabulateArea_sa("admin2Moll", "ZS_ID", "LC_2010_Moll", "LC", "E:/WBG/Data/LandCover/NewLandCoverData/LC_p2_2010", "300")


import arcpy, arcinfo
from arcpy import env
from arcpy.sa import *
import os
import time, subprocess
from GOSTRocks.arcpyMisc import *
arcpy.CheckOutExtension("Spatial")
print 'Check out extension complete'

#######################August 2017
#####Define input datasets
g1 = r"E:\Andres_Data\HD\GIS\Master\g1_master.shp"
g2 = r"E:\Andres_Data\HD\GIS\Master\g2_master.shp"
p2 = r"E:\Andres_Data\HD\GIS\Master\p2_Jul20.shp"
outTable = "E:/Andres_Data/ESA-CCI/Output"
outExcel = "E:/Andres_Data/ESA-CCI/Excel"
env.workspace = r"E:\Andres_Data\ESA-CCI\Annual_v2"

rasters = arcpy.ListRasters("*", "All")
rasters.sort()
i = 1992
a = datetime.datetime.now()

i = 1992
for raster in rasters:
    print "tab area p2 land cover for " + raster
    LC = arcpy.gp.TabulateArea_sa(p2,"ZS_ID", raster, "Value", outTable + "/p2/LC_" + str(i), "0,002777777701187")
    print "     elapsed time: " + str(datetime.datetime.now() - a)
    print "finished tab area p2 land cover for " + raster
    arcpy.TableToExcel_conversion(Input_Table=LC, Output_Excel_File=outExcel + "/p2/lc_p2_" + str(i) + ".xls", Use_field_alias_as_column_header="NAME", Use_domain_and_subtype_description="CODE")
    print "saved as xls!"
    i = i + 1


print "complete"
