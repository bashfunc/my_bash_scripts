#!/bin/bash

# generate a series of qr codes that fully encode a file
# workflow:
#
# create a temporary folder
#    compress
#    split
#    generate metadata
#    digest on all splits
#    generate the qr codes on all splits
#    copy the result to local dir
# destroy temporary folder
#
# 1st qr-code: metadata
#    - list of program versions used
#    - total number of data qr codes
#    - digest algorithm command
#    - compress algorithm command
#    - metadata
#    - user message
#
# following qr-codes: data segments
#
# output is 1 folder containing the "segment_0" (metadata) and
# the "segment_XX", containing the data.

# TODO: check that all needed packages are installed
# zbarimg --version
# qrencode
# gzip
# 

echo "start qr-code archiving..."

##############################################
# a bit of input sanitation                  #
##############################################

if [ $# -eq 0 ]; then
    echo "No arguments provided; -h for help"
    exit 1
fi

if [ "$1" == "-h" ]; then
  echo "A bash script to generate a series of qr-codes"
  echo "to archive a file."
  echo "use: qrarchive file_name"
  echo "ex : qrarchive my_file.txt"
  exit 0
fi

FILE_NAME=$1
echo "qr-code archiving of ${FILE_NAME}"

if [ ! -f ${FILE_NAME} ]; then
    echo "File not found! Aborting..."
    exit 1
fi

##############################################
# some general parameters                    #
##############################################

# the digest function to use
# this is not for cryptographic reasons,
# only as a strong proof that the data
# was well decrypted
digest_function(){
    sha1sum $1 | awk '{print $1;}' | xxd -r -ps
    # it is not necessary to remove the EOR 
    # sha1sum $1 | awk '{print $1;}' | head -c-1 | xxd -r -ps
}

SIZE_DIGEST=$(echo "anything" | digest_function | wc -c)

echo "using a SIZE_DIGEST of ${SIZE_DIGEST}"

# TODO: decide this so that use a 'good' size of individual qr codes
# the max information content of a qr-code depending
# of its size is given by the 'version table'.
# see for example: https://web.archive.org/web/20160326120122/http://blog.qr4.nl/page/QR-Code-Data-Capacity.aspx
# be a bit conservative about qr code size
# to be nice to possible bad printers
CONTENT_QR_CODE_BYTES=$((403-20-2-8))

echo "data content per qr code (bytes)"
echo "${CONTENT_QR_CODE_BYTES}"

# TODO: some print of the content per qr code

# TODO: some verbose control

# TODO: some choices of metadata

# TODO: some checks of 'well encoded data'

# TODO: some decoding function

# TODO: what this package is doing / not doing
# help in splitting / putting together
# no encryption or malicious user

# generate a random signature ID for the package
SIZE_ID=8
ID=$(dd if=/dev/urandom bs=${SIZE_ID} count=1)
echo "random ID:"
echo -n ${ID} | xxd

# TODO: function to organize the scanned QR codes
# for printing

# TODO function for ordering the collected QR codes

# TODO: app for scanning on the phone or from
# paper

# TODO: function for putting on paper
# first page: 'title, metadata, etc'
# following: data
# use A4 format
# typically 1mm minimum per mini block

# TODO: first page metadata: include how things
# organized on paper sheets when printing (so
# that more easy to decrypt).

##############################################
# ready to do the heavy work                 #
##############################################

# create temporary folder
TMP_DIR=$(mktemp -d)
echo "created working tmp: ${TMP_DIR}"

# compress the destination file
# display information, use maximum compression
echo "compressing file..."
touch ${TMP_DIR}/compressed
gzip -vc9 ${FILE_NAME} > ${TMP_DIR}/compressed

echo "information about compressed binary file:"
ls -lrth ${TMP_DIR}/compressed

# split the compressed file
# into segments to be used for qr-codes.
echo "split the compressed file into segments"
split -d -a 2 -b ${CONTENT_QR_CODE_BYTES} ${TMP_DIR}/compressed ${TMP_DIR}/data-

NBR_DATA_SEGMENTS=$(find ${TMP_DIR} -name 'data-*' | wc -l)
echo "split into ${NBR_DATA_SEGMENTS} segments"

# append for each data segment its digest
# the ID, and current segment number
COUNTER=0

for CRRT_FILE in ${TMP_DIR}/data-??; do
    echo "append digest ID to ${CRRT_FILE}"

    digest_function ${CRRT_FILE} >> ${CRRT_FILE}

    echo -n "${ID}" >> ${CRRT_FILE}

    # NOTE: this limits the max number of segments to 2^16-1 as
    # we are using 2 bytes for encoding
    printf "0: %.4x" $COUNTER | xxd -r -g0 >> ${CRRT_FILE}
    COUNTER=$((COUNTER+1))
done

# generate the data segments qr codes
for CRRT_FILE in ${TMP_DIR}/data-??; do
    echo "generate the qr-code for ${CRRT_FILE}"

    # use highest error correction level
    # TODO: adjust parameters to get nice sharp qr codes to print on A4
    cat ${CRRT_FILE} | qrencode -l H -8 -o ${CRRT_FILE}.png
done


# generate the qr code with the metadata
echo "create meteadata"

CRRT_FILE=${TMP_DIR}/metadata
echo -n "QRD:" >> ${CRRT_FILE}
echo "${FILE_NAME}" >> ${CRRT_FILE}

echo -n "NSEG:" >> ${CRRT_FILE}
echo "${NBR_DATA_SEGMENTS}" >> ${CRRT_FILE}

echo -n "DATE:" >> ${CRRT_FILE}
echo "$(date '+%Y-%m-%d,%H:%M:%S')" >> ${CRRT_FILE}

echo -n "ID:" >> ${CRRT_FILE}
echo "${ID}" >> ${CRRT_FILE}

echo -n "vGZIP:" >> ${CRRT_FILE}
echo "$(gzip --version | head -1 | awk '{print $2}')" >> ${CRRT_FILE}

echo -n "vQRENCODE:" >> ${CRRT_FILE}
echo "$(qrencode --version 2>&1 | head -1 |  awk '{print $3}')" >> ${CRRT_FILE}

echo -n "SYS:" >> ${CRRT_FILE}
echo "$(lsb_release -d | cut -f 2- -d$'\t' | sed 's/ //g')" >> ${CRRT_FILE}

echo "generate metadata qr code"


# check that able to decode all and agree with the input data


# move all the qr codes to a new folder
# at the current location

# delete temporary folder
#rm -r $TMP_DIR
echo "removed working tmp: ${TMP_DIR}"

echo "done"




















