#!/bin/sh

export SIMPLECA_DIR=${SIMPLECA_DIR:-/data}
export SIMPLECA_KEYSIZE=${SIMPLECA_KEYSIZE:-2048}
export SIMPLECA_PASSWORD=${SIMPLECA_PASSWORD:-"admin001"}
export SIMPLECA_EXPIRATION=${SIMPLECA_EXPIRATION:-3650}
export SIMPLECA_DEFAULTMD=${SIMPLECA_DEFAULTMD:-"sha256"}

export SIMPLECA_COUNTRYNAME=${SIMPLECA_COUNTRYNAME:-"FR"}
export SIMPLECA_STATE=${SIMPLECA_STATE:-"France"}
export SIMPLECA_LOCALITY=${SIMPLECA_LOCALITY:-"Paris"}
export SIMPLECA_ORGANIZATION=${SIMPLECA_ORGANIZATION:-"MyOrg"}
export SIMPLECA_UNIT=${SIMPLECA_UNIT:-"MyUnit"}
export SIMPLECA_COMMONNAME=${SIMPLECA_COMMONNAME:-""}
export SIMPLECA_EMAILADDRESS=${SIMPLECA_EMAILADDRESS:-"nobody@nowhere.com"}

do_mkdir() {
    dir="$1"
    if [ ! -d ${dir} ]; then 
        echo "Creating ${dir}"
        mkdir -p ${dir}
    fi
}

do_mkdir ${SIMPLECA_DIR}
do_mkdir ${SIMPLECA_DIR}/ca
do_mkdir ${SIMPLECA_DIR}/ca/ca.db.certs
do_mkdir ${SIMPLECA_DIR}/web
do_mkdir ${SIMPLECA_DIR}/web/ca

if [ ! -f ${SIMPLECA_DIR}/ca/ca.key ] ; then
    echo "Generating private key"
    openssl genrsa -des3 -passout env:SIMPLECA_PASSWORD -out ${SIMPLECA_DIR}/ca/ca.key ${SIMPLECA_KEYSIZE}
fi

if [ ! -f ${SIMPLECA_DIR}/ca/ca.crt ] ; then
    echo "Generating root certificate"
    openssl req -x509 -new -nodes -key ${SIMPLECA_DIR}/ca/ca.key -passin env:SIMPLECA_PASSWORD -sha256 -subj "/C=${SIMPLECA_COUNTRYNAME}/ST=${SIMPLECA_STATE}/L=${SIMPLECA_LOCALITY}/O=${SIMPLECA_ORGANIZATION}/OU=${SIMPLECA_UNIT}/emailAddress=${SIMPLECA_EMAILADDRESS}" -days ${SIMPLECA_EXPIRATION} -out ${SIMPLECA_DIR}/ca/ca.crt -outform PEM
fi
cp ${SIMPLECA_DIR}/ca/ca.crt ${SIMPLECA_DIR}/web/ca/ca.crt
echo "Here is the Certificate Authority certificate"
cat ${SIMPLECA_DIR}/ca/ca.crt

if [ ! -f ${SIMPLECA_DIR}/ca/ca.db.index ]; then
    echo "Creating ${SIMPLECA_DIR}/ca/ca.db.index file"
    touch ${SIMPLECA_DIR}/ca/ca.db.index
fi

if [ ! -f ${SIMPLECA_DIR}/ca/ca.db.index.attr ]; then
    echo 'unique_subject = no' > ${SIMPLECA_DIR}/ca/ca.db.index.attr
fi

if [ ! -f ${SIMPLECA_DIR}/ca/ca.db.serial ]; then
    echo "Creating ${SIMPLECA_DIR}/ca/ca.db.serial file"
    cat /dev/urandom | tr -dc '0-9' | fold -w 4 | head -n 1 > ${SIMPLECA_DIR}/ca/ca.db.serial
fi

if [ ! -f ${SIMPLECA_DIR}/ca.conf ]; then
echo '[ ca ]
default_ca = ca_default
[ ca_default ]
dir = '${SIMPLECA_DIR}'/ca
certs = $dir
new_certs_dir = $dir/ca.db.certs
database = $dir/ca.db.index
serial = $dir/ca.db.serial
RANDFILE = $dir/ca.db.rand
certificate = $dir/ca.crt
private_key = $dir/ca.key
default_days = '${SIMPLECA_EXPIRATION}'
default_crl_days = 30
default_md = '${SIMPLECA_DEFAULTMD}'
preserve = no
policy = generic_policy
[ generic_policy ]
countryName = optional
stateOrProvinceName = optional
localityName = optional
organizationName = optional
organizationalUnitName = optional
commonName = optional
emailAddress = optional' > ${SIMPLECA_DIR}/ca.conf
fi

echo -n ${SIMPLECA_PASSWORD} > ${SIMPLECA_DIR}/ca/ca.passwd
unset SIMPLECA_PASSWORD

if [ $# -eq 0 ]; then
    /usr/local/bin/basicweb -port 80 -dir ${SIMPLECA_DIR}/web -cmd '/sign=/data/scripts/sign.sh'
else
    /usr/local/bin/basicweb -port 80 -dir ${SIMPLECA_DIR}/web -cmd '/sign=/data/scripts/sign.sh' &
    pid=$!
    "$@"
    kill $pid
fi

exit 0
