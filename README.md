## Disclaimer

This a fork of what I originally posted years ago in the original NEON repo, updated to work with the newer NEON AOP H5 format.  I've posted this version in case anyone else finds it useful, but I make NO warranties or claims about its accuracy.  Use at your own risk.  For a full liability statement, see the original LICENSE.txt which I am also adhering to.


# NEON-AOP-H5toENVI

## The NEON Airborne Observation Platform HDF5 ENVI Extension.

This ENVI Extension is written in the IDL programming language, and is intended to read HDF5 formatted data files produced by the NEON Airborne Observation Platform.  These data can be acquired by here: http://www.neonscience.org/data-resources/get-data/airborne-data

This software is licensed under a BSD style 3-clause license.  See LICENSE.txt for the full license text.

To install as an ENVI extension, follow the instructions listed in "Install Guide.pdf" document.

To utilize from the IDL command line, for example to open the file and display in ENVI:

```IDL
.compile aoph5metadatafactory__define.pro
.compile aoph5toenvi.pro
nv = envi()
raster = OpenAOPh5('/path/to/some_aop_data_file.h5', DATASET_NAME='REFLECTANCE')
view = nv.getview()
layer = view.CreateLayer(raster)
```
