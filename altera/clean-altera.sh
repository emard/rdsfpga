#!/bin/sh

DIR=quartus
PROJECT=project
COPY=""
# SYMLINK="main.v altera/Makefile altera/tb276.pin altera/main.qsf altera/project.qpf"
SYMLINK="main.v altera/Makefile altera/tb276.pin"

echo $COPY
echo $SYMLINK
RM=rm
MKDIR=mkdir
BUGGYNAME=$(echo "${PROJECT}" | sed -e "s/\(.*\)\(...\)/\1_\1\2\2/g")

$RM -rf ${DIR}
mkdir -p ${DIR}
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
