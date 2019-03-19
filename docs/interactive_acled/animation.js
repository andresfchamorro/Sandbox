

var baseLayer = L.tileLayer('https://map1.vis.earthdata.nasa.gov/wmts-webmerc/VIIRS_CityLights_2012/default/{time}/{tilematrixset}{maxZoom}/{z}/{y}/{x}.{format}', {
	attribution: 'Imagery provided by services from the Global Imagery Browse Services (GIBS), operated by the NASA/GSFC/Earth Science Data and Information System (<a href="https://earthdata.nasa.gov">ESDIS</a>) with funding provided by NASA/HQ.',
	bounds: [[-85.0511287776, -179.999999975], [85.0511287776, 179.999999975]],
	minZoom: 1,
	maxZoom: 8,
	format: 'jpg',
	time: '',
	tilematrixset: 'GoogleMapsCompatible_Level'
});

//Conditions for heatmap
var options = {
  "radius": 10,
  "minOpacity": 1,
  "blur": 10,
  "max": 10,
  "gradient": {0.2:'#0CA0E6',0.8: '#FDBC19', 1:'#D60004'},
};

var mymap = new L.Map('map-canvas', {
  center: new L.LatLng(15.571093, 47.776592),
  zoom: 6,
  layers: [baseLayer]
});

var IPC_colors = {
  1: "#86CF86",
  2: "#E3D330",
  3: "#E67800",
  4: "#C80000",
  5: "#640000"
}

var dataset = [];
var filteredDataset;
var nested_dataset;
var Year_Month = "2016_01";
var FEWS_years = ["2016_02","2016_06","2016_10","2017_06","2017_10","2018_02","2018_06"]
var heatmapLayer;
var adminLayer;

var filterData = function(ym){

  var filtered = nested_dataset.filter(function(d){
    return d.key == ym;
  })[0].value;

  return filtered;

}

d3.queue()
  .defer(d3.csv, "data/2016-01-01-2018-10-22-Yemen.csv")
  .defer(d3.json, "data/Yemen.geojson")
  .await(Vis);

function style(feature) {

	var col_name = "CS_" + Year_Month;

	if(Year_Month=="2016_01"){
		col_name = "CS_2016_02";
	}

  return {
    fillColor: IPC_colors[feature.properties[col_name]],
    weight: 1,
    opacity: 1,
    color: 'white',
    dashArray: '3',
    fillOpacity: 0.5
  };
}

function Vis(error, data, json_yem){

  if (error) {
    console.log(error);
  }

  else {

    // var maxFat = d3.max(data, function(d) { return d.fatalities; });
    // var minFat = d3.min(data, function(d) { return d.fatalities; });
    // console.log(minFat,maxFat);
    //max is wrong, should be 10
    var parseDate1 = d3.timeParse("%d %B %Y");

    data.forEach(function(d){
      var array = [];
      array[0] = +d.latitude;
      array[1] = +d.longitude;
      // array[2] = (+d.fatalities-1)/(10-1);
      array[2] = +d.fatalities;
      array[3] = formatDate_var(parseDate1(d.event_date));
      dataset.push(array);
    });

    nested_dataset = d3.nest()
    .key(function(d){return d[3]})
    .entries(dataset)
    .map(function(a_nest){
      var newarray = [];
      a_nest.values.forEach(function(d){
        newarray.push([d[0],d[1],d[2]])
      })
      var dict = {
        key: a_nest.key,
        value: newarray
      };
      return dict;
    });

    var filteredDataset = filterData(Year_Month);

    adminLayer = new L.geoJson(json_yem, {style: style}).addTo(mymap);
    heatmapLayer = new L.heatLayer(filteredDataset,options).addTo(mymap);
		L.esri.basemapLayer('ImageryLabels').addTo(mymap);

    // heatmapLayer.setOptions(options).setLatLngs(subset);
		var overlays = {
			"IPC Phases (FEWS NET)": adminLayer,
			"Density of Conflict Events (ACLED)": heatmapLayer
		};
		var opts = {
			"collapsed": false
		}

		L.control.layers(null, overlays, opts).addTo(mymap);

		var legend = L.control({position: 'topright'});

		legend.onAdd = function (map) {

		    var div = L.DomUtil.create('div', 'info legend'),
		        grades = [1, 2, 3, 4, 5],
		        labels = ["Minimal","Stressed","Crisis","Emergency","Famine"];

		    // loop through our density intervals and generate a label with a colored square for each interval
		    for (var i = 0; i < grades.length; i++) {
		        div.innerHTML +=
		            '<i style="background:' + IPC_colors[i + 1] + '"></i> ' +
		            labels[i]+'<br>';
		    }

		    return div;
		};

		legend.addTo(mymap);

  }

};


// Slider

var formatDateIntoYear = d3.timeFormat("%Y");
var formatDate_lab = d3.timeFormat("%b %Y");
var formatDate_var = d3.timeFormat("%Y_%m");
var parseDate = d3.timeParse("%m/%d/%y");

var startDate = new Date("2016-01-01"),
    endDate = new Date("2018-10-01");

var margin = {top:0, right:50, bottom:0, left:50},
    width = 960 - margin.left - margin.right,
    height = 100 - margin.top - margin.bottom;

////////// slider //////////

var svgSlider = d3.select("#div-slider")
    .append("svg")
    .attr("width", width + margin.left + margin.right)
    .attr("height", height);

var x = d3.scaleTime()
    .domain([startDate, endDate])
    .range([0, width])
    .clamp(true)
    .nice(d3.timeMonth,1);

var slider = svgSlider.append("g")
    .attr("class", "slider")
    .attr("transform", "translate(" + margin.left + "," + height / 2 + ")");

slider.append("line")
    .attr("class", "track")
    .attr("x1", x.range()[0])
    .attr("x2", x.range()[1])
  .select(function() { return this.parentNode.appendChild(this.cloneNode(true)); })
    .attr("class", "track-inset")
  .select(function() { return this.parentNode.appendChild(this.cloneNode(true)); })
    .attr("class", "track-overlay")
    .call(d3.drag()
        .on("start.interrupt", function() { slider.interrupt(); })
        .on("start drag", function() { update(x.invert(d3.event.x)); }));

slider.insert("g", ".track-overlay")
    .attr("class", "ticks")
    .attr("transform", "translate(0," + 18 + ")")
  .selectAll("text")
    .data(x.ticks(10))
    .enter()
    .append("text")
    .attr("x", x)
    .attr("y", 10)
    .attr("text-anchor", "middle")
    .text(function(d) { return formatDate_lab(d); });

var handle = slider.insert("circle", ".track-overlay")
    .attr("class", "handle")
    .attr("r", 9);

var label = slider.append("text")
    .attr("class", "label")
    .attr("text-anchor", "middle")
    .text(formatDate_lab(startDate))
    .attr("transform", "translate(0," + (-25) + ")")

function update(h) {
  year_month=formatDate_var(h);
  // update position and text of label according to slider scale
  handle.attr("cx", x(h));
  label
    .attr("x", x(h))
    .text(formatDate_lab(h));

  if(year_month!=Year_Month){
    Year_Month=year_month;
    filteredDataset = filterData(Year_Month);
		if(d3.select(".leaflet-heatmap-layer")._groups[0][0]){
			heatmapLayer.setLatLngs(filteredDataset);
		};
		if(FEWS_years.includes(Year_Month)){
			adminLayer.setStyle(style);
		}

  }

}
