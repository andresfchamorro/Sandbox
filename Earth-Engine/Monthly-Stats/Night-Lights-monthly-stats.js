//    1. Import

var Yemen_districts  = ee.FeatureCollection('USDOS/LSIB_SIMPLE/2017')
  .filter(ee.Filter.eq('country_na', 'Yemen'));
var viirs = ee.ImageCollection("NOAA/VIIRS/DNB/MONTHLY_V1/VCMSLCFG");
var viirs_rad = viirs.select('avg_rad');

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
var n_images = byAll.toList(150).length().getInfo();
print(n_images);

var avg_2018 = byAll.filterMetadata('year','equals',2018).mean();
print(avg_2018)
Map.centerObject(Yemen_districts,6);
Map.addLayer(avg_2018.clip(Yemen_districts));
Map.addLayer(Yemen_districts);


//    3. Reduce to region(s)

// Combine the mean and standard deviation and pctiles reducers.
var reducers = ee.Reducer.stdDev().combine({
  reducer2: ee.Reducer.sum(),
  sharedInputs: true
});

var ZonalStats = function(feature) {

  //I don't know why maskedNDVI.length() is not working here. 
  //U should use getInfo() to make it a Javascript number. line 38
  for (var i = 0; i < n_images; i++) {

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

var mappedReduction = Yemen_districts.map(ZonalStats);
print(mappedReduction);

Export.table.toDrive({
  collection: mappedReduction,
  description: 'yemen_nightlights',
  fileFormat: 'CSV'
});