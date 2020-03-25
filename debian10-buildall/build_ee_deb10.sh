#!/bin/bash
EE_BUILD_HOME=`pwd`
EE_BUILD_EE_PATH="${EE_BUILD_HOME}/EmptyEpsilon"
EE_BUILD_SP_PATH="${EE_BUILD_HOME}/SeriousProton"
EE_BUILD_ZIP_PATH="${EE_BUILD_HOME}/EE_ZIP"
EE_BUILD_DATE="$(date +'%Y%m%d')"
EE_BUILD_CMAKE="${EE_BUILD_EE_PATH}/cmake"

set -e

sudo apt-get update
sudo apt-get -y dist-upgrade
sudo apt-get -y install joe unzip cmake git ninja-build wget build-essential libsfml-dev python-minimal zip mingw-w64 p7zip-full  apt-transport-https ca-certificates wget dirmngr gnupg software-properties-common

#openjdk 8
wget -qO - https://adoptopenjdk.jfrog.io/adoptopenjdk/api/gpg/key/public | sudo apt-key add -
sudo add-apt-repository --yes https://adoptopenjdk.jfrog.io/adoptopenjdk/deb/
sudo apt update
sudo apt -y install adoptopenjdk-8-hotspot


sudo apt purge -y python2.7-minimal

sudo rm -f /usr/bin/python
sudo ln -sfn /usr/bin/python3.7 /usr/bin/python
alias python='python3.7' 


# Clone repos.
echo "Cloning or updating git repos..."

## Get SeriousProton and EmptyEpsilon.
if [ ! -d "${EE_BUILD_SP_PATH}" ]; then
  echo "-   Cloning SeriousProton repo to ${EE_BUILD_SP_PATH}..."
  git clone https://github.com/daid/SeriousProton.git "${EE_BUILD_SP_PATH}"
else
  echo "-   Fetching and merging SeriousProton repo at ${EE_BUILD_SP_PATH}..."
  ( cd "${EE_BUILD_SP_PATH}";
    git fetch --all && git merge --ff-only; )
fi
echo

if [ ! -d "${EE_BUILD_EE_PATH}" ]; then
  echo "-   Cloning EmptyEpsilon repo to ${EE_BUILD_EE_PATH}..."
  git clone https://github.com/daid/EmptyEpsilon.git "${EE_BUILD_EE_PATH}"
else
  echo "-   Fetching and merging EmptyEpsilon repo at ${EE_BUILD_EE_PATH}..."
  ( cd "${EE_BUILD_EE_PATH}";
    git fetch --all && git merge --ff-only; )
fi
echo

## Write commit IDs for each repo into a file for reference.
for i in "${EE_BUILD_SP_PATH}" "${EE_BUILD_EE_PATH}"
do (
  cd "${i}";
  echo "$(git log --pretty='oneline' -n 1)" > "${i}/commit.log";
); done
echo


## Build EE for win32
echo "Building EE for win32"
cd "${EE_BUILD_EE_PATH}"
if [ ! -d _build_win32 ]; then
  mkdir _build_win32
fi
cd _build_win32
### Use the CMake toolchain from EE to make it easier to compile for Windows.
rm -rf script_reference.html
cmake .. -G Ninja -DSERIOUS_PROTON_DIR=../../SeriousProton -DCMAKE_TOOLCHAIN_FILE=../cmake/mingw.toolchain -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_MAKE_PROGRAM="/usr/bin/ninja"
cmake --build . --target package

cp EmptyEpsilon.zip /vagrant/


## Build EE for debian
echo "Building EE for debian"
cd "${EE_BUILD_EE_PATH}"
if [ ! -d _build_native ]; then
  mkdir _build_native
fi
cd _build_native
### Use the CMake toolchain from EE to make it easier to compile for Windows.
rm -rf script_reference.html
cmake .. -G Ninja -DSERIOUS_PROTON_DIR=../../SeriousProton -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_MAKE_PROGRAM="/usr/bin/ninja"
cmake --build . --target package

cp EmptyEpsilon.deb /vagrant/






## Build EE for Android
echo "Building EE for Android"
cd "${EE_BUILD_EE_PATH}"
if [ ! -d _build_android ]; then
  mkdir _build_android
fi
cd _build_android
cmake .. -G Ninja -DSERIOUS_PROTON_DIR=../../SeriousProton -DCMAKE_TOOLCHAIN_FILE=../cmake/android.toolchain -DCMAKE_BUILD_TYPE=Release -DCMAKE_MAKE_PROGRAM="/usr/bin/ninja" > /vagrant/build.log
if [ ! -d /home/vagrant/.keystore ]; then
    keytool -genkeypair -dname "cn=gwaland, ou=na, o=na, c=US" -alias "Android" -keypass password -keystore /home/vagrant/.keystore -storepass password -keyalg RSA -keysize 2048 -validity 10000
fi
cmake --build . >> /vagrant/build.log

cp EmptyEpsilon.apk /vagrant/








