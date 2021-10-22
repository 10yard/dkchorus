set version=v0.11

set zip_path="C:\Program Files\7-Zip\7z"
del releases\dkchorus_plugin_%version%.zip

copy readme.md dkchorus\ /Y
%zip_path% a releases\dkchorus_plugin_%version%.zip dkchorus
del dkchorus\readme.md /Q