
//Import images/features
var Landsat = ee.ImageCollection('LANDSAT/LE7_L1T_ANNUAL_NDVI');
var Modis = ee.ImageCollection('MODIS/MOD13A1').select('NDVI');
var NPP = ee.ImageCollection('MODIS/006/MYD17A3H').select('Npp')
var veg = ee.ImageCollection('MODIS/006/MOD17A2H').select('PsnNet');

//var Ghana = ee.FeatureCollection('ft:1DQUmyrZjR2SQ6oDZ37MDvJBdBrFUnr6k6x_EH28H');
//var bookmark = ee.FeatureCollection('ft:1vmwlG8r0CinMD1SHlCRfd3kJsQvuDt_cZQZho9Xk');
var africa = ee.FeatureCollection(geometry)
print(africa)

var addTimeClip = function(image) {
  return image.addBands(image.metadata('system:time_start')
    .divide(1000 * 60 * 60 * 24 * 365)).clip(africa);
};

var NPP_clipped = veg.map(addTimeClip);
var Modis_clipped = Modis.map(addTimeClip);

print(Modis_clipped);

var trend = Modis_clipped.select(['system:time_start', 'NDVI'])
  // Compute the linear trend over time.
  .reduce(ee.Reducer.linearFit());

var slope = trend.select(['scale']);

print('Projection, crs, and crs_transform:', slope.projection());
print('Scale in meters:', slope.projection().nominalScale());

// Combine the mean and standard deviation reducers.
var reducers = ee.Reducer.mean().combine({
  reducer2: ee.Reducer.minMax(),
  sharedInputs: true
});


// Use the combined reducer to get the mean and SD of the image.
var stats = slope.reduceRegion({
  reducer: reducers,
  geometry: africa,
  scale: 111319.49079327357
});

print(stats);
var min_value = ee.Number(stats.get("scale_min"));
var max_value = ee.Number(stats.get("scale_max"));

Map.addLayer(slope, {min: -100000, max: 100000, palette: ['67000d','ef3b2c','fcbba1','fff5f0']}, 'Slope NPP Change');
var red_colorBrewer = ['67000d','ef3b2c','fcbba1','fff5f0']

// Export the image, specifying scale and region.
Export.image.toDrive({
  image: slope,
  description: 'NDVI_Slope_Monthly',
  maxPixels:10e9,
  scale: 500,
  region: africa
});
