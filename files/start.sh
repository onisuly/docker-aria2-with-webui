#!/bin/sh
set -e

PUID=${PUID:=0}
PGID=${PGID:=0}
SECURE=${SECURE:=false}
SEEDRATIO=${SEEDRATIO:=0}
SEEDTIME=${SEEDTIME:=0}
IPV6=${IPV6:=false}

if [ ! -f /conf/aria2.conf ]; then
    cp /preset-conf/aria2.conf /conf/aria2.conf
    chown $PUID:$PGID /conf/aria2.conf

    if [ -z "$SECRET" ] && [ -n "$SECRET_FILE" ] && [ -r "$SECRET_FILE" ]; then
        echo "rpc-secret=$(cat "${SECRET_FILE}")" >> /conf/aria2.conf
    elif [ -n "$SECRET" ]; then
        echo "rpc-secret=${SECRET}" >> /conf/aria2.conf
    fi

    if [ $SECURE = 'true' ]; then
        echo "" >> /conf/aria2.conf
        echo "rpc-secure=true" >> /conf/aria2.conf
        echo "rpc-certificate=$CERTIFICATE" >> /conf/aria2.conf
        echo "rpc-private-key=$PRIVATEKEY" >> /conf/aria2.conf
    fi

    if [ "$IPV6" = "true" ]; then
        sed -i "s@disable-ipv6.*@disable-ipv6=false@g" /conf/aria2.conf
        ipv6="--ipv6"
    fi

    if  [ -n "$FILE_ALLOCATION" ]; then
        case "$FILE_ALLOCATION" in
            none|prealloc|trunc|falloc)
                echo "" >> /conf/aria2.conf
                echo "file-allocation=$FILE_ALLOCATION" >> /conf/aria2.conf            
            ;;
        esac
    fi
        
    echo "" >> /conf/aria2.conf
    echo "seed-ratio=$SEEDRATIO" >> /conf/aria2.conf
    echo "seed-time=$SEEDTIME" >> /conf/aria2.conf
fi

list=`wget -qO- https://raw.githubusercontent.com/ngosang/trackerslist/master/trackers_best.txt|awk NF|sed ":a;N;s/\n/,/g;ta"`
if [ -z "`grep "bt-tracker" /conf/aria2.conf`" ]; then
    echo "bt-tracker=$list" >> /conf/aria2.conf
else
    sed -i "s@bt-tracker.*@bt-tracker=$list@g" /conf/aria2.conf
fi

chown $PUID:$PGID /conf || echo 'Failed to set owner of /conf, aria2 may not have permission to write /conf/aria2.session'

touch /conf/aria2.session
chown $PUID:$PGID /conf/aria2.session

touch /logs.log
chown $PUID:$PGID /logs.log

s6-setuidgid $PUID:$PGID darkhttpd /aria2-ng --port 80 --daemon --no-listing --no-server-id $ipv6

exec s6-setuidgid $PUID:$PGID aria2c --conf-path=/conf/aria2.conf --log=/logs.log
