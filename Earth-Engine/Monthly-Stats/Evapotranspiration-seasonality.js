//    1. Import

// var Ghana = ee.FeatureCollection('ft:1DQUmyrZjR2SQ6oDZ37MDvJBdBrFUnr6k6x_EH28H');
// var all = ee.FeatureCollection('ft:17Mn6PoouIhN0FzbXcDMUsjQTOzc7uexFptArKVB1');
// var g2_sim = ee.FeatureCollection('ft:1SwDJ-YIHeN2Lqv14pkBRlrWnpO7Vzq6bu90cEq2q');
// var sahel_adm2 = ee.FeatureCollection('ft:1Km2OVbA2b7AhZfxMP0Pxq3xE3H-JS_3K6_OJ18V8');
// var chirpsCol = ee.ImageCollection(CHIRPS_PENTAD).select('precipitation').filter(ee.Filter.calendarRange(1981, 2018, 'year'));
var etCol = ee.ImageCollection(evapotranspiration).select('ET');
// var gadm_adm2 = ee.FeatureCollection('ft:1GdU_RjSazVOZ587r6eQbOfJi3SsdwN8g9SbQ0x8l');
var Artemis_districts = ee.FeatureCollection('ft:1f6dIWPjdRWXvgGvm8V8xQNKS90BystFeh4ETKwKu');

print(Artemis_districts)

//    2. Mask cropland

var crop_wat_mask = crop_wat.eq(0).or(waterMask.select('water_mask').eq(1));
var pas_wat_mask = pasture.eq(0).or(waterMask.select('water_mask').eq(1));
var wat_mask = waterMask.select('water_mask').eq(1);

var maskCropCol = function(image){
  return image.updateMask(crop_wat_mask.not()).multiply(0.1).set('month',image.get('month'));
}

var maskPasCol = function(image){
  return image.updateMask(pas_wat_mask.not()).multiply(0.1).set('month',image.get('month'));
}

var maskWatCol = function(image){
  return image.updateMask(wat_mask.not()).multiply(0.1).set('month',image.get('month'));
}

// var maskedCHIRPS_allref = chirpsCol.map(maskWatCol);
// var maskedCHIRPS_cropref = chirpsCol.map(maskCropCol);
// var maskedCHIRPS_pasref = chirpsCol.map(maskPasCol);

var months = ee.List.sequence(1, 12);

// These are used for long term mean
var byMonthRef = ee.ImageCollection.fromImages(
      months.map(function (m) {
        return etCol.filter(ee.Filter.calendarRange(m, m, 'month'))
                    .mean()
                    .set('month', m);
}));

var refAll = byMonthRef.map(maskWatCol);
var refCrop = byMonthRef.map(maskCropCol);
var refPas = byMonthRef.map(maskPasCol);


//    4. Reduce to region(s)

var reducer_pct = ee.Reducer.percentile([25,75], null, null, null, null)

// Combine the mean and standard deviation and pctiles reducers.
var reducers = ee.Reducer.mean().combine({
  reducer2: reducer_pct,
  sharedInputs: true
});

var ZonalStatsRef = function(feature) {

  //I don't know why maskedNDVI.length() is not working here
  for (var i = 0; i < 12; i++) {

    var i_string = ee.String(ee.Number(i));

    var image_all_mean = ee.Image(refAll.filterMetadata('system:index','equals',i_string).first());
    var image_crop_mean = ee.Image(refCrop.filterMetadata('system:index','equals',i_string).first());
    var image_pas_mean = ee.Image(refPas.filterMetadata('system:index','equals',i_string).first());

    var month = ee.String(ee.Number(image_all_mean.get('month')).int());

    var stat_mean_all = image_all_mean.reduceRegion({
      reducer: ee.Reducer.mean(),
      geometry: feature.geometry(),
      scale: 500,
      maxPixels:10e15
    });

    var stat_mean_crop = image_crop_mean.reduceRegion({
      reducer: ee.Reducer.mean(),
      geometry: feature.geometry(),
      scale: 500,
      maxPixels:10e15
    });

    var stat_mean_pas = image_pas_mean.reduceRegion({
      reducer: ee.Reducer.mean(),
      geometry: feature.geometry(),
      scale: 500,
      maxPixels:10e15
    });

    var nameAll_mean = ee.String("ET_AllRef_mean__").cat("_").cat(month);
    var nameCrop_mean = ee.String("ET_CropRef_mean__").cat("_").cat(month);
    var namePas_mean = ee.String("ET_PasRef_mean__").cat("_").cat(month);

    feature = feature.set(
      nameAll_mean,stat_mean_all.get('ET'),
      nameCrop_mean,stat_mean_crop.get('ET'),
      namePas_mean,stat_mean_pas.get('ET')
    );

  }

  return feature;

}

// var mappedReduction = Artemis_districts.map(ZonalStats);
// // print(mappedReduction)

// Export.table.toDrive({
//   collection: mappedReduction,
//   description: 'Artemis_Rainfall_Stats',
//   fileFormat: 'CSV'
// });
