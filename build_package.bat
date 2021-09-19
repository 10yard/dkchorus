echo ----------------------------------------------------------------------------------------------
echo  Package the dkchorus plugin 
echo ----------------------------------------------------------------------------------------------
copy readme.md dkchorus\ /Y

echo **** package into a release ZIP getting the version from version.txt
set /p version=<VERSION
set zip_path="C:\Program Files\7-Zip\7z"
del releases\dkchorus_plugin_%version%.zip
%zip_path% a releases\dkchorus_plugin_%version%.zip dkchorus