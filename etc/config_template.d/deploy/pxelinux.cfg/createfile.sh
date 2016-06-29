#!/bin/bash
for i in 00{1..9} 0{10..90}; do
  echo atlas-$i
  hex=`gethostip -x atlas-$i`
  echo $hex
  cp pxe $hex
done
