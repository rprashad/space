CACRT="ca.crt"
CACSR="ca.csr"
CAKEY="ca.key"
BS=2048
SHA="-sha512"
EXPIRE=1095
OPENSSL=`which openssl`
COUNTRY="US"
STATE="NJ"
LOCATION="Leonardo"
ORG="Prashad_LLC"
EMAIL="raj@prashad.net"
CADOMAIN=$1
DOMAIN=$2
OU=""
SUBJECT=""
# get domain
if [[ -z $CADOMAIN ]]; then
  read -p "Enter CA Domain: " CADOMAIN
  CADOMAIN=`echo $CADOMAIN | sed 's/\n//'`
fi

# get ou
if [[ -z $OU ]]; then
  read -p "Enter OU: " OU
  OU=`echo $OU |sed 's/\n//g'`
fi

# create working directory
if [[ ! -d $CADOMAIN ]]; then
  mkdir $CADOMAIN
fi


function selfgenca {

  SUBJECT="/C=${COUNTRY}/ST=${STATE}/L=${LOCATION}/O=${ORG}/OU=${OU}/CN=${CADOMAIN}/emailAddress=${EMAIL}"
  cmd1="$OPENSSL genrsa -des3 -out $CADOMAIN/$CAKEY $BS"
  cmd2="$OPENSSL req -new -key $CADOMAIN/$CAKEY -x509 -days $EXPIRE $SHA -subj ${SUBJECT} -out $CADOMAIN/$CACRT"
  echo "Generating CA KEY"
  $cmd1
  echo "Generating CA CRT"
  `$cmd2`
  echo $cmd2

  echo "CA Generation Complete, re-run to create server certificates that are signed with this CA"
  exit

}

function selfgenserver {

  if [[ -z $DOMAIN ]]; then
    read -p "Enter Domain: " DOMAIN
    DOMAIN=`echo $DOMAIN |sed 's/\n//g'`
  fi

  # create working directory
  if [[ ! -d "$CADOMAIN/$DOMAIN" ]]; then
    mkdir "$CADOMAIN/$DOMAIN"
  else
    echo "A directory $CADOMAIN/$DOMAIN already exists please backup/remove before proceeding"
    exit
  fi

  SUBJECT="/C=${COUNTRY}/ST=${STATE}/L=${LOCATION}/O=${ORG}/OU=${OU}/CN=${DOMAIN}/emailAddress=${EMAIL}"
  cmd1="$OPENSSL genrsa -out ${CADOMAIN}/${DOMAIN}/${DOMAIN}.key $BS"
  echo $cmd1
  cmd2="$OPENSSL req -new -key ${CADOMAIN}/${DOMAIN}/${DOMAIN}.key -subj $SUBJECT -out ${CADOMAIN}/${DOMAIN}/${DOMAIN}.csr"
  cmd3="$OPENSSL x509 -req -days $EXPIRE -in ${CADOMAIN}/${DOMAIN}/${DOMAIN}.csr -CA ${CADOMAIN}/${CACRT} -CAkey ${CADOMAIN}/${CAKEY} -CAcreateserial $SHA -out ${CADOMAIN}/${DOMAIN}/${DOMAIN}.crt"

  $cmd1
  $cmd2
  $cmd3
}

if [[ ! -e "$CADOMAIN/$CAKEY" ]]; then
  selfgenca
fi

selfgenserver
