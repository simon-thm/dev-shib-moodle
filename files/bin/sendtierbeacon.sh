#!/bin/sh
LOGHOST="collector.testbed.internet2.edu"
LOGPORT="5000"
if [ -s /opt/tier/env.bash ]; then
  . /opt/tier/env.bash
fi
LOGTEXT="TIERBEACON/TIER/1.0#IM=$IMAGENAME#IV=$VERSION-$TIERVERSION#MT=$MAINTAINER#"
if [ -z "$TIER_BEACON_OPT_OUT" ]; then
  `logger -n $LOGHOST -P $LOGPORT -t TIERBEACON $LOGTEXT`
  echo `date`"; TIER beacon sent."
fi