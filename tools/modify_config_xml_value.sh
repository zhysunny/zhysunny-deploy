#!/bin/sh
   
# Author : 章云
# Date   : 2019/8/21 8:53

Usage()
{
    echo "Usage: sh modify_config_xml_value.sh <filename> <propertyname> <valuename>"
    exit 1
}

if [ $# -ne 3 ]
then
    Usage
fi

FILE_NAME=$1
PROPERTY_NAME=$2
PROPERTY_VALUE=$3

declare -i Dline
getline()
{
    # 找到 $PROPERTY_NAME 对应的行号
	grep -n $PROPERTY_NAME $FILE_NAME | head -1 | cut -d ":" -f 1;
}


getlinenum()
{
    # $PROPERTY_NAME 行号+1 为value的行号
	awk "BEGIN{a=`getline`;b="1";c=(a+b);print c}";
}

Dline=`getlinenum`;
# 修改 value 标签的值
sed -i "${Dline}s/.*/\t<value>$PROPERTY_VALUE<\/value>/g" $FILE_NAME
echo "modify $FILE_NAME $PROPERTY_NAME=$PROPERTY_VALUE successful !!"

