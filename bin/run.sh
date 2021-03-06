#!/bin/sh

#Move to the folder where ep-lite is installed
cd `dirname $0`

#Was this script started in the bin folder? if yes move out
if [ -d "../bin" ]; then
  cd "../"
fi

ignoreRoot=0
for ARG in $*
do
  if [ "$ARG" = "--root" ]; then
    ignoreRoot=1
  fi
done

#Stop the script if its started as root
if [ "$(id -u)" -eq 0 ] && [ $ignoreRoot -eq 0 ]; then
   echo "You shouldn't start Etherpad as root!"
   echo "Please type 'Etherpad rocks my socks' or supply the '--root' argument if you still want to start it as root"
   read rocks
   if [ ! "$rocks" == "Etherpad rocks my socks" ]
   then
     echo "Your input was incorrect"
     exit 1
   fi
fi

#prepare the enviroment
#bin/installDeps.sh $* || exit 1

# Clear the cache directory so that we can refill it if running outside Sandstorm.
if [ "${SANDSTORM:-no}" = no ]; then
  mkdir -p cache
  # Load .capnp files from sandstorm installation. (In the Sandstorm sandbox, these are mapped
  # to /usr/include.)
  export NODE_PATH="/opt/sandstorm/latest/usr/include"
elif [ ! -e cache ]; then
  echo "ERROR: Must run once outside Sandstorm to populate minification cache" >&2
  exit 1
fi

#Move to the node folder and start
SCRIPTPATH=`pwd -P`

if [ -e var/dirty.db ]; then
  # Upgrade dirty.db to sqlite.
  echo "Upgrading from dirty.db to sqlite..."
  node $SCRIPTPATH/node_modules/ep_etherpad-lite/sandstorm-migrate.js || exit 1
  gzip -c var/dirty.db > var/dirty-backup.db.gz || exit 1
  rm -f var/dirty.db
  rm -f var/minified_*  # Delete garbage we used to litter here.
fi

echo "Started Etherpad..."

exec node "$SCRIPTPATH/node_modules/ep_etherpad-lite/node/server.js" $*
