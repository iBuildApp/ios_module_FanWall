#!/bin/bash
for i in $( find ./mFanWall -name '*.h' -type f ); do
headerdoc2html -j -o ./mFanWall/Documentation $i
done

gatherheaderdoc ./mFanWall/Documentation


sed -i.bak 's/<html><body>//g' ./mFanWall/Documentation/masterTOC.html
sed -i.bak 's|<\/body><\/html>||g' ./mFanWall/Documentation/masterTOC.html
sed -i.bak 's|<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN" "http://www.w3.org/TR/REC-html40/loose.dtd">||g' ./mFanWall/Documentation/masterTOC.html