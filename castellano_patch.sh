#!/bin/bash

# Color codes
NORMAL='\033[0;39m'
GREEN='\033[1;32m'
RED='\033[1;31m'
WHITE='\033[1;37m'
YELLOW='\033[1;33m'

WORKDIR=$(pwd)
FILENAME='com.freestylelibre.app.de_2019-04-22'

echo -e "${WHITE}Compruebe las herramientas que necesita ....${NORMAL}"
MISSINGTOOL=0
echo -en "${WHITE}  apksigner ... ${NORMAL}"
which apksigner > /dev/null
if [ $? = 0 ]; then
  echo -e "${GREEN}encontrado.${NORMAL}"
else
  echo -e "${RED}extraviado.${NORMAL}"
  MISSINGTOOL=1
fi
echo -en "${WHITE}  apktool ... ${NORMAL}"
if [ -x tools/apktool ]; then
  echo -e "${GREEN}encontrado.${NORMAL}"
  APKTOOL=$(pwd)/tools/apktool
else
  which apktool > /dev/null
  if [ $? = 0 ]; then
    echo -e "${GREEN}encontrado.${NORMAL} Sin embargo, se desconoce el origen y la compatibilidad.."
    APKTOOL=$(which apktool)
  else
    echo -e "${RED}extraviado.${NORMAL}"
    MISSINGTOOL=1
  fi
fi
echo -en "${WHITE}  git ... ${NORMAL}"
which git > /dev/null
if [ $? = 0 ]; then
  echo -e "${GREEN}encontrado.${NORMAL}"
else
  echo -e "${RED}extraviado.${NORMAL}"
  MISSINGTOOL=1
fi
echo -en "${WHITE}  keytool ... ${NORMAL}"
which keytool > /dev/null
if [ $? = 0 ]; then
  echo -e "${GREEN}encontrado.${NORMAL}"
else
  echo -e "${RED}extraviado.${NORMAL}"
  MISSINGTOOL=1
fi
echo -en "${WHITE}  zipalign ... ${NORMAL}"
which zipalign > /dev/null
if [ $? = 0 ]; then
  echo -e "${GREEN}encontrado.${NORMAL}"
else
  echo -e "${RED}extraviado.${NORMAL}"
  MISSINGTOOL=1
fi
echo
if [ ${MISSINGTOOL} = 1 ]; then
  echo -e "${YELLOW}=> Instale las herramientas que necesita.${NORMAL}"
  exit 1
fi

echo -e "${WHITE}Buscar archivo APK '${FILENAME}.apk' ...${NORMAL}"
if [ -e APK/${FILENAME}.apk ]; then
  echo -e "${GREEN}  encontrado.${NORMAL}"
  echo
else
  echo -e "${RED}  extraviado.${NORMAL}"
  echo
  echo -e "${YELLOW}=> Descargue el archivo APK original de https://www.apkmonk.com/download-app/com.freestylelibre.app.de/5_com.freestylelibre.app.de_2019-04-22.apk/ y ponerlo en el directorio APK/ ab.${NORMAL}"
  exit 1
fi

echo -e "${WHITE}Verifique la suma MD5 del archivo APK ...${NORMAL}"
md5sum -c APK/${FILENAME}.apk.md5 > /dev/null 2>&1
if [ $? = 0 ]; then
  echo -e "${GREEN}  Todo va bien.${NORMAL}"
  echo
else
  echo -e "${RED}  No va bien.${NORMAL}"
  echo
  echo -e "${YELLOW}=> Descargue el APK original correcto y sin adulterar.${NORMAL}"
  exit 1
fi

echo -e "${WHITE}Descomprime el archivo APK original ...${NORMAL}"
${APKTOOL} d -o /tmp/librelink APK/${FILENAME}.apk
if [ $? = 0 ]; then
  echo -e "${GREEN}  Todo va bien.${NORMAL}"
  echo
else
  echo -e "${RED}  No va bien.${NORMAL}"
  echo
  echo -e "${YELLOW}=> Marque como error.${NORMAL}"
  exit 1
fi

echo -e "${WHITE}Aplicación de parche original ...${NORMAL}"

cat <<EOF
¿Deben desactivarse las funciones en línea de la aplicación Librelink?

Con la funcionalidad en línea desactivada, la verificación de licencia y
Mensajería en la nube es desactivada en la aplicación.

Entonces ya no es necesario iniciar sesión en la aplicación con un nombre de usuario
y contraseña, y la aplicación ya no transferirá ningún dato al fabricante.


ATENCIÓN: Sin funciones en línea, NO se pueden enviar datos a LibreView !
          

Si está utilizando LibreView para generar informes
¡Deje las funciones online activadas! Además, solo se transfieren valores
que están disponibles en la propia aplicación, es decir, los que están a través de NFC
(escanear en el sensor). Para obtener un completo
Por lo tanto, debe  al menos una vez cada 8 horas.
escanear el sensor con el teléfono móvil a través de NFC.

EOF

patches=0001-Add-forwarding-of-Bluetooth-readings-to-other-apps.patch
while true ; do
    read -p "Desactivar funciones online? [S/n] " result
    case ${result} in
        S | s | Si | si | "" )
            patches+=" 0002-Disable-uplink-features.patch"
            appmode=Offline
            break;;
        n | N | no | No )
            appmode=Online
            break;;
        * )
            echo "${RED}Por favor responda con s o n !${NORMAL}";;
    esac
done

cd /tmp/librelink/
for patch in ${patches} ; do
    echo -e "${WHITE}Patch : ${patch}${NORMAL}"
    git apply --whitespace=nowarn --verbose "${WORKDIR}/${patch}"
    if [ $? = 0 ]; then
        echo -e "${GREEN}  Todo va bien.${NORMAL}"
        echo
    else
        echo -e "${RED}  No va bien.${NORMAL}"
        echo
        echo -e "${YELLOW}=> Marque como error.${NORMAL}"
        exit 1
    fi
done

echo -e "${WHITE}Use un nuevo código fuente para la aplicación parcheada ...${NORMAL}"
cp -Rv ${WORKDIR}/sources/* /tmp/librelink/smali_classes2/com/librelink/app/
if [ $? = 0 ]; then
  echo -e "${GREEN}  Todo va bien.${NORMAL}"
  echo
else
  echo -e "${RED}  No va bien.${NORMAL}"
  echo
  echo -e "${YELLOW}=> Marque como error.${NORMAL}"
  exit 1
fi
chmod 644 /tmp/librelink/smali_classes2/com/librelink/app/*.smali

echo -e "${WHITE}Utilice nuevos gráficos para la aplicación parcheada ...${NORMAL}"
cp -Rv ${WORKDIR}/graphics/* /tmp/librelink/
if [ $? = 0 ]; then
  echo -e "${GREEN}  Todo va bien.${NORMAL}"
  echo
else
  echo -e "${RED}  No va bien.${NORMAL}"
  echo
  echo -e "${YELLOW}=> Marque como error.${NORMAL}"
  exit 1
fi

echo -e "${WHITE}Copie el archivo APK original en la aplicación parcheada ...${NORMAL}"
cp ${WORKDIR}/APK/${FILENAME}.apk /tmp/librelink/assets/original.apk
if [ $? = 0 ]; then
  echo -e "${GREEN}  Todo va bien.${NORMAL}"
  echo
else
  echo -e "${RED}  No va bien.${NORMAL}"
  echo
  echo -e "${YELLOW}=> Marque como error.${NORMAL}"
  exit 1
fi

echo -e "${WHITE}Ensamblar la aplicación parcheada ...${NORMAL}"
${APKTOOL} b -o ${WORKDIR}/APK/librelink_unaligned.apk
if [ $? = 0 ]; then
  echo -e "${GREEN}  Todo va bien.${NORMAL}"
  echo
else
  echo -e "${RED}  No va bien.${NORMAL}"
  echo
  echo -e "${YELLOW}=> Marque como error.${NORMAL}"
  exit 1
fi

echo -e "${WHITE}Espacios /tmp/ en ...${NORMAL}"
cd ${WORKDIR}
rm -rf /tmp/librelink/
echo -e "${GREEN}  Todo va bien."
echo

echo -e "${WHITE}Optimizar la alineación del archivo APK parcheado...${NORMAL}"
zipalign -p 4 APK/librelink_unaligned.apk APK/${FILENAME}_patched.apk
if [ $? = 0 ]; then
  echo -e "${GREEN}  Todo va bien.${NORMAL}"
  echo
  rm APK/librelink_unaligned.apk
else
  echo -e "${RED}  No va bien.${NORMAL}"
  echo
  echo -e "${YELLOW}=> Marque como error.${NORMAL}"
  exit 1
fi

echo -e "${WHITE}Cree un almacén de claves para firmar el archivo APK parcheado ...${NORMAL}"
keytool -genkey -v -keystore /tmp/libre-keystore.p12 -storetype PKCS12 -alias "Libre Signer" -keyalg RSA -keysize 2048 --validity 10000 --storepass geheim --keypass geheim -dname "cn=Libre Signer, c=de"
if [ $? = 0 ]; then
  echo -e "${GREEN}  Todo va bien.${NORMAL}"
  echo
else
  echo -e "${RED}  No va bien.${NORMAL}"
  echo
  echo -e "${YELLOW}=> Marque como error.${NORMAL}"
  exit 1
fi

echo -e "${WHITE}Firmar el archivo APK parcheado ...${NORMAL}"
if [ -x /usr/lib/android-sdk/build-tools/debian/apksigner.jar ]; then
  java -jar /usr/lib/android-sdk/build-tools/debian/apksigner.jar sign --ks-pass pass:geheim --ks /tmp/libre-keystore.p12 APK/${FILENAME}_patched.apk
elif [ -x /usr/share/apksigner/apksigner.jar ]; then
  java -jar /usr/share/apksigner/apksigner.jar sign --ks-pass pass:geheim --ks /tmp/libre-keystore.p12 APK/${FILENAME}_patched.apk
else
  apksigner sign --ks-pass pass:geheim --ks /tmp/libre-keystore.p12 APK/${FILENAME}_patched.apk
fi
if [ $? = 0 ]; then
  echo -e "${GREEN}  Todo va bien.${NORMAL}"
  echo
  rm /tmp/libre-keystore.p12
else
  echo -e "${RED}  No va bien.${NORMAL}"
  echo
  echo -e "${YELLOW}=> Marque como error.${NORMAL}"
  exit 1
fi

if [ -d /mnt/c/ ]; then
  echo -e "${WHITE}Windows-System reconocido ...${NORMAL}"
  echo -e "${WHITE}Copiar APK ...${NORMAL}"
  mkdir -p /mnt/c/APK
  cp APK/${FILENAME}_patched.apk /mnt/c/APK/
  if [ $? = 0 ]; then
    echo -e "${GREEN}  Todo va bien.${NORMAL}"
    echo
  echo -en "${YELLOW}¡Terminado! El archivo APK parcheado y firmado se puede encontrar en C:\\APK"
  echo -en "\\"
  echo -e "${FILENAME}_patched.apk${NORMAL}"
  else
    echo -e "${RED}  No va bien.${NORMAL}"
    echo
    echo -e "${YELLOW}=> Marque como error.${NORMAL}"
    exit 1
  fi
else
  echo -e "${YELLOW}¡Terminado! El archivo APK parcheado y firmado se puede encontrar en APK/${FILENAME}_patched.apk${NORMAL}"
fi

echo -en "${GREEN}La aplicación parcheada se ejecuta en ${appmode}-modo"
if [[ ${appmode} == Online ]] ; then
  echo -e " (con soporte LibreView)${NORMAL}"
else
  echo -e " (sin soporte de LibreView)${NORMAL}"
fi
