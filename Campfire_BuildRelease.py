import os
import shutil
import subprocess

print " "
print "=============================="
print "|  Campfire Release Builder  |"
print "|            .(              |"
print "|           /%/\             |"
print "|          (%(%))            |"
print "|         .-'..`-.           |"
print "|         `-'.'`-'           |"
print "=============================="
print " "
user_input = raw_input("Enter the release version: ")
game_input = raw_input("(C)lassic Skyrim or Skyrim (SE)?")

if game_input == "C":
    print "Generating Classic Skyrim build."
elif game_input == "SE":
    print "Generating Skyrim SE build."
else:
    print "Unknown game type entered. Please enter C or SE."
    exit()

os.chdir("..\\")

# Build the temp directory
print "Creating temp directories..."
tempdir = ".\\tmp\\Data\\"
os.makedirs('./tmp/Data/readmes')
os.makedirs('./tmp/Data/Interface/campfire')
os.makedirs('./tmp/Data/Interface/Translations')
os.makedirs('./tmp/Data/meshes/campfire')
os.makedirs('./tmp/Data/meshes/mps')
os.makedirs('./tmp/Data/Scripts/Source')
os.makedirs('./tmp/Data/textures/campfire')

# Copy the project files
print "Copying project files..."
with open("./Campfire/CampfireArchiveManifest.txt") as manifest:
    lines = manifest.readlines()
    for line in lines:
        shutil.copy(".\\Campfire\\" + line.rstrip('\n'), tempdir + line.rstrip('\n'))

print "Copying external dependencies..."
with open("./Campfire/CampfireArchiveManifestExternal.txt") as manifest:
    lines = manifest.readlines()
    if game_input == "C":
        for line in lines:
            shutil.copy(".\\Campfire\\external\\Skyrim\\" + line.rstrip('\n'), tempdir + line.rstrip('\n'))
    elif game_input == "SE":
        for line in lines:
            shutil.copy(".\\Campfire\\external\\SkyrimSE\\" + line.rstrip('\n'), tempdir + line.rstrip('\n'))

# Build the directories
dirname = "./Campfire " + user_input + " Release"
if not os.path.isdir(dirname):
    print "Creating new build..."
    os.makedirs(dirname + "/Campfire")
else:
    print "Removing old build of same version..."
    shutil.rmtree(dirname)
    os.mkdir(dirname)

os.makedirs(dirname + "/readmes")
os.makedirs(dirname + "/SKSE/Plugins/CampfireData")

# Generate BSA archive
print "Generating BSA archive..."
if game_input == "C":
    shutil.copy('./Campfire/external/Skyrim/Archive.exe', './tmp/Archive.exe')
elif game_input == "SE":
    shutil.copy('./Campfire/external/SkyrimSE/Archive.exe', './tmp/Archive.exe')
shutil.copy('./Campfire/CampfireArchiveBuilder.txt', './tmp/CampfireArchiveBuilder.txt')
shutil.copy('./Campfire/CampfireArchiveManifest.txt', './tmp/CampfireArchiveManifest.txt')

os.chdir("./tmp")
subprocess.call(['./Archive.exe', './CampfireArchiveBuilder.txt'])
os.chdir("..\\")

# Copy files - Mod
shutil.copyfile("./Campfire/Campfire.esm", dirname + "/Campfire.esm")
shutil.copyfile("./tmp/Campfire.bsa", dirname + "/Campfire.bsa")
shutil.copyfile("./Campfire/SKSE/Plugins/CampfireData/READ_THIS_PLEASE_AND_DO_NOT_DELETE.txt", dirname + "/SKSE/Plugins/CampfireData/READ_THIS_PLEASE_AND_DO_NOT_DELETE.txt")
if game_input == "C":
    shutil.copyfile("./Campfire/external/Skyrim/SKSE/Plugins/StorageUtil.dll", dirname + "/SKSE/Plugins/StorageUtil.dll")
elif game_input == "SE":
    shutil.copyfile("./Campfire/external/SkyrimSE/SKSE/Plugins/PapyrusUtil.dll", dirname + "/SKSE/Plugins/PapyrusUtil.dll")
shutil.copyfile("./Campfire/readmes/Campfire_readme.txt", dirname + "/readmes/Campfire_readme.txt")
shutil.copyfile("./Campfire/readmes/Campfire_license.txt", dirname + "/readmes/Campfire_license.txt")
shutil.copyfile("./Campfire/readmes/Campfire_changelog.txt", dirname + "/readmes/Campfire_changelog.txt")

# Clean Up
print "Removing temp files..."
shutil.rmtree("./tmp")

# Create release zip
zip_name_ver = user_input.replace(".", "_")
shutil.make_archive("./Campfire_" + zip_name_ver + "_Release", format="zip", root_dir=dirname)
shutil.move("./Campfire_" + zip_name_ver + "_Release.zip", dirname + "/Campfire_" + zip_name_ver + "_Release.zip")
print "Created " + dirname + "/Campfire_" + zip_name_ver + "_Release.zip"
print "Done!"
