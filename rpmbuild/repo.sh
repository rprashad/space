# To be added to /etc/profile.d/

buildroot=$HOME/rpmbuild
epel="epel-6-x86_64"
ftproot="/var/ftp/repo/CentOS/6.3/x86_64"
srcroot="/var/ftp/src/"
ftpsite="wpprs1rpm01.rs.warbyparker.com/repo/CentOS/6.3/x86_64"
MOCKRESULT="/var/lib/mock/$epel/result"
MOCKROOT="/var/lib/mock/$epel/root"
export epel ftproot ftpsite mockresults mockroot

function signrpm() {
  rpm --resign $MOCKRESULT/*.rpm
}

function rpm2ftp() {
  sudo cp $MOCKRESULT/*.rpm $ftproot/
}


function cleancache() {
  sudo /usr/local/bin/genrepo.sh
  sudo yum --enablerepo=warbyparker clean metadata
  sudo yum makecache
}

function mockinit() {
	mock --init $epel
}

function makesrpm() {
  srpm=`ls $buildroot/SRPMS/${1}*`;
  rm $srpm
  rpmbuild -bs $buildroot/SPECS/$1.spec --verbose
}

function mockbuild() {
	srpm=`ls $buildroot/SRPMS/${1}*`;
	mock -r $epel rebuild $srpm  --verbose
}

function lsspec() {
	ls $buildroot/SPECS
}

function lssrpm() {
	ls $buildroot/RPMS
}

function buildall() {
	src=$1
	makesrpm $src
	mockbuild $src
	signrpm
	rpm2ftp
	cleancache
}

function mockroot() {
	cd $MOCKROOT
}

function mockresult() {
	cd $MOCKRESULT

}

function extractrpm() {
rpm=$1
type=`file -b $1| awk '{print $1}'`
if [ $type == "RPM" ]
  then
  rpm2cpio $rpm| cpio -idmv
  echo "rpm extraction complete for: $rpm"
else
  echo "This doesn't seem like an RPM file"
fi

}

