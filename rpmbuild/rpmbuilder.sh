#!/bin/bash

# rajendra prashad 2013 - Warby Parker <raj@warbyparker.com>
# this file should be sourced from the buildmaster's .bash_profile
# this script helps facilitate the buildout of RPM packages both manually
# and through the Bamboo build process.  Please be careful if/when making
# modifications to this script.

BUILDROOT=$HOME/rpmbuild
EPEL="epel-6-x86_64"
FTPROOT="/var/ftp/repo/CentOS/6.3/x86_64"
SOURCE="/var/ftp/src/"
FTPSITE="p-yum01.warbyparker.com/repo/CentOS/6.3/x86_64"
MOCKRESULT="/var/lib/mock/$EPEL/result"
MOCKROOT="/var/lib/mock/$EPEL/root"
export EPEL FTPROOT FTPSITE MOCKRESULTS MOCKROOT

# BUILD RPM SOURCE
function makesrpm() {

  echo "Making Source RPM"
  srpm=`ls $BUILDROOT/SRPMS/${1}* 2> /dev/null`;
  if [[ -e $srpm ]]; then
    rm $srpm
  fi

  if [[ -e "$BUILDROOT/SPECS/$1.spec" ]]; then
    rpmbuild -bs $BUILDROOT/SPECS/$1.spec --verbose
    return 0
  else
    echo "Spec file: $BUILDROOT/SPECS/$1.spec not found!"
    return 1
  fi
}

# BUILD IN MOCK ENVIRONMENT
function mockbuild() {

  srpm=`ls $BUILDROOT/SRPMS/${1}* 2>/dev/null`;
    if [[ ! -z  $srpm ]]; then
      echo "Mock Build"
      mock -r $EPEL rebuild $srpm  --verbose
      return 0
    else
      echo "mockbuild cannot continue - no SRPM found!"
      return 1
    fi
}

# SIGN AND COPY RPM IN PLACE
function signandcopy() {
	
  count=`ls $MOCKRESULT | egrep "\.rpm$" | wc -l`;
  if [[ $count > 0 ]]; then
    rpm --resign $MOCKRESULT/*.rpm
    sudo mv $MOCKRESULT/*.rpm $FTPROOT/
    return 0
  else
    echo "No RPMS found to sign!"
    return 1
  fi
}

# CLEAN THE REPOSITORY CACHE
function cleancache() {

  destdir="/var/ftp/repo/CentOS/6.3"
  for arch in i386 x86_64
    do
      pushd ${destdir}/${arch} >/dev/null 2>&1
        createrepo .
      popd >/dev/null 2>&1
  done

  sudo yum --enablerepo=warbyparker clean metadata
  sudo yum makecache
}

# INITIALIZE CLEAN REPO
function mockinit() {
	mock --init $EPEL
}

function buildall() {

   src=$1
   if [[ ! -z "$src" ]]; then
	if  makesrpm $src ; then
          if mockbuild $src; then
	    if signandcopy $src; then
	        cleancache
	    fi
	  fi
	fi
   else
     echo "buildall requires the name of the spec file without extension!"
   fi
}

# EXTRACT AN RPM
function extractrpm() {

  rpm=$1
  type=`file -b $1| awk '{print $1}'`
  if [[ $type == "RPM" ]]; then
      rpm2cpio $rpm| cpio -idmv
      echo "rpm extraction complete for: $rpm"
  else
    echo "This doesn't seem like an RPM file"
  fi
}

