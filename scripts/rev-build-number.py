import plistlib

path = "../src/PlaySketch2-ios/Info.plist"

print "Opening Info.plist"
list = plistlib.readPlist(path)

print "Updating Version"
old_version = int(list['CFBundleVersion'])
new_version = old_version + 1

print "Saving out Info.plist"
list['CFBundleVersion'] = new_version
plistlib.writePlist(list, path)

print "! Updated !"
print "Old version: ", old_version
print "New version: ", new_version
