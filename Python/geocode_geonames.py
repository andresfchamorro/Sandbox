import csv, os, geopy
from geopy.geocoders import GeoNames

instance = GeoNames(country_bias="PK", username="", timeout=15)

with open('bank_tehsils.csv', 'rb') as csvfile:
    spamreader = csv.reader(csvfile, delimiter=',')
    rownum = 0
    array = []
    for row in spamreader:
        if rownum==0:
            header = row
        else:
            try:
                print("geocoding " + str(rownum))
                place = row[1]
                # Geocode based on name
                location = GeoNames.geocode(instance,place, timeout=15)
                if hasattr(location,"latitude"):
                    array.append([row[0],place,location.latitude,location.longitude])
                    print("succesfully completed " + place)
                else:
                    print("couldn't find " + place)
                    array.append([row[0],place,"NA","NA"])
            except geopy.exc.GeopyError as err:
                print(err)
                print("bad request for " + place)
                array.append([row[0],place,"error","error"])
        rownum += 1
    csvfile.close()

with open('tehsils_geonames.csv', 'wb') as outfile:
    spamwriter = csv.writer(outfile, delimiter=",")
    spamwriter.writerow(['id','place','lat','long'])
    spamwriter.writerows(array)
    outfile.close()
