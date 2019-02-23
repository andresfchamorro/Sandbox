//    1. ET_fall Mean

// var Ghana = ee.FeatureCollection('ft:1DQUmyrZjR2SQ6oDZ37MDvJBdBrFUnr6k6x_EH28H');
// var all = ee.FeatureCollection('ft:17Mn6PoouIhN0FzbXcDMUsjQTOzc7uexFptArKVB1');
// var g2_sim = ee.FeatureCollection('ft:1SwDJ-YIHeN2Lqv14pkBRlrWnpO7Vzq6bu90cEq2q');
// var sahel_adm2 = ee.FeatureCollection('ft:1Km2OVbA2b7AhZfxMP0Pxq3xE3H-JS_3K6_OJ18V8');
// var chirpsCol = ee.ImageCollection(CHIRPS_PENTAD).select('precipitation').filter(ee.Filter.calendarRange(2009, 2018, 'year'));
var etCol = ee.ImageCollection(evapotranspiration).select('ET').filter(ee.Filter.calendarRange(2009, 2018, 'year'));

// var gadm_adm2 = ee.FeatureCollection('ft:1GdU_RjSazVOZ587r6eQbOfJi3SsdwN8g9SbQ0x8l');
var Artemis_districts = ee.FeatureCollection('ft:1f6dIWPjdRWXvgGvm8V8xQNKS90BystFeh4ETKwKu');

//    2. Mask cropland

var crop_wat_mask = crop_wat.eq(0).or(waterMask.select('water_mask').eq(1));
var pas_wat_mask = pasture.eq(0).or(waterMask.select('water_mask').eq(1));
var wat_mask = waterMask.select('water_mask').eq(1);

var maskCropCol = function(image){
  return image.updateMask(crop_wat_mask.not()).multiply(0.1).set('month',image.get('month')).set('year',image.get('year'));
}

var maskPasCol = function(image){
  return image.updateMask(pas_wat_mask.not()).multiply(0.1).set('month',image.get('month')).set('year',image.get('year'));
}

var maskWatCol = function(image){
  return image.updateMask(wat_mask.not()).multiply(0.1).set('month',image.get('month')).set('year',image.get('year'));
}


//    3. Arrange by month/year pair

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
    year_month.map(function(ym){
      var y = ym[0];
      var m = ym[1];
      var image_ym = etCol.filter(ee.Filter.calendarRange(y, y, 'year'))
        .filter(ee.Filter.calendarRange(m, m, 'month'))
        .mean()
        .set('year',y)
        .set('month',m);
      var result = conditional(image_ym);
      return result;
      })
    );

print(byYM_avg);

var All_Avg_Monthly= byYM_avg.map(maskWatCol)
var Crop_Avg_Monthly= byYM_avg.map(maskCropCol)
var Pas_Avg_Monthly= byYM_avg.map(maskPasCol)

//    4. Reduce to region(s)

var reducer_pct = ee.Reducer.percentile([25,75], null, null, null, null)

// Combine the mean and standard deviation and pctiles reducers.
var reducers = ee.Reducer.mean().combine({
  reducer2: reducer_pct,
  sharedInputs: true
});

var n_images = byYM_avg.toList(150).length();
print(n_images);

var ZonalStats = function(feature) {

  //I don't know why maskedNDVI.length() is not working here
  for (var i = 0; i < 116; i++) {

    var i_string = ee.String(ee.Number(i));

    var image_all_mean = ee.Image(All_Avg_Monthly.filterMetadata('system:index','equals',i_string).first());
    var image_crop_mean = ee.Image(Crop_Avg_Monthly.filterMetadata('system:index','equals',i_string).first());
    var image_pas_mean = ee.Image(Pas_Avg_Monthly.filterMetadata('system:index','equals',i_string).first());

    var year = ee.String(ee.Number(image_all_mean.get('year')).int());
    var month = ee.String(ee.Number(image_all_mean.get('month')).int());

    var stat_mean_all = image_all_mean.reduceRegion({
      reducer: ee.Reducer.mean(),
      geometry: feature.geometry(),
      scale: 1000,
      maxPixels:10e15
    });

    var stat_mean_crop = image_crop_mean.reduceRegion({
      reducer: ee.Reducer.mean(),
      geometry: feature.geometry(),
      scale: 1000,
      maxPixels:10e15
    });

    var stat_mean_pas = image_pas_mean.reduceRegion({
      reducer: ee.Reducer.mean(),
      geometry: feature.geometry(),
      scale: 1000,
      maxPixels:10e15
    });

    var nameAll_mean = ee.String("ET_All_mean__").cat(year).cat("_").cat(month);
    var nameCrop_mean = ee.String("ET_Crop_mean__").cat(year).cat("_").cat(month);
    var namePas_mean = ee.String("ET_Pas_mean__").cat(year).cat("_").cat(month);

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
//   description: 'Artemis_ET_fall_Stats',
//   fileFormat: 'CSV'
// });
