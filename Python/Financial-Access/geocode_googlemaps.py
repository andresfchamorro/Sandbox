import csv, os, geopy
from geopy.geocoders import GoogleV3

instance = GoogleV3(api_key="", domain='maps.googleapis.com')

with open('banks_unique.csv', 'rb') as csvfile:
    spamreader = csv.reader(csvfile, delimiter=',')
    rownum = 0
    found = 0
    array = []
    for row in spamreader:
        if rownum==0:
            header = row
        else:
            success = 0
            if success==0:
                try:
                    print("geocoding " + str(rownum))
                    place_teh = row[0] + ", Pakistan"
                    place_cit = row[1] + ", Pakistan"
                    # Geocode based on tehsil
                    res = instance.geocode(place_teh, exactly_one=True, timeout=15, region="pk")
                    if res is not None:
                        array.append([row[0],row[1],res.latitude,res.longitude,1])
                        print("succesfully completed tehsil " + place_teh)
                        found += 1
                    else:
                        # Geocode based on city name
                        res2 = instance.geocode(place_cit, exactly_one=True, timeout=15, region="pk")
                        if res2 is not None:
                            array.append([row[0],row[1],res2.latitude,res2.longitude,1])
                            print("succesfully completed city " + place_cit)
                            found += 1
                        else:
                            print("couldn't find " + place_cit)
                            array.append([row[0],row[1],"NA","NA",0])
                except geopy.exc.GeopyError as err:
                    print(err)
                    print("bad request for " + place_teh)
                    array.append([row[0],row[1],"error","error",-1])
            else:
                array.append([row[0],row[1],row[2],row[3],row[4]])
        rownum += 1
    print("geocoded " + str(found))
    csvfile.close()

with open('banks_geo.csv', 'wb') as outfile:
    spamwriter = csv.writer(outfile, delimiter=",")
    spamwriter.writerow(['tehsil','city','lat','long','success'])
    spamwriter.writerows(array)
    outfile.close()
