//Import images
var gfc2013 = ee.Image('UMD/hansen/global_forest_change_2013');
Map.addLayer(gfc2013.mask(gfc2013), {bands: ['treecover2000'], palette: ['CDF5CB', '062904']}, 'treecover2000');
var lossImage = gfc2013.select(['loss']);
var treeCover = gfc2013.select(['treecover2000']);

var p2 = ee.FeatureCollection('ft:1iHM_T7sm-UPHVrSyuM5eCJvcA0NJtrCGp4Eip_hU');
Map.addLayer(p2.draw({color:'48548A' , strokeWidth: 1}), {}, 'p2');

//Reclassify tree cover
var bool = treeCover.gt(30);

//Get loss greater than 30
var loss30 = lossImage.and(bool);
//Map.addLayer(loss30, {}, 'loss bool');

var area = ee.Image.pixelArea();
var area_cover = bool.multiply(area)
var area_loss = loss30.multiply(area);

var ZonalStats = function(feature) {

  var area_value = area.reduceRegion({
    reducer: 'sum',
    geometry: feature.geometry(),
    scale: 30,
    maxPixels:10e9
  }).get('area');

  var cover_value = area_cover.reduceRegion({
    reducer: 'sum',
    geometry: feature.geometry(),
    scale: 30,
    maxPixels:10e9
  }).get('treecover2000');

  var loss_value = area_loss.reduceRegion({
    reducer: 'sum',
    geometry: feature.geometry(),
    scale: 30,
    maxPixels:10e9
  }).get('loss');

  feature = feature.set({area: area_value, cover: cover_value, loss: loss_value});

  return feature;

};

var mappedReduction = p2.map(ZonalStats);

Export.table.toDrive({
  collection: mappedReduction,
  description: 'loss',
  fileFormat: 'CSV'
});
