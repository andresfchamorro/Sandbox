
## Modified by Yingxu Song.
### target file 1: Earth-Engine\NDVI-NPP-linear-trend.js
- Fusion table cound not be used in GEE(Google Earth Engine) any longer, so I add a new geometry to make it work.
- GEE Link:
https://code.earthengine.google.com/8edb11aff83042cc3974521d6eb8476b#workspace


### target file 2: Earth-Engine\Monthly-Stats\Night-Lights-monthly-stats.js
- A new ROI was imported.
- I found why ```n_images``` not work, it should be something like this:
  ```
  var n_images = byAll.toList(150).length().getInfo();
  ```
- GEE link: 
https://code.earthengine.google.com/40cbab4859b1c2d371af4f3c5cd71bb5#workspace