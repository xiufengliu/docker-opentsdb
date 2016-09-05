#!/bin/bash

set -e

export TSD_CONF_tsd__http__cachedir=${TSD_CONF_tsd__http__cachedir:-/var/cache/opentsdb}
export TSD_CONF_tsd__http__staticroot=${TSD_CONF_tsd__http__staticroot:-/usr/share/opentsdb/static}

for VAR in $(env); do
    if [[ $VAR =~ ^TSD_CONF_ ]]; then
        tsd_conf_name=$(echo "$VAR" | sed -r 's/^TSD_CONF_([^=]*)=.*/\1/' | sed 's/__/./g' | tr '[:upper:]' '[:lower:]')
        tsd_conf_value=$(echo "$VAR" | sed -r "s/^[^=]*=(.*)/\1/")

        if grep "$tsd_conf_name" /etc/opentsdb/opentsdb.conf
        then
            # Replace conf value
            replaceString="/$tsd_conf_name/c\\$tsd_conf_name = $tsd_conf_value"
            sed -i "$replaceString" /etc/opentsdb/opentsdb.conf
        else
            # Add conf value
            echo "$tsd_conf_name = $tsd_conf_value" >> /etc/opentsdb/opentsdb.conf
        fi
        
    fi
done

mkdir -p "${TSD_CONF_tsd__http__cachedir}"

chown opentsdb "${TSD_CONF_tsd__http__cachedir}"
chown opentsdb /data/hbase

echo "Running supervisord"
exec supervisord -n -c /etc/supervisord.conf
