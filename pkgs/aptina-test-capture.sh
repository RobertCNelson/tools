#!/bin/bash

echo "Aptina test capture using yavta/convert dumping image to /var/www"

sudo apt-get update
sudo apt-get -y install imagemagick

camera="mt9p031 2-0048"

sudo media-ctl -r -l '"${camera}":0->"OMAP3 ISP CCDC":0[1], "OMAP3 ISP CCDC":2->"OMAP3 ISP preview":0[1], "OMAP3 ISP preview":1->"OMAP3 ISP resizer":0[1], "OMAP3 ISP resizer":1->"OMAP3 ISP resizer output":0[1]'

sudo media-ctl -f '"${camera}":0 [SGRBG10 1280x1024], "OMAP3 ISP CCDC":2 [SGRBG10 1280x1024], "OMAP3 ISP preview":1 [UYVY 1280x1024], "OMAP3 ISP resizer":1 [UYVY 1024x768]'

if [ -f /var/www/img.uyvy ] ; then
	sudo rm -rf /var/www/img.uyvy || true
fi

if [ -f /var/www/img.jpg ] ; then
	sudo rm -rf /var/www/img.jpg || true
fi

sudo yavta -f UYVY -s 1024x768 --capture=1 --file=/var/www/img.uyvy /dev/video6
sudo convert -size 1024x768 /var/www/img.uyvy /var/www/img.jpg

