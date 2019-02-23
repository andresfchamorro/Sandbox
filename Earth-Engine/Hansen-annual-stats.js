//Import images from EE
var gfc2013 = ee.Image('UMD/hansen/global_forest_change_2013');

var lossYear = gfc2013.select(['lossyear']);
var treeCover = gfc2013.select(['treecover2000']);

//Get feature collection/fusion table we are computing for
var gadm1 = ee.FeatureCollection('ft:1iHM_T7sm-UPHVrSyuM5eCJvcA0NJtrCGp4Eip_hU')


//Reclassify tree cover and get boolean for each year
var bool = treeCover.gt(30);

//Apply boolean tree cover mask and multiply to get area for each year of loss
var cover_2000 = lossYear.eq(0).and(bool).multiply(ee.Image.pixelArea());
var loss_2001 = lossYear.eq(1).and(bool).multiply(ee.Image.pixelArea());
var loss_2002 = lossYear.eq(2).and(bool).multiply(ee.Image.pixelArea());
var loss_2003 = lossYear.eq(3).and(bool).multiply(ee.Image.pixelArea());
var loss_2004 = lossYear.eq(4).and(bool).multiply(ee.Image.pixelArea());
var loss_2005 = lossYear.eq(5).and(bool).multiply(ee.Image.pixelArea());
var loss_2006 = lossYear.eq(6).and(bool).multiply(ee.Image.pixelArea());
var loss_2007 = lossYear.eq(7).and(bool).multiply(ee.Image.pixelArea());
var loss_2008 = lossYear.eq(8).and(bool).multiply(ee.Image.pixelArea());
var loss_2009 = lossYear.eq(9).and(bool).multiply(ee.Image.pixelArea());
var loss_2010 = lossYear.eq(10).and(bool).multiply(ee.Image.pixelArea());
var loss_2011 = lossYear.eq(11).and(bool).multiply(ee.Image.pixelArea());
var loss_2012 = lossYear.eq(12).and(bool).multiply(ee.Image.pixelArea());
var loss_2013 = lossYear.eq(13).and(bool).multiply(ee.Image.pixelArea());
var loss_2014 = lossYear.eq(14).and(bool).multiply(ee.Image.pixelArea());

//Push all images into an array
var hansen_area = [];
hansen_area.push(cover_2000,loss_2001,loss_2002,loss_2003,loss_2004,loss_2005,loss_2006,loss_2007,loss_2008,loss_2009,loss_2010,loss_2011,loss_2012,loss_2013,loss_2014);

//Create new array for variable names
var years = ['cover','l2001','l2002','l2003','l2004','l2005','l2006','l2007'
,'l2008','l2009','l2010','l2011','l2012','l2013','l2014']

//This function takes a feature as an input, and computes zonal statistics (reduceRegion) for each year of loss, it then sets a new property with the derived value of tree cover loss
var ZonalStats = function(feature) {

for (var i = 0; i < years.length; i++) {
  var varname = years[i];
  var image = hansen_area[i];
  var value = image.reduceRegion({
    reducer: 'sum',
    geometry: feature.geometry(),
    scale: 30,
    maxPixels:10e9
  }).get('lossyear');

  feature = feature.set(varname ,value)

}
  return feature;
}

var mappedReduction = gadm1.map(ZonalStats);

Export.table.toDrive({
  collection: mappedReduction,
  description: 'Testing annual script',
  fileFormat: 'CSV'
});
