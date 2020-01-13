# linux bash shell之awk

## awk命令工作原理

* 与sed一样, 均是一行一行的读取、处理
* sed作用于一整行的处理, 而awk将一行分成数个字段来处理

## awk的用-F来指定分隔符

* 默认的字段分隔符是任意空白字符(空格或者TAB)
* 举例对比cut和awk的区别

## awk的数据字段变量

* $0表示整行文本
* $1表示文本中第一个数据字段
* $2表示文本中第二个数据字段
* $n表示文本中第n个数据字段

## awk命令的基本语法

* awk -F 分隔符 ‘/模式/{动作}’ 输入文件

## 指令由模式和动作结合

* awk的指令一定要用单引号括起
* awk的动作一定要用花括号括起
* 模式可以是正则表达式、条件表达式或两种组合
* 如果模式是正则表达式要用/定界符
* 多个动作之间用;号分开

## awk基本命令示例
```
awk '/bash/' /etc/passwd
# 只有模式没有动作结果和grep一样，显示$0
who | awk '{print $2}'
# 只有动作没有模式就直接执行动作
awk -F: '/^h/{print $1,$7}' /etc/passwd
# print执行显示功能将文本输出到STDOUT
# 以冒号为分隔符，显示以h开头的行的第一列和第七列
awk -F: '/^[^h]/{print $1,$7}' /etc/passwd
# 不显示以h开头的行的第一列和第七列
awk -F '[:/]' '{print $1,$10}' /etc/passwd
# 以：或者/作为分隔符显示第1列和第10列
```

## awk命令的操作符

* 正则表达式和bash一致
* 数学运算：+，-，*，/， %，++，- -
* 逻辑关系符：&&， ||， !
* 比较操作符：>，<，>=，!=，<=，== ~ !~
* 文本数据表达式：== （精确匹配）
* ~波浪号表示匹配后面的模式
* who | awk '$2 ~ /pts/{print $1}‘
* awk -F: '$3 ~ /\<...\>/ {print $1,$3}' /etc/passwd
* seq 100 | awk '$1 % 5 == 0 || $1 ~ /^1/{print $1}'
* awk -F: '$1 == "root"{print $1,$3}' /etc/passwd

## awk基本命令示例

```
awk -F: '$3>=500{print $1}' /etc/passwd
# 显示UID大于等于500行的用户名
awk -F: '$3>=500 && $3<=60000{print $1}' /etc/passwd
# 显示UID大于等于500且小于等于60000行的用户名
awk -F: '$3 != $4 {print $1}' /etc/passwd
# 显示UID不等于GID的用户名
awk -F: '/^h/ && /bash/{print $1}' /etc/passwd
# 显示用户名以h开头的普通用户
ps aux | awk '$2 <=10 {print $11}'
awk 'BEGIN{print "line one\nline two\nline three"}'
# 显示后面三行
awk 'END{print "line one\nline two\nline three"}'
# 按ctrl+D开始显示后面三行
awk 'BEGIN{print "start..."}{print $1}END{print "end..."}' /etc/passwd
# 显示文件的内容并在前面加上start和后面加上end
awk 'BEGIN{i=0}{i++}END{print i}' /etc/passwd
# 显示文件的行数
```

## awk命令的内部变量

|名称|用途|
|---|---|
|NF|每行$0的字段数|
|NR|当前处理的行号|
|FS|当前的分隔符，默认是空白字符|
|OFS|当前的输出分隔符，默认是空白字符|

## awk基本命令示例

```
awk '{print NF}' /etc/grub.conf
# 显示每行的字段数目
awk '{print $1,$NF}' /etc/grub.conf
# 显示每行的第一字段 和最后一个字段
awk '{print NR,$0}' /etc/grub.conf
# 显示每行的内容和行号
awk -F: 'BEGIN{OFS="---"}{print $1,$7}' /etc/passwd
# 显示第一列和第七列，中间用---隔开
awk 'BEGIN{FS=":"}/bash$/{print NR,$1}END{print NR}' /etc/passwd
# 显示符合模式的用户名和所在的行号最后显示总行号
awk 'NR==3,NR==5' /etc/grub.conf
# 显示文件的3到5行
awk 'NR<=10' /etc/fstab
# 显示文件的前10行
```

## awk命令的引用shell变量

```
name=haha
echo|awk -v abc=$name '{print abc,$name}'
```

## awk命令的函数

```
awk -F: 'length($2)==1{print $1}' /etc/passwd /etc/shadow
# 利用length计算字符数目的函数来检查有无空口令用户
awk -F: 'length($0)>=30{print NR,$1}' /etc/passwd /etc/shadow
# 显示文件中超过60个字符的行
```

## awk命令的结构化语句

### 单分支

```
awk -F: '{if($1 ~ /\<...\>/)print $0}' /etc/passwd
awk -F: '{if($3 >= 500)print $1,$7}' /etc/passwd
```

### 双分支

```
awk -F: '{if($3 != 0) print $1 ; else print $3}' /etc/passwd
```

### 多分支

```
awk -F: '{if($1=="root") print $1; else if($1=="ftp") print $2; else if($1=="mail") print $3; else print NR}' /etc/passwd
```