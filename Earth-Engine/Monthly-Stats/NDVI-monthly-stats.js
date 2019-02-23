//    1. Import features and image collections

// var g2_sim = ee.FeatureCollection('ft:1SwDJ-YIHeN2Lqv14pkBRlrWnpO7Vzq6bu90cEq2q');
// var sahel_adm2 = ee.FeatureCollection('ft:1Km2OVbA2b7AhZfxMP0Pxq3xE3H-JS_3K6_OJ18V8');
// var gadm_adm2 = ee.FeatureCollection('ft:1GdU_RjSazVOZ587r6eQbOfJi3SsdwN8g9SbQ0x8l');
var ndviCol = ee.ImageCollection(terra_16day).select('NDVI');
//var Artemis_districts = ee.FeatureCollection('ft:1f6dIWPjdRWXvgGvm8V8xQNKS90BystFeh4ETKwKu');
var Yemen_districts = ee.FeatureCollection(yemen);

//    2. Mask by land type (non-water, cropland and pasture)

var crop_wat_mask = crop_wat.eq(0).or(waterMask.select('water_mask').eq(1));
var pas_wat_mask = pasture.eq(0).or(waterMask.select('water_mask').eq(1));
var wat_mask = waterMask.select('water_mask').eq(1);

// Vizualize masks
// Map.addLayer(wat_mask, {min: 0, max: 1, palette: ['FFFFFF', 'red']}, 'water mask');
// Map.addLayer(crop_wat_mask, {min: 0, max: 1, palette: ['FFFFFF', 'red']}, 'crop mask');
// Map.addLayer(pas_wat_mask, {min: 0, max: 1, palette: ['FFFFFF', 'red']}, 'pas mask');

var maskCropCol = function(image){
  return image.updateMask(crop_wat_mask.not()).multiply(0.0001).set('month',image.get('month')).set('year',image.get('year'));
}

var maskPasCol = function(image){
  return image.updateMask(pas_wat_mask.not()).multiply(0.0001).set('month',image.get('month')).set('year',image.get('year'));
}

var maskWatCol = function(image){
  return image.updateMask(wat_mask.not()).multiply(0.0001).set('month',image.get('month')).set('year',image.get('year'));
}

//    3. Arrange images by year-month pair, using the mean, max and min

var year_month = [];
for (var y = 2009; y < 2019; y++){
  for (var m = 1; m < 13; m++){
    year_month.push([y,m]);
  }
}

var conditional = function(image) {
  return ee.Algorithms.If(ee.Number(image.bandNames().length()).gt(0),
                          image.set('month',image.get('month')).set('year',image.get('year')),
                          null);
};

var byYM_avg = ee.ImageCollection.fromImages(
    year_month.map(function(ym){m
      var y = ym[0];
      var m = ym[1];
      var image_ym = ndviCol.filter(ee.Filter.calendarRange(y, y, 'year'))
        .filter(ee.Filter.calendarRange(m, m, 'month'))
        .mean()
        .set('year',y)
        .set('month',m);
      var result = conditional(image_ym);
      return result;
      })
    );

var byYM_max = ee.ImageCollection.fromImages(
    year_month.map(function(ym){
      var y = ym[0];
      var m = ym[1];
      var image_ym = ndviCol.filter(ee.Filter.calendarRange(y, y, 'year'))
        .filter(ee.Filter.calendarRange(m, m, 'month'))
        .max()
        .set('year',y)
        .set('month',m);
      var result = conditional(image_ym);
      return result;
      })
    );

var byYM_min = ee.ImageCollection.fromImages(
    year_month.map(function(ym){
      var y = ym[0];
      var m = ym[1];
      var image_ym = ndviCol.filter(ee.Filter.calendarRange(y, y, 'year'))
        .filter(ee.Filter.calendarRange(m, m, 'month'))
        .min()
        .set('year',y)
        .set('month',m);
      var result = conditional(image_ym);
      return result;
      })
    );

var All_Avg_Monthly= byYM_avg.map(maskWatCol)
var Crop_Avg_Monthly= byYM_avg.map(maskCropCol)
var Pas_Avg_Monthly= byYM_avg.map(maskPasCol)

var All_Max_Monthly= byYM_max.map(maskWatCol)
var Crop_Max_Monthly= byYM_max.map(maskCropCol)
var Pas_Max_Monthly= byYM_max.map(maskPasCol)

var All_Min_Monthly= byYM_min.map(maskWatCol)
var Crop_Min_Monthly= byYM_min.map(maskCropCol)
var Pas_Min_Monthly= byYM_min.map(maskPasCol)

var n_images = byYM_avg.toList(150).length();
print(n_images);

//    4. Calculate zonal stats (mean) for each land type

var ZonalStats = function(feature) {

  for (var i = 0; i < 117; i++) {

    var i_string = ee.String(ee.Number(i));

    var image_all_mean = ee.Image(All_Avg_Monthly.filterMetadata('system:index','equals',i_string).first());
    var image_crop_mean = ee.Image(Crop_Avg_Monthly.filterMetadata('system:index','equals',i_string).first());
    var image_pas_mean = ee.Image(Pas_Avg_Monthly.filterMetadata('system:index','equals',i_string).first());

    var image_all_max = ee.Image(All_Max_Monthly.filterMetadata('system:index','equals',i_string).first());
    var image_crop_max = ee.Image(Crop_Max_Monthly.filterMetadata('system:index','equals',i_string).first());
    var image_pas_max = ee.Image(Pas_Max_Monthly.filterMetadata('system:index','equals',i_string).first());

    var image_all_min = ee.Image(All_Min_Monthly.filterMetadata('system:index','equals',i_string).first());
    var image_crop_min = ee.Image(Crop_Min_Monthly.filterMetadata('system:index','equals',i_string).first());
    var image_pas_min = ee.Image(Pas_Min_Monthly.filterMetadata('system:index','equals',i_string).first());

    var year = ee.String(ee.Number(image_all_mean.get('year')).int());
    var month = ee.String(ee.Number(image_all_mean.get('month')).int());

    var stat_mean_all = image_all_mean.reduceRegion({
      reducer: ee.Reducer.mean(),
      geometry: feature.geometry(),
      scale: 250,
      maxPixels:10e15
    }).get('NDVI');

    var stat_mean_crop = image_crop_mean.reduceRegion({
      reducer: ee.Reducer.mean(),
      geometry: feature.geometry(),
      scale: 250,
      maxPixels:10e15
    }).get('NDVI');

    var stat_mean_pas = image_pas_mean.reduceRegion({
      reducer: ee.Reducer.mean(),
      geometry: feature.geometry(),
      scale: 250,
      maxPixels:10e15
    }).get('NDVI');

    var stat_max_all = image_all_max.reduceRegion({
      reducer: ee.Reducer.mean(),
      geometry: feature.geometry(),
      scale: 250,
      maxPixels:10e15
    }).get('NDVI');

    var stat_max_crop = image_crop_max.reduceRegion({
      reducer: ee.Reducer.mean(),
      geometry: feature.geometry(),
      scale: 250,
      maxPixels:10e15
    }).get('NDVI');

    var stat_max_pas = image_pas_max.reduceRegion({
      reducer: ee.Reducer.mean(),
      geometry: feature.geometry(),
      scale: 250,
      maxPixels:10e15
    }).get('NDVI');

    var stat_min_all = image_all_min.reduceRegion({
      reducer: ee.Reducer.mean(),
      geometry: feature.geometry(),
      scale: 250,
      maxPixels:10e15
    }).get('NDVI');

    var stat_min_crop = image_crop_min.reduceRegion({
      reducer: ee.Reducer.mean(),
      geometry: feature.geometry(),
      scale: 250,
      maxPixels:10e15
    }).get('NDVI');

    var stat_min_pas = image_pas_min.reduceRegion({
      reducer: ee.Reducer.mean(),
      geometry: feature.geometry(),
      scale: 250,
      maxPixels:10e15
    }).get('NDVI');

    var nameAll_mean = ee.String("NdviAll_mean__").cat(year).cat("_").cat(month);
    var nameCrop_mean = ee.String("NdviCrop_mean__").cat(year).cat("_").cat(month);
    var namePas_mean = ee.String("NdviPas_mean__").cat(year).cat("_").cat(month);

    var nameAll_max = ee.String("NdviAll_max__").cat(year).cat("_").cat(month);
    var nameCrop_max = ee.String("NdviCrop_max__").cat(year).cat("_").cat(month);
    var namePas_max = ee.String("NdviPas_max__").cat(year).cat("_").cat(month);

    var nameAll_min = ee.String("NdviAll_min__").cat(year).cat("_").cat(month);
    var nameCrop_min = ee.String("NdviCrop_min__").cat(year).cat("_").cat(month);
    var namePas_min = ee.String("NdviPas_min__").cat(year).cat("_").cat(month);

    feature = feature.set(
      nameAll_mean,stat_mean_all,
      nameCrop_mean,stat_mean_crop,
      namePas_mean,stat_mean_pas,
      nameAll_max,stat_max_all,
      nameCrop_max,stat_max_crop,
      namePas_max,stat_max_pas,
      nameAll_min,stat_min_all,
      nameCrop_min,stat_min_crop,
      namePas_min,stat_min_pas
    );

  }

  return feature;

}


var mappedReduction = Yemen_districts.map(ZonalStats);
// print(mappedReduction)

Export.table.toDrive({
  collection: mappedReduction,
  description: 'Yemen_NDVI_Stats',
  fileFormat: 'CSV'
});
