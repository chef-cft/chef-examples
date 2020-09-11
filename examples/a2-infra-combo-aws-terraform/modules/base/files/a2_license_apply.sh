#!/usr/bin/env bash
[ "`cat /tmp/a2_license`" != "none" ] && sudo chef-automate license apply /tmp/a2_license
