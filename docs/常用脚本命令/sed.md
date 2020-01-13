# linux bash shell之sed

对文件的操作无非就是”增删改查“，怎样用sed命令实现对文件的”增删改查“，玩转sed是写自动化脚本必须的基础之一

## 命令(在不加参数的情况下，修改文件后的内容输出到控制台，实际并没有修改文件)

### a 新增

```
sed '2a key=value' sed.txt
# 在第2行后新增一行key=value，实际在第三行
sed '1,3a key=value' sed.txt
# 从第一行到第三行，每行后面新增一行key=value
```

### c 替换

```
sed '2c key=value' sed.txt
# 把第2行替换成key=value，实际在第二行
sed '1,3c key=value' sed.txt
# 从第一行到第三行替换成一行key=value
```

### d 替换

```
sed '2d' sed.txt
# 删除第二行
sed '1,3d' sed.txt
# 删除第一行到第三行
```

### i 插入

```
sed '2i key=value' sed.txt
# 在第2行前新增一行key=value，实际在第二行
sed '1,3i key=value' sed.txt
# 从第一行到第三行，每行前面新增一行key=value
```

### p 打印

```
sed '2p' sed.txt
# 重复打印第二行内容
sed '1,3p' sed.txt
# 重复打印第一行到第三行内容
sed -n '2p' sed.txt
# 只打印第二行内容
sed -n '1,3p' sed.txt
# 只打印第一行到第三行内容
```

### s 局部替换

```
sed 's/old/new/' sed.txt
# 每一行的'old'替换成'new'
sed 's/old/new/gi' sed.txt
# 每一行的'old'替换成'new'，g 代表一行多个，i 代表匹配忽略大小写
sed '1,3s/old/new/gi' sed.txt
# 只替换第一行到第三行
```

## 参数

### -e 可以指定多个命令

```
sed -e 's/old/new/gi' -e '2i key=value' sed.txt
```

### -f 多个命令写到文件中执行

```
sed -f command.txt sed.txt
```

### -n 取消默认控制台输出，与p一起使用可打印指定内容

```
sed -n 's/old/new/gip' sed.txt
# 打印修改过的行，必须加p命令，否则不打印
```

### -i 输出到原文件，静默执行（修改原文件的意思）

```
sed -i 's/old/new/gi' sed.txt
```

## 温馨提示

若不指定行号，则每一行都操作。

$代表最后一行，双引号内的$代表使用变量。