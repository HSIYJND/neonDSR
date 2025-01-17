#!/bin/bash
platform=1
resolution=1
startLongitude_e4=-1280000
stopLongitude_e4=-980001
startLatitude_e4=150000
stopLatitude_e4=449999
startTime=201200000000
stopTime=201300000000

iquery -anq "remove(ndvi)" > /dev/null 2>&1

attrs="<ndvi:double null>"
dims="[x=1:300000,10000,0,y=1:300000,10000,0]"
schema=$attrs$dims

iquery -anq "create immutable empty array ndvi $schema" > /dev/null 2>&1

echo "Calculating NDVI values..."

time iquery -anq "
    redimension_store(
        apply(
            between(
                join(
                    attribute_rename(
                        band_1_measurements,
                        reflectance,
                        red
                    ),
                    attribute_rename(
                        band_2_measurements,
                        reflectance,
                        nir
                    )
                ),
                $startLongitude_e4, $startLatitude_e4, $startTime, $platform, $resolution,
                $stopLongitude_e4, $stopLatitude_e4, $stopTime, $platform, $resolution
            ),
            x, longitude_e4 - $startLongitude_e4 + 1,
            y, latitude_e4 - $startLatitude_e4 + 1,
            ndvi, (nir - red) / (nir + red)
        ),
        ndvi,
        max(ndvi) as ndvi
    )
"

