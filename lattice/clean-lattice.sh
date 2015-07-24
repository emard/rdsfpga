#!/bin/sh

DIR=diamond
PROJECT=project
TOP_LEVEL_ENTITY="main"
# file list to copy
COPY=""
# file list to symlink
SYMLINK="lattice/ulx2s.lpf \
  lattice/build.sh lattice/build.tcl \
  lattice/${PROJECT}.ldf \
  lattice/lattice_pll_25MHz_250MHz.vhd \
  enkoder.vhd \
  tonegen.vhd \
  message.vhd \
  strobe.vhd \
  rds.vhd \
  fmgen.vhd \
  main.v"

echo "COPY=${COPY}"
echo "SYMLINK=${SYMLINK}"

RM=rm
MKDIR=mkdir
BUGGYNAME=$(echo "${PROJECT}" | sed -e "s/\(.*\)\(...\)/\1_\1\2\2/g")

$RM -rf ${DIR}
$MKDIR -p ${DIR}
cd ${DIR}
for name in ${COPY}
do
  echo "copying $name"
  cp ../$name .  
done
for name in ${SYMLINK}
do
  echo "symlinking $name"
  ln -s ../$name .  
done
echo "create bugfix symlink"
mkdir -p ${PROJECT}
cd ${PROJECT}
ln -s "${PROJECT}_${PROJECT}.p2t" "${BUGGYNAME}.p2t"

# create file list for including into project
cd ..
FILELIST=$(find . -type l -name "*.vhd")
(
cat ../lattice/project.ldf.first
echo "        <Options def_top=\"${TOP_LEVEL_ENTITY}\"/>"
for file in $(ls *.vhd)
do
  if [ "${file}" = "${TOP_LEVEL_ENTITY}.vhd"  ]
  then
    OPTIONS=" top_module=\"${TOP_LEVEL_ENTITY}\""
  else
    OPTIONS=""
  fi
  echo "        <Source name=\"${file}\" type=\"VHDL\" type_short=\"VHDL\"><Options${OPTIONS}/></Source>"
done
for file in $(ls *.v)
do
  if [ "${file}" = "${TOP_LEVEL_ENTITY}.v"  ]
  then
    OPTIONS=" top_module=\"${TOP_LEVEL_ENTITY}\""
  else
    OPTIONS=""
  fi
  echo "        <Source name=\"${file}\" type=\"Verilog\" type_short=\"Verilog\"><Options${OPTIONS}/></Source>"
done
cat ../lattice/project.ldf.last
) > project.ldf
