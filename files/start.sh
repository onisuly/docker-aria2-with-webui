#!/bin/sh
set -e

PUID=${PUID:=0}
PGID=${PGID:=0}
SECURE=${SECURE:=false}
SEEDRATIO=${SEEDRATIO:=0}
SEEDTIME=${SEEDTIME:=0}
IPV6=${IPV6:=false}

conf=/conf/aria2.conf
if [ ! -f $conf ]; then
    cp /preset-conf/aria2.conf $conf
    chown $PUID:$PGID $conf

    if [ -z "$SECRET" ] && [ -n "$SECRET_FILE" ] && [ -r "$SECRET_FILE" ]; then
        echo "rpc-secret=$(cat "$SECRET_FILE")" >> $conf
    elif [ -n "$SECRET" ]; then
        echo "rpc-secret=$SECRET" >> $conf
    fi

    if [ "$SECURE" = "true" ]; then
        echo "" >> $conf
        echo "rpc-secure=true" >> $conf
        echo "rpc-certificate=$CERTIFICATE" >> $conf
        echo "rpc-private-key=$PRIVATEKEY" >> $conf
    fi

    if [ "$IPV6" = "true" ]; then
        sed -i "s@disable-ipv6.*@disable-ipv6=false@g" $conf
        ipv6="--ipv6"
    fi

    if  [ -n "$FILE_ALLOCATION" ]; then
        case "$FILE_ALLOCATION" in
            none|prealloc|trunc|falloc)
                echo "" >> $conf
                echo "file-allocation=$FILE_ALLOCATION" >> $conf            
            ;;
        esac
    fi
        
    echo "" >> $conf
    echo "seed-ratio=$SEEDRATIO" >> $conf
    echo "seed-time=$SEEDTIME" >> $conf
fi

chown $PUID:$PGID /conf || echo 'Failed to set owner of /conf, aria2 may not have permission to write /conf/aria2.session'

touch /conf/aria2.session
chown $PUID:$PGID /conf/aria2.session

touch /logs.log
chown $PUID:$PGID /logs.log

crond -l2 -b

( sleep 30 && run-parts /etc/periodic/daily ) &

s6-setuidgid $PUID:$PGID darkhttpd /aria2-ng --port 80 --daemon --no-listing --no-server-id $ipv6

exec s6-setuidgid $PUID:$PGID aria2c --conf-path=$conf --log=/logs.log
