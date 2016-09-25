# (re)generate a pubic key from a given private rsa key

function makepubkey() {
   KEY=$1
   ssh-keygen -y -f $KEY | tee $KEY.pub
   echo "Public Key Created: $KEY.pub"
}

function genpub() {
  KEY=$1
  if [[ ! -z $KEY ]]; then
    if [[ -e $KEY ]]; then
      makepubkey $KEY
    else
      echo "Private key: '$key' not found!"
      exit 2
    fi
  else
    echo "genpub is a wrapper for: 'ssh-keygen -y -f site.pem > site.pem.pub, just pass a key as argument"
  fi
}

export genpub
