# linux bash shell之declare
**declare**或**typeset**内建命令(它们是完全相同的)可以用来限定变量的属性.这是在某些编程语言中使用的定义类型不严格的方式。命令declare是bash版本2之后才有的。命令typeset也可以在ksh脚本中运行。

## 参数

### -r 只读

    declare -r var1
    readonly var1
    # 作用相同，声明并设置变量只读，一个试图改变只读变量值的操作将会引起错误信息而失败
    
### -i 整数

    declare -i number
    # 脚本余下的部分会把"number"当作整数看待.
    number=3
    echo "Number = $number"     # Number = 3
    number=three
    echo "Number = $number"     # Number = 0
    # 脚本尝试把字符串"three"作为整数来求值(注：当然会失败，所以出现值为0).
    
    # 某些算术计算允许在被声明为整数的变量中完成，而不需要特别使用expr或let来完成。
    n=6/3
    echo "n = $n"       # n = 6/3
    declare -i n
    n=6/3
    echo "n = $n"       # n = 2

### -a 数组
    
    declare -a indices
    # 变量indices会被当作数组.
    
### -f 函数
    
    declare -f
    # 在脚本中没有带任何参数的declare -f 会列出所有在此脚本前面已定义的函数出来。
    declare -f function_name
    # 而declare -f function_name则只会列出指定的函数.
    
### -x export

    declare -x var3
    # 这样将声明一个变量作为脚本的环境变量而被导出。
    declare -x var3=373
    # declare命令允许在声明变量类型的时候同时给变量赋值。