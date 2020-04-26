; docformat = 'rst'
;+
; :Description:
;    Open an AOP H5 raster and retrieve a reference to the Reflectance dataset.
;    This function allows for programatic usage of the reader.
;
; :Params:
;    filename [in, req, String] : File name.
;
; :Keywords:
;    DATASET_NAME [in, opt, string] : H4 dataset name.
;
; :Author: Josh Elliott
; 
; :History:
;   2019-04-26: Moved this to a separate file to allow IDL to auto-find it on it's path.
;-
function OpenAOPH5, filename, DATASET_NAME=datasetName
  compile_opt idl2
  AOPH5toENVI, FILENAMES=filename, DATASET_NAME=datasetName, _getrasters=rasters, /headless
  if ~isa(rasters) then rasters = !null
  return, (rasters.length eq 1) ? rasters[0] : rasters
end
