

//1. Import GEE images/features

var africa = ee.FeatureCollection(zimbabwe)
Map.addLayer(africa,{},'shapefile');
var Chirps = ee.ImageCollection('UCSB-CHG/CHIRPS/PENTAD').select('precipitation');
//var Ghana = ee.FeatureCollection('ft:1DQUmyrZjR2SQ6oDZ37MDvJBdBrFUnr6k6x_EH28H');
//var bookmark = ee.FeatureCollection('ft:1vmwlG8r0CinMD1SHlCRfd3kJsQvuDt_cZQZho9Xk');

print(Chirps)


//2. Clip images to extent
var Clip = function(image) {
  return image.clip(africa);
};
var Chirps_clipped = Chirps.map(Clip);


//3. Define reference conditions from the first x years of data and sort chronologically in descending order.
var reference = Chirps_clipped.filterDate('2000-01-01', '2005-12-31').sort('system:time_start', false);

//4. Compute the mean of the first 10 years. This is the baseline period average.
var mean = reference.mean();
Map.addLayer(mean,{},'ref_mean');


// Combine the mean and standard deviation reducers.
var reducers = ee.Reducer.mean().combine({
  reducer2: ee.Reducer.minMax(),
  sharedInputs: true
});


// Use the combined reducer to get the mean and SD of the image.
var stats = mean.reduceRegion({
  reducer: reducers,
  geometry: africa,
  scale: 500
});

print(stats);
// var min_value = ee.Number(stats.get("scale_min"));
// var max_value = ee.Number(stats.get("scale_max"));


//5. Compute anomalies by subtracting the reference mean from each image in a collection of 2011-2015 images.
//Copy the date metadata over to the computed anomaly images in the new collection.

var series = Chirps_clipped.filterDate('2010-01-01', '2015-12-31').map(function(image) {
    return image.subtract(mean).set('system:time_start', image.get('system:time_start'));
});

console.log(series);

//6. Display cumulative rainfall anomalies.
Map.addLayer(series.sum(), {min: -100000, max: 100000, palette: ['67000d','ef3b2c','fcbba1','fff5f0']}, 'Sum of Precipitation anomalies');

var stats_sum = series.sum().reduceRegion({
  reducer: reducers,
  geometry: africa,
  scale: 500
});

print(stats_sum);



//7. Export sum to drive
// Export.image.toDrive({
//   image: series.sum(),
//   description: 'Precipitation_Anomalies',
//   maxPixels:10e9,
//   scale: 500,
//   region: africa
// });
