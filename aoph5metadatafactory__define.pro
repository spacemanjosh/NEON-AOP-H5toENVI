; docformat = 'rst'
;+
; :Description:
;     AOPh5MetadataFactory is a class with static methods designed
;     to create and return metadataobjects such as an ENVIRasterMetaData or an
;     ENVIStandardRasterSpatialRef.  These objects can then
;     be passed to the ENVI Raster constructor.
;     
; :Requires:
;     ENVI 5.2 / IDL 8.4
;
; :Author: Josh Elliott jelliott@neoninc.org
;
; :History:
;   Created Jan 22, 2015 3:32:26 PM
;   
; $Rev: 7397 $
; $Date: 2015-10-15 09:45:22 -0600 (Thu, 15 Oct 2015) $
;-

;-------------------------------------------------------------------------------
;+
; :Description:
;    Constructor
;
; :Keywords:
;    _EXTRA
;-
function AOPh5MetadataFactory::Init, _EXTRA=extra
  compile_opt idl2  
  if (isa(extra)) then begin
    self.AOPh5MetadataFactory::SetProperty, _EXTRA=extra
  endif
  return, 1
end

;-------------------------------------------------------------------------------
;+
; :Description:
;     Destructor
;-
pro AOPh5MetadataFactory::Cleanup
  compile_opt idl2
  
end

;-------------------------------------------------------------------------------
;+
; :Description:
;     Accessor
;-
pro AOPh5MetadataFactory::GetProperty, _REF_EXTRA=extra
  compile_opt idl2

end

;-------------------------------------------------------------------------------
;+
; :Description:
;     Mutator
;-
pro AOPh5MetadataFactory::SetProperty, _EXTRA=extra
  compile_opt idl2

end

;-------------------------------------------------------------------------------
;+
; :Description:
;    Static method to return an ENVIRasterMetadata object for a particular dataset
;    contained within an h5 file.
;    
; :Params:
;    h5           [in, req, Hash] : h5 file structure, Hash() object.
;    data_set_name  [in, req, IDL_String] : Data set name.
;    
; :Returns:
;    ENVIRasterMetadata
;-
function AOPh5MetadataFactory::CreateMetadata, h5, dataset_name
  compile_opt static, idl2
  
  metadata = !null
  
  dataset_name_parts = strsplit(dataset_name, '/', /EXTRACT)
  name_key = strupcase(dataset_name_parts[-1])
  
  case (name_key) of
    'REFLECTANCE_DATA': metadata = AOPh5MetadataFactory._Reflectance(h5, dataset_name)
    'DARK_DENSE_VEGETATION_CLASSIFICATION' : metadata = AOPh5MetadataFactory._Class(h5, dataset_name)
    'HAZE_CLOUD_WATER_MAP' : metadata = AOPh5MetadataFactory._Class(h5, dataset_name)
    else: metadata = AOPh5MetadataFactory._Raster(h5, dataset_name)
  endcase
  
  return, metadata
end

;-------------------------------------------------------------------------------
;+
; :Description:
;    Static method to return an ENVIStandardRasterSpatialRef for the h5 datasets.
;
; :Params:
;    h5           [in, req, Hash] : h5 file structure, Hash() object.
;-
function AOPh5MetadataFactory::CreateSpatialRef, h5
  compile_opt static, idl2
  
  ; Get the site key
  site = _find_site_key(h5)
    
  ; Get coordinate system information
  map_info = h5[site, 'REFLECTANCE', 'METADATA', 'COORDINATE_SYSTEM', 'MAP_INFO','_DATA', 0]
  map_info_parts = strsplit(map_info, ',', /EXTRACT)
  coord_sys_string = h5[site, 'REFLECTANCE', 'METADATA', 'COORDINATE_SYSTEM', 'COORDINATE_SYSTEM_STRING','_DATA', 0]
  
  ; Get the pixel size
  ps = double(map_info_parts[5:6])
  
  ; Get the pixel tie point
  tp = double(map_info_parts[1:2])
  
  ; Get the map tie point
  tm = double(map_info_parts[3:4])
  
  ; Get the rotation, if any
  if (map_info_parts[-1].Contains('rotation')) then begin
    rotation = double((strsplit(map_info_parts[-1],'=', /EXTRACT))[-1])
  endif else begin
    rotation = !null
  endelse
  
  ; Create the spatial ref object
  spatialRef = ENVIStandardRasterSpatialRef( $
    COORD_SYS_STR=coord_sys_string, $
    PIXEL_SIZE=ps, $
    TIE_POINT_MAP=tm, $
    TIE_POINT_PIXEL=[0,0], $
    ROTATION=rotation)
  
  return, spatialRef
end

;+
; :Description:
;
;-
function AOPh5MetadataFactory::CreateTime, h5
  compile_opt idl2

  ; TODO: We should be adding the Acquisition time to the h5 file metadata.
  return, 1
end


;-------------------------------------------------------------------------------
;+
; :Description:
;    Reflectance
;
; :Params:
;    h5           [in, req, Hash] : h5 file structure, Hash() object.
;    data_set_name  [in, req, IDL_String] : Data set name.
;
; :Returns:
;    ENVIRasterMetadata
;-
function AOPh5MetadataFactory::_Reflectance, h5, data_set_name
  compile_opt static, idl2

  metadata = envirastermetadata()
  
  ; Get the site key
  site = _find_site_key(h5)

  ; Wavelength / Spectral Radiance Bands
  wavelength_key = '/' + h5[site, '_NAME'] + $
    '/' + h5[site, 'REFLECTANCE', '_NAME'] + $
    '/' + h5[site, 'REFLECTANCE', 'METADATA', '_NAME'] + $
    '/' + h5[site, 'REFLECTANCE', 'METADATA', 'SPECTRAL_DATA', '_NAME']+ $
    '/' + h5[site, 'REFLECTANCE', 'METADATA', 'SPECTRAL_DATA', 'WAVELENGTH', '_NAME']
  metadata.AddItem, 'wavelength', h5_getdata(h5['_FILE'], wavelength_key)
  units = h5[site, 'REFLECTANCE', 'METADATA', 'SPECTRAL_DATA', 'WAVELENGTH', 'UNITS', '_DATA']
  metadata.AddItem, 'wavelength units', units.CapWords()

  ; FWHM
  fwhm_key = '/' + h5[site, '_NAME'] + $
    '/' + h5[site, 'REFLECTANCE', '_NAME'] + $
    '/' + h5[site, 'REFLECTANCE', 'METADATA', '_NAME'] + $
    '/' + h5[site, 'REFLECTANCE', 'METADATA', 'SPECTRAL_DATA', '_NAME']+ $
    '/' + h5[site, 'REFLECTANCE', 'METADATA', 'SPECTRAL_DATA', 'FWHM', '_NAME']
  metadata.AddItem, 'fwhm', h5_getdata(h5['_FILE'], fwhm_key)
  
  ; interleave 
  ;metadata.AddItem, 'interleave', 'BIP'
  
  AOPh5MetadataFactory._AddCommonRasterMetadata, h5, data_set_name, metadata

  return, metadata
end

;+
; :Description:
;
;-
function AOPh5MetadataFactory::_Class, h5, data_set_name
  compile_opt static, idl2

  metadata = envirastermetadata()
  AOPh5MetadataFactory._AddCommonClassificationMetadata, h5, data_set_name, metadata
  return, metadata
end

;+
; :Description:
;
;-
function AOPh5MetadataFactory::_Raster, h5, data_set_name
  compile_opt static, idl2

  metadata = envirastermetadata()
  AOPh5MetadataFactory._AddCommonRasterMetadata, h5, data_set_name, metadata
  return, metadata

  return, 1
end

;+
; :Description:
;
;-
pro AOPh5MetadataFactory::_AddCommonRasterMetadata, _h5, data_set_name, metadata
  compile_opt static, idl2
  
  keys = strsplit(strupcase(data_set_name), '/', /EXTRACT)
  h5 = _h5
  foreach key, keys do h5 = h5[key]
  
  ; Scale factor
  if (h5.haskey('SCALE_FACTOR')) then begin
    metadata.AddItem, 'reflectance scale factor', h5['SCALE_FACTOR','_DATA']
  endif
    
  ; Description
  if (h5.haskey('DESCRIPTION')) then begin
    metadata.AddItem, 'description', h5['DESCRIPTION','_DATA']
  endif
  
  ; data-ignore-value
  if (h5.haskey('DATA_IGNORE_VALUE')) then begin
    metadata.AddItem, 'data ignore value', fix(h5['DATA_IGNORE_VALUE', '_DATA'])
  endif
  
  ; Units, if specified
  if (h5.haskey('UNITS')) then begin
    metadata.AddItem, 'data units', h5['UNITS', '_DATA']
  endif
end

;+
; :Description:
;
;-
pro AOPh5MetadataFactory::_AddCommonClassificationMetadata, _h5, data_set_name, metadata
  compile_opt static, idl2
  
  keys = strsplit(strupcase(data_set_name), '/', /EXTRACT)
  h5 = _h5
  foreach key, keys do h5 = h5[key]
  
  ; Add class names and look-up-table (LUT)
  classNames = h5['CLASS_NAMES', '_DATA']
  classLookup = byte(fix(h5['CLASS_LOOKUP', '_DATA']))
  classLookup = reform(classLookup, 3, classLookup.length/3)
  metadata.AddItem, 'classes', classNames.length
  metadata.AddItem, 'class names', classNames
  metadata.AddItem, 'class lookup', classLookup
  
  ; Add band name(s)
  bandNames = h5['BAND_NAMES', '_DATA']
  metadata.AddItem, 'band names', bandNames
end


;-------------------------------------------------------------------------------
;+
; :Description:
;     Class data definition procedure
;-
pro AOPh5MetadataFactory__define
  compile_opt idl2

  !NULL = {AOPh5MetadataFactory,  $
    inherits IDL_Object           $
  }
end
