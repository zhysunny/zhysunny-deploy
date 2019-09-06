#!/bin/sh
   
# Author      : 章云
# Date        : 2019/9/1 11:09
# Description : 针对xml配置文件的操作

Usage()
{
    echo "Usage: "
    echo "sh xml_config_tools.sh get <fileName> <propertyName>"
    echo "sh xml_config_tools.sh put <fileName> <propertyName> <propertyValue>"
    echo "sh xml_config_tools.sh createXmlFile <fileName>"
    exit 1
}

get(){
    if [[ $# -ne 2 ]]
    then
        Usage
        exit 1
    fi
    FILE_NAME=$1
    if [[ "${FILE_NAME}" != *".xml" ]]
    then
        echo "get指令只能获取xml配置文件的配置值"
        exit 1
    fi
    PROPERTY_NAME=$2
    declare -i NAME_LINE
    declare -i VALUE_LINE
    # 找到 $PROPERTY_NAME 对应的行号
	NAME_LINE=`grep -n "<name>${PROPERTY_NAME}</name>" ${FILE_NAME} | head -1 | cut -d ":" -f 1`
	# $PROPERTY_NAME 行号+1 为value的行号
	VALUE_LINE=`awk "BEGIN{a=${NAME_LINE};b="1";c=(a+b);print c}"`
    # 获取 value 标签的值
    sed -n "${VALUE_LINE}p" ${FILE_NAME} | sed 's/.*<.*>\([^<].*\)<.*>.*/\1/'
}

put(){
    if [[ $# -ne 3 ]]
    then
        Usage
        exit 1
    fi
    FILE_NAME=$1
    if [[ "${FILE_NAME}" != *".xml" ]]
    then
        echo "put指令只能修改xml配置文件的配置值"
        exit 1
    fi
    PROPERTY_NAME=$2
    PROPERTY_VALUE=$3
    declare -i NAME_LINE
    declare -i VALUE_LINE
    # 找到 $PROPERTY_NAME 对应的行号
	NAME_LINE=`grep -n "<name>${PROPERTY_NAME}</name>" ${FILE_NAME} | head -1 | cut -d ":" -f 1`
	# 如果不存在行号，增加一个配置项
	if [[ ${NAME_LINE} -eq 0 ]]
	then
        add ${FILE_NAME} ${PROPERTY_NAME} ${PROPERTY_VALUE}
    else
        # 如果存在行号，修改配置值
        # $PROPERTY_NAME 行号+1 为value的行号
        VALUE_LINE=`awk "BEGIN{a=${NAME_LINE};b="1";c=(a+b);print c}"`
        # 修改 value 标签的值
        PROPERTY_VALUE=`echo ${PROPERTY_VALUE} | sed 's#\/#\\\/#g'`
        sed -i "${VALUE_LINE}s/.*/\t<value>${PROPERTY_VALUE}<\/value>/g" ${FILE_NAME}
        echo "modify $FILE_NAME $PROPERTY_NAME=$PROPERTY_VALUE successful !!"
	fi
}

add(){
    # 防止添加相同配置项，这个命令不对外开放
    FILE_NAME=$1
    PROPERTY_NAME=$2
    PROPERTY_VALUE=$3
    declare -i ROOT_LINE
    declare -i VALUE_LINE
    # 找到 </configuration> 对应的行号,在前一行增加数据
	ROOT_LINE=`grep -n "^</configuration>" ${FILE_NAME} | head -1 | cut -d ":" -f 1`
    # 修改 value 标签的值
    PROPERTY_VALUE=`echo ${PROPERTY_VALUE} | sed 's#\/#\\\/#g'`
    sed -i "${ROOT_LINE}i\    <property>\n        <name>${PROPERTY_NAME}</name>\n        <value>${PROPERTY_VALUE}</value>\n    </property>" ${FILE_NAME}
    echo "add $FILE_NAME $PROPERTY_NAME=$PROPERTY_VALUE successful !!"
}

createXmlFile(){
    if [[ $# -ne 1 ]]
    then
        Usage
        exit 1
    fi
    FILE_NAME=$1
    if [[ -e ${FILE_NAME} ]]
    then
        echo "${FILE_NAME}文件已存在"
    else
        touch ${FILE_NAME}
        echo "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?>" > ${FILE_NAME}
        echo "<configuration>" >> ${FILE_NAME}
        echo "</configuration>" >> ${FILE_NAME}
    fi
}

COMMAND=$1
#参数位置左移1
shift

case ${COMMAND} in
    get )
        get $*
        ;;
    put )
        put $*
        ;;
    createXmlFile )
        createXmlFile $*
        ;;
    * )
		Usage
        exit 1
        ;;
esac

