# install build tools
sudo yum install rpmdevtools rpmlint gpgme
sudo yum install mock

# setup gpg key and import key
gpg2 --gen-key
gpg2 --export -a "key_name" > repo_name.key
sudo rpm --import repo_name.key

# setup rpmbuild tree
rpmdev-setuptree

# create SPEC file
cd rpmbuild/SPECS
rpmddev-newspec stub

# configure your stub spec file
rpmlint stub.spec
rpmbuilder -ba stub.spec
mock --init epel-6-x86_64 --verbose
mock -r epel-6-x86_64 --rebuild stub.srpm
rpm --resign /var/lib/mock/epel-6-x86_64/results/spec.rpm
scp /var/lib/mock/epel-6-x86_64/results/spec.rpm  yumrepo.com:/var/ftp/repo/os/ver/arch/
