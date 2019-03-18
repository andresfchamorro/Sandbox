import arcpy, arcinfo
from arcpy import env
from arcpy.sa import *
import os
import time, subprocess
from GOSTRocks.arcpyMisc import *

arcpy.CheckOutExtension("Spatial")
arcpy.AddMessage('Check out extension complete')

# Set environment settings
shape = r"E:\Andres_Data\HD\GIS\Master\g1_master_zeros.shp"
outTable = "E:/Andres_Data/tmp/tables_zeros/"
if not os.path.exists(outTable):
    os.mkdir(outTable)
indir = r"E:\Andres_Data\tmp\annual"
env.workspace = indir
scratch_gdb = os.path.join(indir,"scratch.gdb")
if not os.path.exists(scratch_gdb):
    arcpy.CreateFileGDB_management(indir,"scratch.gdb")
scratch_workspace = os.path.join(indir,"scratch.gdb")
arcpy.env.scratchWorkspace = scratch_workspace
env.cellSize = "0.1"


rasters = arcpy.ListRasters("*", "All")
rasters.sort()
year = 1996
a = datetime.datetime.now()
for raster in rasters:
    arcpy.AddMessage("calculating zonal stats for " + str(year))
    outZSaT = ZonalStatisticsAsTable(shape, "OBJECTID", raster, outTable + "tmp_mean_" + str(year) + ".dbf", "DATA", "MEAN")
    arcpy.AddMessage("     elapsed time: " + str(datetime.datetime.now() - a))
    arcpy.AddMessage("joining " + "tmp_mean_" + str(year) + ".dbf")
    arcpy.JoinField_management(shape,"OBJECTID",outTable + "tmp_mean_" + str(year) + ".dbf","OBJECTID",["MEAN"])
    year += 1

renameField(shape,"MEAN","ND_me_1996")
renameField(shape,"MEAN_1","ND_me_1997")
renameField(shape,"MEAN_12","ND_me_1998")
renameField(shape,"MEAN_12_13","ND_me_1999")
renameField(shape,"MEAN_12_14","ND_me_2000")
renameField(shape,"MEAN_12_15","ND_me_2001")
renameField(shape,"MEAN_12_16","ND_me_2002")
renameField(shape,"MEAN_12_17","ND_me_2003")
renameField(shape,"MEAN_12_18","ND_me_2004")
renameField(shape,"MEAN_12_19","ND_me_2005")
renameField(shape,"MEAN_12_20","ND_me_2006")
renameField(shape,"MEAN_12_21","ND_me_2007")
renameField(shape,"MEAN_12_22","ND_me_2008")
renameField(shape,"MEAN_12_23","ND_me_2009")
renameField(shape,"MEAN_12_24","ND_me_2010")
renameField(shape,"MEAN_12_25","ND_me_2011")
renameField(shape,"MEAN_12_26","ND_me_2012")
renameField(shape,"MEAN_12_27","ND_me_2013")
renameField(shape,"MEAN_12_28","ND_me_2014")
renameField(shape,"MEAN_12_29","ND_me_2015")
