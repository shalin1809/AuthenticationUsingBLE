#!/bin/sh

# THIS FILE IS GENERATED BY APPBUILDER, DO NOT MODIFY
# CONFIGURE VIA ENV VARS

# use PATH_GCCARM env var to override default path for gcc-arm
if [[ -z ${PATH_GCCARM} ]]; then
  OBJCOPY="C:\SiliconLabs\SimplicityStudio\v4\developer\toolchains\gnu_arm\4.9_2015q3/bin/arm-none-eabi-objcopy"
  if [[ `uname` == CYGWIN* ]]; then OBJCOPY="`cygpath ${OBJCOPY}`"; fi
else
  OBJCOPY="${PATH_GCCARM}/bin/arm-none-eabi-objcopy"
fi

# use PATH_SCMD env var to override default path for Simplicity Commander
if [[ -z ${PATH_SCMD} ]]; then
  COMMANDER="C:\SiliconLabs\SimplicityStudio\v4\developer\adapter_packs\commander\commander.exe"
  if [[ `uname` == CYGWIN* ]]; then COMMANDER="`cygpath ${COMMANDER}`"; fi
else
  COMMANDER="${PATH_SCMD}/commander"
fi

# use PATH_OUT env var to override the full path for the .out file

# default file extension of GCC and IAR
FILE_EXTENSION_GCC="*.axf"
FILE_EXTENSION_IAR="*.out"

# output path of the OTA and UART DFU ebl and gbl files (relative to project root)
PATH_EBL="output_ebl"
PATH_GBL="output_gbl"

# names of the OTA and UART DFU output files
OTA_STACK_NAME="stack"
OTA_APP_NAME="app"
UARTDFU_FULL_NAME="full"

# names of the sign and encypt key files
GBL_SIGING_KEY_FILE="app-sign-key.pem"
GBL_ENCRYPT_KEY_FILE="app-encrypt-key.txt"

# change the working dir to the dir of the batch file, which should be in the project root
cd "${0%/*}"

PATH_OUT=`find . -type f \( -iname ${FILE_EXTENSION_GCC} -or -iname ${FILE_EXTENSION_IAR} \) -exec echo {} \;`

if [[ -z ${PATH_OUT} ]]; then
  echo "Error: neither ${FILE_EXTENSION_GCC} nor ${FILE_EXTENSION_IAR} found"
  echo "Was the project compiled and linked successfully?"
  read -rsp $'Press enter to continue...\n'
  exit
fi

if [[ ! -f "${OBJCOPY}" ]]; then
  echo "Error: gcc-arm objcopy not found at '${OBJCOPY}'"
  echo "Use PATH_GCCARM env var to override default path for gcc-arm."
  read -rsp $'Press enter to continue...\n'
  exit
fi

if [[ ! -f "${COMMANDER}" ]]; then
  echo "Error: Simplicity Commander not found at '${COMMANDER}'"
  echo "Use PATH_SCMD env var to override default path for Simplicity Commander."
  read -rsp $'Press enter to continue...\n'
  exit
fi

echo "**********************************************************************"
echo "Converting .out to .ebl files"
echo "**********************************************************************"
echo
echo ".out file used:"
echo "${PATH_OUT}"
echo
echo "output folders:"
echo "${0%/*}${PATH_EBL}"
echo "${0%/*}${PATH_GBL}"

mkdir -p ${PATH_EBL}
mkdir -p ${PATH_GBL}

# create the EBL & GBL files
echo
echo "**********************************************************************"
echo "Creating ${OTA_STACK_NAME}.ebl and ${OTA_STACK_NAME}.gbl for OTA"
echo "**********************************************************************"
echo
"${OBJCOPY}" -O srec -j .text_stack* "${PATH_OUT}" "${PATH_EBL}/${OTA_STACK_NAME}.srec"
if [ $? -ne 0 ]; then
  read -rsp $'Press enter to continue...\n'
  exit
fi
"${COMMANDER}" ebl create "${PATH_EBL}/${OTA_STACK_NAME}.ebl" --app "${PATH_EBL}/${OTA_STACK_NAME}.srec" -d EFR32F256
"${COMMANDER}" gbl create "${PATH_GBL}/${OTA_STACK_NAME}.gbl" --app "${PATH_EBL}/${OTA_STACK_NAME}.srec"

echo 
echo "**********************************************************************"
echo "Creating ${OTA_APP_NAME}.ebl and ${OTA_APP_NAME}.gbl for OTA"
echo "**********************************************************************"
echo
"${OBJCOPY}" -O srec -j .text_app* "${PATH_OUT}" "${PATH_EBL}/${OTA_APP_NAME}.srec"
if [ $? -ne 0 ]; then
  read -rsp $'Press enter to continue...\n'
  exit
fi
"${COMMANDER}" ebl create "${PATH_EBL}/${OTA_APP_NAME}.ebl" --app "${PATH_EBL}/${OTA_APP_NAME}.srec" -d EFR32F256
"${COMMANDER}" gbl create "${PATH_GBL}/${OTA_APP_NAME}.gbl" --app "${PATH_EBL}/${OTA_APP_NAME}.srec"

# create the full EBL & GBL files for UART DFU
echo
echo "**********************************************************************"
echo "Creating ${UARTDFU_FULL_NAME}.ebl and ${UARTDFU_FULL_NAME}.gbl for UART DFU"
echo "**********************************************************************"
echo
"${OBJCOPY}" -O srec -R .text_bootloader* "${PATH_OUT}" "${PATH_EBL}/${UARTDFU_FULL_NAME}.srec"
if [ $? -ne 0 ]; then
  read -rsp $'Press enter to continue...\n'
  exit
fi
"${COMMANDER}" ebl create "${PATH_EBL}/${UARTDFU_FULL_NAME}.ebl" --app "${PATH_EBL}/${UARTDFU_FULL_NAME}.srec" -d EFR32F256
"${COMMANDER}" gbl create "${PATH_GBL}/${UARTDFU_FULL_NAME}.gbl" --app "${PATH_EBL}/${UARTDFU_FULL_NAME}.srec"

# create encrypted GBL file for secure boot if encrypt-key file exist
if [[ -f $GBL_ENCRYPT_KEY_FILE ]]; then
  echo
  echo "**********************************************************************"
  echo "Creating encrypted .gbl files"
  echo "**********************************************************************"
  echo
  "${COMMANDER}" gbl create "${PATH_GBL}/${OTA_STACK_NAME}-encrypted.gbl" --app "${PATH_EBL}/${OTA_STACK_NAME}.srec" --encrypt ${GBL_ENCRYPT_KEY_FILE}
  echo
  "${COMMANDER}" gbl create "${PATH_GBL}/${OTA_APP_NAME}-encrypted.gbl" --app "${PATH_EBL}/${OTA_APP_NAME}.srec" --encrypt ${GBL_ENCRYPT_KEY_FILE}
  echo
  "${COMMANDER}" gbl create "${PATH_GBL}/${UARTDFU_FULL_NAME}-encrypted.gbl" --app "${PATH_EBL}/${UARTDFU_FULL_NAME}.srec" --encrypt ${GBL_ENCRYPT_KEY_FILE}
fi

# create signed GBL file for secure boot if sign-key file exists
if [[ -f $GBL_SIGING_KEY_FILE ]]; then
  echo
  echo "**********************************************************************"
  echo "Creating signed .gbl files"
  echo "**********************************************************************"
  echo
  "${COMMANDER}" gbl create "${PATH_GBL}/${OTA_STACK_NAME}-signed.gbl" --app "${PATH_EBL}/${OTA_STACK_NAME}.srec" --signgbl --secureboot --signingkey ${GBL_SIGING_KEY_FILE}
  echo
  "${COMMANDER}" gbl create "${PATH_GBL}/${OTA_APP_NAME}-signed.gbl" --app "${PATH_EBL}/${OTA_APP_NAME}.srec" --signgbl --secureboot --signingkey ${GBL_SIGING_KEY_FILE}
  echo
  "${COMMANDER}" gbl create "${PATH_GBL}/${UARTDFU_FULL_NAME}-signed.gbl" --app "${PATH_EBL}/${UARTDFU_FULL_NAME}.srec" --signgbl --secureboot --signingkey ${GBL_SIGING_KEY_FILE}
  
  # create signed and encrypted GBL file for if both sign-key and encrypt-key file exist
  if [[ -f $GBL_ENCRYPT_KEY_FILE ]]; then
    echo
    echo "**********************************************************************"
    echo "Creating signed and encrypted .gbl files"
    echo "**********************************************************************"
    echo
    "${COMMANDER}" gbl create "${PATH_GBL}/${OTA_STACK_NAME}-signed-encrypted.gbl" --app "${PATH_EBL}/${OTA_STACK_NAME}.srec" --encrypt ${GBL_ENCRYPT_KEY_FILE} --signgbl --secureboot --signingkey ${GBL_SIGING_KEY_FILE}
    echo
    "${COMMANDER}" gbl create "${PATH_GBL}/${OTA_APP_NAME}-signed-encrypted.gbl" --app "${PATH_EBL}/${OTA_APP_NAME}.srec" --encrypt ${GBL_ENCRYPT_KEY_FILE} --signgbl --secureboot --signingkey ${GBL_SIGING_KEY_FILE}
    echo
    "${COMMANDER}" gbl create "${PATH_GBL}/${UARTDFU_FULL_NAME}-signed-encrypted.gbl" --app "${PATH_EBL}/${UARTDFU_FULL_NAME}.srec" --encrypt ${GBL_ENCRYPT_KEY_FILE} --signgbl --secureboot --signingkey ${GBL_SIGING_KEY_FILE}
  fi
fi

# clean up output dir
rm "${PATH_EBL}"/*.srec

read -rsp $'Press enter to continue...\n'