#!/bin/bash -e
# Copyright 2016 C.S.I.R. Meraka Institute
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


# build script for fitsio
. /etc/profile.d/modules.sh
SOURCE_FILE=${NAME}${VERSION}.tar.gz

# We provide the base module which all jobs need to get their environment on the build slaves
module add ci
module add bzip2
# Workspace is the "home" directory of jenkins into which the project itself will be created and built.
mkdir -p $WORKSPACE
# SRC_DIR is the local directory to which all of the source code tarballs are downloaded. We cache them locally.
mkdir -p $SRC_DIR
# SOFT_DIR is the directory into which the application will be "installed"
mkdir -p $SOFT_DIR

#  Download the source file if it's not available locally.
#  we were originally using ncurses as the test application
if [ ! -e ${SRC_DIR}/${SOURCE_FILE}.lock ] && [ ! -s ${SRC_DIR}/${SOURCE_FILE} ] ; then
  touch  ${SRC_DIR}/${SOURCE_FILE}.lock
  echo "seems like this is the first build - let's get the source"
  wget http://heasarc.gsfc.nasa.gov/FTP/software/fitsio/c/$SOURCE_FILE -O $SRC_DIR/$SOURCE_FILE
  echo "releasing lock"
  rm -v ${SRC_DIR}/${SOURCE_FILE}.lock
elif [ -e ${SRC_DIR}/${SOURCE_FILE}.lock ] ; then
  # Someone else has the file, wait till it's released
  while [ -e ${SRC_DIR}/${SOURCE_FILE}.lock ] ; do
    echo " There seems to be a download currently under way, will check again in 5 sec"
    sleep 5
  done
else
  echo "continuing from previous builds, using source at " ${SRC_DIR}/${SOURCE_FILE}
fi

tar xvzf ${SRC_DIR}/${SOURCE_FILE} -C ${WORKSPACE} --skip-old-files

#  generally tarballs will unpack into the NAME-VERSION directory structure. If this is not the case for your application
#  ie, if it unpacks into a different default directory, either use the relevant tar commands, or change
#  the next lines

# We will be running configure and make in this directory
cd $WORKSPACE/$NAME
# Note that $SOFT_DIR is used as the target installation directory.
./configure \
--enable-sse2 \
--enable-ssse3 \
--prefix=${SOFT_DIR} \
--enable-reentrant \
--with-bzip2=${BZLIB_DIR}

make
make shared
echo "is the statically-linked library present ?"
find . -name "*.a"
echo  "is the dynamically-linked library present ?"
find . -name "*.so*"
