#!/bin/bash
exec 1> >(logger -s -t $(basename $0)) 2>&1
sudo wget https://raw.githubusercontent.com/Microsoft/OMS-Agent-for-Linux/master/installer/scripts/onboard_agent.sh && sh onboard_agent.sh --purge
