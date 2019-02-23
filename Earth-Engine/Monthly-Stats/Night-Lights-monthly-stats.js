//    1. Import

// var Ghana = ee.FeatureCollection('ft:1DQUmyrZjR2SQ6oDZ37MDvJBdBrFUnr6k6x_EH28H');
// var all = ee.FeatureCollection('ft:17Mn6PoouIhN0FzbXcDMUsjQTOzc7uexFptArKVB1');
// var gadm_adm2_old = ee.FeatureCollection('ft:1SwDJ-YIHeN2Lqv14pkBRlrWnpO7Vzq6bu90cEq2q');
// var sahel_adm2 = ee.FeatureCollection('ft:1Km2OVbA2b7AhZfxMP0Pxq3xE3H-JS_3K6_OJ18V8');
// var ndviCol = ee.ImageCollection(terra_16day).select('NDVI');
// var sahel_test = ee.FeatureCollection('ft:1Km2OVbA2b7AhZfxMP0Pxq3xE3H-JS_3K6_OJ18V8').filter(ee.Filter.or(
//   ee.Filter.eq('adm2_code', 154459),
//   ee.Filter.eq('adm2_code', 154460)
//   ))
// var gadm_adm2 = ee.FeatureCollection('ft:1GdU_RjSazVOZ587r6eQbOfJi3SsdwN8g9SbQ0x8l');
// var ss_adm2 = ee.FeatureCollection('ft:1up3bKym18AOSCflB20pztI4HhGwkbb4i8Q_ynfBz')
// var artemis_shape = ee.FeatureCollection('ft:1f6dIWPjdRWXvgGvm8V8xQNKS90BystFeh4ETKwKu')
// var Yemen_districts = ee.FeatureCollection(yemen);

var viirs_rad = viirs.select('avg_rad');

// var setTimeCol = function(image){
//   return image.set('system:time_start', image.get('system:time_start'));
// }

//     2. Set month and year

var year_month = [];
for (var y = 2014; y < 2019; y++){
  for (var m = 1; m < 13; m++){
    year_month.push([y,m]);
  }
}

var conditional = function(image) {
  return ee.Algorithms.If(ee.Number(image.bandNames().length()).gt(0),
                          image.set('month',image.get('month')).set('year',image.get('year')),
                          null);
};

var byAll = ee.ImageCollection.fromImages(
    year_month.map(function(ym){
      var y = ym[0];
      var m = ym[1];
      var image_ym = viirs_rad.filter(ee.Filter.calendarRange(y, y, 'year'))
        .filter(ee.Filter.calendarRange(m, m, 'month'))
        .mean()
        .set('year',y)
        .set('month',m);
      var result = conditional(image_ym);
      return result;
      })
    );

print(byAll)
// var n_images = byAll.toList(150).length();
// print(n_images);

var avg_2018 = byAll.filterMetadata('year','equals',2018).mean();
print(avg_2018)
Map.addLayer(avg_2018)


//    3. Reduce to region(s)

// Combine the mean and standard deviation and pctiles reducers.
var reducers = ee.Reducer.stdDev().combine({
  reducer2: ee.Reducer.sum(),
  sharedInputs: true
});

var ZonalStats = function(feature) {

  //I don't know why maskedNDVI.length() is not working here
  for (var i = 0; i < 56; i++) {

    var i_string = ee.String(ee.Number(i));
    var image = ee.Image(byAll.filterMetadata('system:index','equals',i_string).first());
    var year = ee.String(ee.Number(image.get('year')).int());
    var month = ee.String(ee.Number(image.get('month')).int());

    var statistics = image.reduceRegion({
      reducer: reducers,
      geometry: feature.geometry(),
      scale: 500,
      maxPixels:10e15
    });

    // set names
    var name_std = ee.String("Lights_std__").cat(year).cat("_").cat(month);
    var name_sum = ee.String("Lights_sum__").cat(year).cat("_").cat(month);

    feature = feature.set(name_std,statistics.get('avg_rad_stdDev'),name_sum,statistics.get('avg_rad_sum'));

  }

    return feature;

}

// var mappedReduction = Yemen_districts.map(ZonalStats);
// print(mappedReduction)

// Export.table.toDrive({
//   collection: mappedReduction,
//   description: 'yemen_nightlights',
//   fileFormat: 'CSV'
// });
