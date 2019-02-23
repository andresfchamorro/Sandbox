var sentinel = ee.ImageCollection(sent);
var one = sentinel.first()
print(one)

// var ndviCol = ee.ImageCollection(tera_16day).select('NDVI').filter(ee.Filter.calendarRange(2,2,'month'))

var spatialFiltered = sentinel.filterBounds(point);
print('spatialFiltered', spatialFiltered);

var temporalFiltered = spatialFiltered.filterDate('2018-03-01', '2018-03-30');
var temporalFiltered2 = spatialFiltered.filterDate('2018-04-01', '2018-04-30');

print('temporalFiltered', temporalFiltered);

// var first = ee.Image(temporalFiltered.first())
// print(first)

var vis = {min:0, max:2500, gamma:1.4, bands: ['B4', 'B3', 'B2']};
// Map.addLayer(temporalFiltered, vis)

// This will sort from least to most cloudy.
var sorted = temporalFiltered.sort('CLOUDY_PIXEL_PERCENTAGE',false);
var sorted2 = temporalFiltered2.sort('CLOUDY_PIXEL_PERCENTAGE',false);


// Get the first (least cloudy) image.
var scene = ee.Image(sorted.first());

Map.addLayer(sorted, vis, 'true-color composite t1')
Map.addLayer(sorted2, vis, 'true-color composite t2')
