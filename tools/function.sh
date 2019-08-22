#!/bin/sh
   
# Author : 章云
# Date   : 2019/8/21 9:04

function wait(){
	i=$1
	while [[ 1 == 1 ]]
	do
		if [[ ${i} == 0 ]]
		then
			break;
		else
			echo "Please waiting ${i}s ...."
			let i-=1
			sleep 1s
		fi
	done
}

#IP字符串分割
arrays=()
function splitIp(){
	IFS=","
	arrayFirst=($1)
	index=0
	dot="."
	length=${#arrayFirst[*]}
	for((b=0;b<$length;b++))
	do
		range=${arrayFirst[b]}
		if [[ $range == *"-"* ]]
		then
			IFS="-"
			arraySecond=($range)
			if [[ ${#arraySecond[*]} == 2 ]]
			then
				IFS="."
				arrayOne=(${arraySecond[0]})
				arrayTwo=(${arraySecond[1]})
				sufMin=${arrayOne[3]}
				sufMax=${arrayTwo[3]}
				if(($sufMax>=$sufMin))
				then
					IFS=" "
					for((i=$sufMin;i<=$sufMax;i++))
					do
						ip="${arrayOne[0]}$dot${arrayOne[1]}$dot${arrayOne[2]}$dot$i";
						arrays[$index]=$ip
						index=$((index+1))
					done
				else
					IFS=" "
					for((i=$sufMax;i<=$sufMin;i++))
					do
						ip="${arrayOne[0]}$dot${arrayOne[1]}$dot${arrayOne[2]}$dot$i";
						arrays[$index]=$ip
						index=$((index+1))
					done
				fi
			fi
		else
			IFS=" "
			arrays[$index]=$range
			index=$((index+1))
		fi
	done
	if [ ${#arrays[*]} -eq 0 ]
	then
		echo "Read ip list exception！！！"
		exit 0
	fi
}
