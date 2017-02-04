#!/bin/bash
if [ "$1" == '' ] || [ "$2" == '' ] || [ "$3" == '' ]; then
    echo "Usage: $0 <video folder> <file extension> <option> <starttime> <endtime>";
    echo "<option 1> : create sub-directories by file names";
    echo "<option 2> : crop videos in the middle";
    echo "<option 3> : extract frames from cropped videos";
    echo "<option 0> : Run option 1, 2 and 3"
    exit;
fi

if [ "$3" == 1 ] || [ "$3" == 0 ]; then
for file in "$1"/*."$2"; do
    dir=${file%.*}
    mkdir -p "$dir"
    #ffmpeg -i "$file" -filter:v "crop=300:720:490:0" "${dir}_cropped.avi"
    #ffmpeg -i "${dir}_cropped.avi" -vf "select=not(mod(n\,3))" -vsync vfr -q:v 2 "${dir}/%05d.jpg"
done
fi

if [ "$3" == 2 ] || [ "$3" == 0 ]; then
for file in "$1"/*."$2"; do
    dir=${file%.*}
    #mkdir -p "$dir"
    ffmpeg -i "$file" -filter:v "crop=300:720:490:0" "${dir}_cropped.avi"
    #ffmpeg -i "${dir}_cropped.avi" -vf "select=not(mod(n\,3))" -vsync vfr -q:v 2 "${dir}/%05d.jpg"
done
fi

if [ "$3" == 3 ] || [ "$3" == 0 ]; then
for file in "$1"/*."$2"; do
    dir=${file%.*}
    #mkdir -p "$dir"
    #ffmpeg -i "$file" -filter:v "crop=300:720:490:0" "${dir}_cropped.avi"
    ffmpeg -i "${dir}_cropped.avi" -vf "select=not(mod(n\,3))" -vsync vfr -q:v 2 "${dir}/%05d.jpg"
done
fi