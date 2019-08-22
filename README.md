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
    
### 待优化点    
* 可增加虚拟机设置的一键化操作
* 目前组件包是经过自己手动处理，暂不支持开源包
* 目前一键部署只支持单机版，不支持集群
* 支持安装java，scala，mysql，hadoop，hive，计划增加spark，hbase，phoenix，zookeeper，kafka，redis
