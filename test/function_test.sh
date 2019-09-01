#!/usr/bin/env bash
    
# Author : 章云
# Date   : 2019/9/1 11:37

source ${LOCAL_PATH}/tools/function.sh
source ${LOCAL_PATH}/test/test.sh

echo "Test function.sh start ..."
echo ""

echo "Test function.sh wait start ..."
echo ""
echo "Test wait 3 seconds"
wait 3
testResult $? function.sh wait 3

echo "Test function.sh splitIp start ..."
echo ""
splitIp 192.168.1.1-192.168.1.10,192.168.1.15,192.168.1.22-192.168.1.25
test ${#arrays[*]} -eq 15
testResult $? function.sh splitIp 192.168.1.1-192.168.1.10,192.168.1.15,192.168.1.22-192.168.1.25
splitIp 192.168.1.1-192.168.1.10
test "${#arrays[5]}" = "192.168.1.5"
testResult $? function.sh splitIp 192.168.1.1-192.168.1.10

echo ""
echo "Test function.sh successful !!!"