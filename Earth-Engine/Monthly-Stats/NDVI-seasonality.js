//    1. Import

// var g2_sim = ee.FeatureCollection('ft:1SwDJ-YIHeN2Lqv14pkBRlrWnpO7Vzq6bu90cEq2q');
// var sahel_adm2 = ee.FeatureCollection('ft:1Km2OVbA2b7AhZfxMP0Pxq3xE3H-JS_3K6_OJ18V8');
// var gadm_adm2 = ee.FeatureCollection('ft:1GdU_RjSazVOZ587r6eQbOfJi3SsdwN8g9SbQ0x8l');
var ndviCol = ee.ImageCollection(terra_16day).select('NDVI');
//var Artemis_districts = ee.FeatureCollection('ft:1f6dIWPjdRWXvgGvm8V8xQNKS90BystFeh4ETKwKu');
var Yemen_districts = ee.FeatureCollection(yemen);

//    2. Mask cropland

var crop_wat_mask = crop_wat.eq(0).or(waterMask.select('water_mask').eq(1));
var pas_wat_mask = pasture.eq(0).or(waterMask.select('water_mask').eq(1));
var wat_mask = waterMask.select('water_mask').eq(1);

// Map.addLayer(wat_mask, {min: 0, max: 1, palette: ['FFFFFF', 'red']}, 'water mask');
// Map.addLayer(crop_wat_mask, {min: 0, max: 1, palette: ['FFFFFF', 'red']}, 'crop mask');
// Map.addLayer(pas_wat_mask, {min: 0, max: 1, palette: ['FFFFFF', 'red']}, 'pas mask');

var maskCropCol = function(image){
  return image.updateMask(crop_wat_mask.not()).multiply(0.0001).set('system:time_start', image.get('system:time_start'));
}

var maskPasCol = function(image){
  return image.updateMask(pas_wat_mask.not()).multiply(0.0001).set('system:time_start', image.get('system:time_start'));
}

var maskWatCol = function(image){
  return image.updateMask(wat_mask.not()).multiply(0.0001).set('system:time_start', image.get('system:time_start'));
}

var maskedNDVI_allref = ndviCol.map(maskWatCol);
var maskedNDVI_cropref = ndviCol.map(maskCropCol);
var maskedNDVI_pasref = ndviCol.map(maskPasCol);

var months = ee.List.sequence(1, 12);

//    3. Arrange images by month to calculate long-term averages

var byMonthRef_All_mean = ee.ImageCollection.fromImages(
      months.map(function (m) {
        return maskedNDVI_allref.filter(ee.Filter.calendarRange(m, m, 'month'))
                    .mean()
                    .set('month', m);
}));

var byMonthRef_Crop_mean = ee.ImageCollection.fromImages(
      months.map(function (m) {
        return maskedNDVI_cropref.filter(ee.Filter.calendarRange(m, m, 'month'))
                    .mean()
                    .set('month', m);
}));

var byMonthRef_Pas_mean = ee.ImageCollection.fromImages(
      months.map(function (m) {
        return maskedNDVI_pasref.filter(ee.Filter.calendarRange(m, m, 'month'))
                    .mean()
                    .set('month', m);
}));

print(byMonthRef_All_mean)


//    4. Do zonal stats for each land type

var ZonalStatsRef = function(feature) {

  for (var i = 0; i < 12; i++) {

    var i_string = ee.String(ee.Number(i));

    var image_all_mean = ee.Image(byMonthRef_All_mean.filterMetadata('system:index','equals',i_string).first());
    var image_crop_mean = ee.Image(byMonthRef_Crop_mean.filterMetadata('system:index','equals',i_string).first());
    var image_pas_mean = ee.Image(byMonthRef_Pas_mean.filterMetadata('system:index','equals',i_string).first());

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


    var nameAll_mean = ee.String("NdviAllRef_mean__").cat(month);
    var nameCrop_mean = ee.String("NdviCropRef_mean__").cat(month);
    var namePas_mean = ee.String("NdviPasRef_mean__").cat(month);


    feature = feature.set(
      nameAll_mean,stat_mean_all,
      nameCrop_mean,stat_mean_crop,
      namePas_mean,stat_mean_pas
      );

  }

    return feature;

}

var mappedReduction = Yemen_districts.map(ZonalStatsRef);
// print(mappedReduction)

Export.table.toDrive({
  collection: mappedReduction,
  description: 'Yemen_NDVI_Stats_Ref',
  fileFormat: 'CSV'
});
