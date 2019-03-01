import arcpy, arcinfo
from arcpy import env
from arcpy.sa import *
import os
import time, subprocess
from GOSTRocks.arcpyMisc import *
arcpy.CheckOutExtension("Spatial")
print 'Check out extension complete'


#### FIND SOURCES

# GAUL Admin 0 <- E:\Andres_Data\Administrative\GAUL\simplified\g2015_0_merge.shp
# Van Donk <- F:\WorldBank\VanDonk\pm25.gdb
# GPW <- F:\WorldBank\GPW\gpw-v4-population-count-adjusted-to-2015-unwpp-country-totals_2015.tif

vandonk = r"F:\WorldBank\VanDonk\pm25.gdb"
gaul = r"E:\Andres_Data\Administrative\GAUL\simplified\g2015_0_merge.shp"
gaul_raster = r"F:\WorldBank\WeightedPollution\TEST_GLOBAL\gaul"
gpw = r"F:\WorldBank\GPW"
gpw_re = r"F:\WorldBank\GPW\resample"
maindir = r"F:\WorldBank\WeightedPollution"
outdir = os.path.join(maindir,"outdir")
if not os.path.exists(outdir):
    os.mkdir(outdir)

#### 1. Resample all GPWs to VanDonk res (DONE)
# Batch process

#### 2. Feature to raster countries (DONE)
# 	Same cell size as VanDonk (0.01)
# 	Snap Raster
# 	*You could also feature to raster at a high res and resample using majority

#### 3. Get population weights for each GPW year (DONE)
out_popsum = os.path.join(outdir,"popsum")
if not os.path.exists(out_popsum):
    os.mkdir(out_popsum)

out_weights = os.path.join(outdir,"weights")
if not os.path.exists(out_weights):
    os.mkdir(out_weights)

out_sumweights = os.path.join(outdir,"sumweights")
if not os.path.exists(out_sumweights):
    os.mkdir(out_sumweights)

out_we_poll = os.path.join(outdir,"weightedpollution")
if not os.path.exists(out_we_poll):
    os.mkdir(out_we_poll)


env.workspace = gpw_re
rasters = arcpy.ListRasters("*", "All")
print(rasters)
rasters.sort()

# 	Zonal stats (sum pop)

for each in rasters:
	out_raster = os.path.join(out_popsum,"sum_"+each)
	print("summing gpw pop for " + each)
	ZonalStats = ZonalStatistics(gaul_raster, "VALUE", each, "SUM", "DATA")
	ZonalStats.save(out_raster)

# 	Raster calculator (pop / sum pop)

for each in rasters:
	sum_gpw = os.path.join(out_popsum,"sum_"+each)
	out_raster = os.path.join(out_weights,"weights_"+each[4:])
	print("dividing pop for " + each)
	Calc = Raster(each) / Raster(sum_gpw)
	Calc.save(out_raster)


#sum weights
env.workspace = r"F:\WorldBank\WeightedPollution\outdir\weights"
rasters = arcpy.ListRasters("*", "All")
print(rasters)
rasters.sort()

for each in rasters:
	out_raster = os.path.join(out_sumweights,"sum_"+each[-4:])
	print("summing weights for " + each)
	print(out_raster)
	ZonalStats = ZonalStatistics(gaul_raster, "VALUE", each, "SUM", "DATA")
	ZonalStats.save(out_raster)

# 4. Apply weights to pollution
# 	Weighted pol = raster calculator (weights * pollution)

vd = r"F:\WorldBank\VanDonk\pm25.gdb\PM25_"+year

years = np.array([2000,2005,2010,2015])

for year in range(2000,2017):
    year_str = str(year)
    out_raster = os.path.join(out_we_poll,"we_pol_"+year)
    vd = r"F:\WorldBank\VanDonk\pm25.gdb\PM25_"+year
    idx = np.abs(years-year).argmin()
    year_poll = years[idx]
    weights = r"F:\WorldBank\WeightedPollution\outdir\weights\weights_"+str(year_poll)
    sumweights = r"F:\WorldBank\WeightedPollution\outdir\sumweights\sum_"+str(year_poll)
    mult = (Raster(vd) * Raster(weights))
    ZonalStats = ZonalStatistics(gaul_raster, "VALUE", mult, "SUM", "DATA")
    Division = ZonalStats / Raster(sumweights)
    Division.save(out_raster)