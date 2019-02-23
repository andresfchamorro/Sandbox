// 1. Import

var Yemen_districts = ee.FeatureCollection(yemen);
var GHSL_built = ee.Image(GHSL).select('built');
var treeCover = hansen.select('treecover2000');

// var sahel_test = ee.FeatureCollection('ft:1Km2OVbA2b7AhZfxMP0Pxq3xE3H-JS_3K6_OJ18V8').filter(ee.Filter.or(
//   ee.Filter.eq('adm2_code', 154459),
//   ee.Filter.eq('adm2_code', 154460)
//   ))
//var gadm_adm2 = ee.FeatureCollection('ft:1GdU_RjSazVOZ587r6eQbOfJi3SsdwN8g9SbQ0x8l');
//var artemis_shape = ee.FeatureCollection('ft:1f6dIWPjdRWXvgGvm8V8xQNKS90BystFeh4ETKwKu')

//  2. Reclassify to non built up land and built up land

var nonbuilt_area = GHSL_built.eq(2).multiply(ee.Image.pixelArea());
var built_area = GHSL_built.gt(2).multiply(ee.Image.pixelArea());

var crop_wat_mask = crop_wat.eq(0);
var bool = ee.Image(1);
var area_crop = bool.updateMask(crop_wat_mask.not()).multiply(ee.Image.pixelArea());

var treeCoverBool = treeCover.gt(30);
var treeCoverArea = treeCoverBool.multiply(ee.Image.pixelArea())

var ZonalStats = function(feature) {

  var sum_nonbuilt = nonbuilt_area.reduceRegion({
    reducer: ee.Reducer.sum(),
    geometry: feature.geometry(),
    scale: 38,
    maxPixels: 10e15
  }).get('built')

  var sum_built = built_area.reduceRegion({
    reducer: ee.Reducer.sum(),
    geometry: feature.geometry(),
    scale: 38,
    maxPixels: 10e15
  }).get('built')

  var sum_treecover = treeCoverArea.reduceRegion({
    reducer: ee.Reducer.sum(),
    geometry: feature.geometry(),
    scale: 38,
    maxPixels: 10e15
  }).get('treecover2000')

  var sum_cropland = area_crop.reduceRegion({
    reducer: ee.Reducer.sum(),
    geometry: feature.geometry(),
    scale: 30,
    maxPixels: 10e15
  }).get('constant')

  return feature.set(
    ee.String("Area"),feature.area(),
    ee.String("Area_nonbuilt"),sum_nonbuilt,
    ee.String("Area_built"),sum_built,
    ee.String("Area_ForestCover"),sum_treecover,
    ee.String("Area_Cropland"),sum_cropland
  );

}

var mappedReduction = Yemen_districts.map(ZonalStats);
// print(mappedReduction)


Export.table.toDrive({
  collection: mappedReduction,
  description: 'area_context_yemen',
  fileFormat: 'CSV'
});
