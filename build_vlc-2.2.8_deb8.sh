#!/bin/bash

# Setting up the environment on Debian 8:
# apt update
# apt -y install apt-src patchelf wget
# apt-src update
# apt-src install vlc
# rm -rf vlc-2* vlc_2*
# apt-get -y purge libvlc* vlc*
# rm -rf build src
# mkdir build src
# wget https://download.videolan.org/vlc/2.2.8/vlc-2.2.8.tar.xz -O ./src/vlc-2.2.8.tar.xz

LOCAL_ARCH=`uname -m`

if [ "$LOCAL_ARCH" != "x86_64" ]
then
    LOCAL_ARCH="i386"
fi

cat <<EOF >./build/vlc.desktop
[Desktop Entry]
Version=1.0
Name=VLC media player
GenericName=Media player
Comment=Read, capture, broadcast your multimedia streams
Exec=vlc --started-from-file %U
Icon=vlc
Terminal=false
Type=Application
Categories=AudioVideo;Player;Recorder;
MimeType=application/ogg;application/x-ogg;audio/ogg;audio/vorbis;audio/x-vorbis;audio/x-vorbis+ogg;video/ogg;video/x-ogm;video/x-ogm+ogg;video/x-theora+ogg;video/x-theora;audio/x-speex;audio/opus;application/x-flac;audio/flac;audio/x-flac;audio/x-ms-asf;audio/x-ms-asx;audio/x-ms-wax;audio/x-ms-wma;video/x-ms-asf;video/x-ms-asf-plugin;video/x-ms-asx;video/x-ms-wm;video/x-ms-wmv;video/x-ms-wmx;video/x-ms-wvx;video/x-msvideo;audio/x-pn-windows-acm;video/divx;video/msvideo;video/vnd.divx;video/avi;video/x-avi;application/vnd.rn-realmedia;application/vnd.rn-realmedia-vbr;audio/vnd.rn-realaudio;audio/x-pn-realaudio;audio/x-pn-realaudio-plugin;audio/x-real-audio;audio/x-realaudio;video/vnd.rn-realvideo;audio/mpeg;audio/mpg;audio/mp1;audio/mp2;audio/mp3;audio/x-mp1;audio/x-mp2;audio/x-mp3;audio/x-mpeg;audio/x-mpg;video/mp2t;video/mpeg;video/mpeg-system;video/x-mpeg;video/x-mpeg2;video/x-mpeg-system;application/mpeg4-iod;application/mpeg4-muxcodetable;application/x-extension-m4a;application/x-extension-mp4;audio/aac;audio/m4a;audio/mp4;audio/x-m4a;audio/x-aac;video/mp4;video/mp4v-es;video/x-m4v;application/x-quicktime-media-link;application/x-quicktimeplayer;video/quicktime;application/x-matroska;audio/x-matroska;video/x-matroska;video/webm;audio/webm;audio/3gpp;audio/3gpp2;audio/AMR;audio/AMR-WB;video/3gp;video/3gpp;video/3gpp2;x-scheme-handler/mms;x-scheme-handler/mmsh;x-scheme-handler/rtsp;x-scheme-handler/rtp;x-scheme-handler/rtmp;x-scheme-handler/icy;x-scheme-handler/icyx;application/x-cd-image;x-content/video-vcd;x-content/video-svcd;x-content/video-dvd;x-content/audio-cdda;x-content/audio-player;application/ram;application/xspf+xml;audio/mpegurl;audio/x-mpegurl;audio/scpls;audio/x-scpls;text/google-video-pointer;text/x-google-video-pointer;video/vnd.mpegurl;application/vnd.apple.mpegurl;application/vnd.ms-asf;application/vnd.ms-wpl;application/sdp;audio/dv;video/dv;audio/x-aiff;audio/x-pn-aiff;video/x-anim;video/x-nsv;video/fli;video/flv;video/x-flc;video/x-fli;video/x-flv;audio/wav;audio/x-pn-au;audio/x-pn-wav;audio/x-wav;audio/x-adpcm;audio/ac3;audio/eac3;audio/vnd.dts;audio/vnd.dts.hd;audio/vnd.dolby.heaac.1;audio/vnd.dolby.heaac.2;audio/vnd.dolby.mlp;audio/basic;audio/midi;audio/x-ape;audio/x-gsm;audio/x-musepack;audio/x-tta;audio/x-wavpack;audio/x-shorten;application/x-shockwave-flash;application/x-flash-video;misc/ultravox;image/vnd.rn-realpix;audio/x-it;audio/x-mod;audio/x-s3m;audio/x-xm;application/mxf;
EOF

rm -rf ./src/vlc-2.2.8
rm -rf ./build/usr

cd ./src
tar -xJf vlc-2.2.8.tar.xz
patch -p0 < ../0001-vlc-2.2.8-fix-includes.patch
patch -p0 < ../0002-vlc-2.2.8-update-playlist.patch
cd vlc-2.2.8
./configure --prefix=/usr --enable-run-as-root
make -j$(nproc)
make install
ldconfig
make install DESTDIR=$(pwd)/../../build/
cd $(pwd)/../../build
cp ./usr/share/icons/hicolor/256x256/apps/vlc.png .
rm ./usr/lib/vlc/plugins/plugins.dat
./usr/lib/vlc/vlc-cache-gen ./usr/lib/vlc/plugins/

cp /usr/lib/$LOCAL_ARCH-linux-gnu/libjack.so.0.0.28 ./usr/lib/
mv ./usr/lib/libjack.so.0.0.28 ./usr/lib/libjack.so.0

rm -rf ./usr/include
rm -rf ./usr/share/doc
rm -rf ./usr/share/man
find ./usr/lib/ -name "*.a" -exec rm {} \;
find ./usr/lib/ -name "*.la" -exec rm {} \;
find ./usr/lib/vlc/ -maxdepth 1 -name "lib*.so*" -exec patchelf --set-rpath '$ORIGIN/../' {} \;
find ./usr/lib/vlc/plugins/ -name "lib*.so*" -exec patchelf --set-rpath '$ORIGIN/../../:$ORIGIN/../../../' {} \;

find . -type d -exec chmod 0755 {} \;
find . -type f -exec chmod 0644 {} \;
chmod 0755 ./usr/bin/vlc
cd ..

VERSION="2.2.8" ./linuxdeployqt-6-$LOCAL_ARCH.AppImage ./build/vlc.desktop -appimage
