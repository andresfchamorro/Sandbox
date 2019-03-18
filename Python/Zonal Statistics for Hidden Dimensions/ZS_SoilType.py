import os
import arcpy
from arcpy.sa import *
import time, subprocess, datetime, sys


''' Section 1: Set environments ##############################################################################'''
arcpy.CheckOutExtension("Spatial")
arcpy.env.overwriteOutput = "TRUE"

indir = r"E:\Andres_Data\HD\GIS\Master\g1_master.shp"
maindir = r"E:\Andres_Data\SoilType\PopulationBySoil\gadm1"
if not os.path.exists(maindir):
    os.mkdir(maindir)
outdir = os.path.join(maindir,"outdir")
if not os.path.exists(outdir):
    os.mkdir(outdir)
############################################################################################################


'''Section 3: Set variables for admininstrative level #######################################################'''
pop_type = "log"
column_name = "OBJECTID"
#------------------------------------
sum_dbf = "_"+pop_type + "_sum.dbf"
error_text_file = os.path.join(maindir,pop_type + '_errors.txt')


'''Section 4: set path to mosaic files #################################################################'''
population = r"E:\Andres_Data\GPW\gpw-v4-population-count-adjusted-to-2015-unwpp-country-totals_2010.tif"
soiltype = r"E:\Andres_Data\SoilType\suborder_re"
############################################################################################################


'''Section 5: Set environments (part 2) #####################################################################'''
scratch_gdb = os.path.join(maindir,"scratch.gdb")
if not os.path.exists(scratch_gdb):
    arcpy.CreateFileGDB_management(maindir,"scratch.gdb")
scratch_workspace = os.path.join(maindir,"scratch.gdb")
arcpy.env.scratchWorkspace = scratch_workspace
arcpy.env.workspace = outdir
arcpy.env.snapRaster = population
############################################################################################################


'''Section 6: Prepare variables for inside script ############################################################'''
start = datetime.datetime.now()
total_features = arcpy.GetCount_management(indir)
total_features = int(total_features.getOutput(0))
############################################################################################################


'''Section 7: main body of script ############################################################################'''
with arcpy.da.SearchCursor(indir,("Shape@",column_name)) as cursor:

    feature_count = 0
    for row in cursor:

        feature_count += 1
        fc = row[0]
        value = str(row[1])
        expression = value
        list = ['']
        if value in list:

            pass
        else:

            zonalstats_sum = os.path.join(outdir,value + sum_dbf)

            if not os.path.exists(zonalstats_sum):

                print "\n" + value + " " + str(feature_count)+"/"+str(total_features)
                a = datetime.datetime.now()

                try:

                    print "     extracting by mask"

                    outExtractSoilTypes = ExtractByMask(soiltype,fc)
#                 Section 7c: run zonal stats ###############################################################'''
                    arcpy.env.cellSize = "MAXOF"
                    print "     zonal stats (sum population on each soil type)"
                    outZSaT = ZonalStatisticsAsTable(outExtractSoilTypes, "VALUE", population,zonalstats_sum, "DATA", "SUM")

#                Section 7d: add and calculate an ID field ###################################################'''
                    arcpy.AddField_management(zonalstats_sum,"ID","TEXT")
                    arcpy.CalculateField_management(zonalstats_sum,"ID","'" + expression + "'","PYTHON_9.3")
                    print "     elapsed time: " + str(datetime.datetime.now() - a)
#                 Section 7e: cleanup temp rasters ###########################################################'''
                    arcpy.env.workspace = scratch_workspace
                    rasterlist = arcpy.ListRasters()
                    for raster in rasterlist:
                        arcpy.Delete_management(raster)

#                 Section 7f: error handlers #################################################################'''

                except IOError as e:
                    print "     failed"
                    error_text = "I/O error({0}): {1}".format(e.errno, e.strerror)
                    errortext = open(error_text_file,'a')
                    errortext.write(value + " " + str(error_text) + "\n")
                    errortext.close()
                    pass
                except ValueError:
                    print "     failed"
                    error_text="Could not convert data to an integer."
                    errortext = open(error_text_file,'a')
                    errortext.write(value + " " + str(error_text) + "\n")
                    errortext.close()
                    pass
                except:
                    print "     failed"
                    error_text= "Unexpected error:", sys.exc_info()
                    error_text= error_text[1][1]
                    errortext = open(error_text_file,'a')
                    errortext.write(value + " " + str(error_text) + "\n")
                    errortext.close()
                    pass
            else:
                print value + " already exists"

'''Section 8: compile output tables ##########################################################################'''
arcpy.env.workspace = outdir
print "merging tables"
tablelist_area = arcpy.ListTables("*"+sum_dbf)
'''Section 8a: list the output tables ########################################################################'''
# list all tables, used for qc later
tablelist_area_text = open(os.path.join(maindir,pop_type +'_tableslist_sum.txt'),'w')
for table in tablelist_area:
    tablelist_area_text.write(table + '\n')
tablelist_area_text.close()
'''Section 8b: create directory to store output #############################################################'''
# create directory to store output merged table
merged_dir = os.path.join(maindir,'merged')
if not os.path.exists(merged_dir):
    os.mkdir(merged_dir)
'''Section 8c: merge tables #################################################################################'''
area_merge = os.path.join(merged_dir,pop_type +'_area_merge.dbf')
arcpy.Merge_management(tablelist_area,area_merge)

a = datetime.datetime.now()

print "total elapsed time: " + str(datetime.datetime.now() - start)
print "done"
