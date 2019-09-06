# 一键部署大数据环境

## v1.0

### 准备环境

* 虚拟机需要设置：
    * 静态ip，包含DNS，网关等
    * hostname，域名，永久生效
    * hosts，域名和ip的映射关系
    * 关闭防火墙，selinux，networkManager，永久生效
    * 免秘钥，并且known_hosts验证通过
    * 其他设置，时区校准

### 已完成
* jdk单机版安装卸载，可增加或删除环境变量
* scala单机版安装卸载，可增加或删除环境变量
* mysql单机版安装卸载，可增加或删除环境变量，增加删除用户，修改root密码等
* hadoop单机版安装卸载，可增加或删除环境变量
* hive单机版安装卸载，可增加或删除环境变量，创建mysql数据库

### 待优化点   
 
* 可增加虚拟机设置的一键化操作
* 目前组件包是经过自己手动处理，暂不支持开源包
* 目前一键部署只支持单机版，不支持集群
* 支持安装java，scala，mysql，hadoop，hive，计划增加spark，hbase，phoenix，zookeeper，kafka，redis

## v1.1

* 由于大数据组件依赖关系，目前组件版本为
    * hadoop 2.6.1
    * hive 1.2.2
    * hbase 1.3.5
    * zookeeper 3.4.14
* 优化配置文件修改脚本，xml可增加配置项，创建空的配置文件
* 增加zookeeper一键部署，只支持单机版，支持开源包
* 增加redis一键部署，只支持单机版，支持开源包
* 支持hadoop2.x开源包
* 支持hive1.x开源包
* 增加hbase一键部署，只支持单机版，支持开源包(目前只测试1.3.5)