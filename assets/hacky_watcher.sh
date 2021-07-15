#!/usr/bin/env bash
while true
do
  cp -vur static/* ../priv/static/
  cp -vur js/ ../priv/static/
  cp -vur css/ ../priv/static/

  sleep 1
done