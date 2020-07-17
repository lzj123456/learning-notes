# 一、基本使用

1. 引入依赖

```xml
<dependency>
    <groupId>org.dromara</groupId>
    <artifactId>hmily-springcloud</artifactId>
    <version>2.0.5-RELEASE</version>
</dependency>
```

2. 配置hmily

```yaml
org:
    dromara:
         hmily :
            serializer : kryo
            recoverDelayTime : 128
            retryMax : 30
            scheduledDelay : 128
            scheduledThreadMax :  10
            repositorySupport : db
            started: false
            # 配置日志数据库信息，他会在数据库下自动创建每个微服务对应的事务日志表
            hmilyDbConfig :
                 driverClassName  : com.mysql.jdbc.Driver
                 url: jdbc:mysql://192.168.18.141:3306/tcc?useUnicode=true&characterEncoding=utf-8&serverTimezone=GMT&failOverReadOnly=false&autoReconnect=true
                 username : root
                 password : 521Baobei~!
```

3. 业务中使用hmily

```java
// 在需要添加事务的service方法中添加注解并为其配置confirem与cancel方法
// 如果try阶段代码执行失败就会执行cancel方法，成功执行confirem
// 下面是try阶段，资源预留方法
@Hmily(confirmMethod = "confirmOrderStatus", cancelMethod = "cancelOrderStatus")
public String mockPaymentInventoryWithTryException(Order order) {
    LOGGER.debug("===========执行springcloud  mockPaymentInventoryWithTryException 扣减资金接口==========");
    order.setStatus(OrderStatusEnum.PAYING.getCode());
    orderMapper.update(order);
    //扣除用户余额
    AccountDTO accountDTO = new AccountDTO();
    accountDTO.setAmount(order.getTotalAmount());
    accountDTO.setUserId(order.getUserId());
    // feign访问的接口如果也要加入到分布式事务中也要在service方法中添加@Hmily并指定confirem与cancel
    accountClient.payment(accountDTO);
    //扣除库存
    InventoryDTO inventoryDTO = new InventoryDTO();
    inventoryDTO.setCount(order.getCount());
    inventoryDTO.setProductId(order.getProductId());
    inventoryClient.mockWithTryException(inventoryDTO);
    return "success";
}
// 提交事务方法
public void confirmOrderStatus(Order order) {
    order.setStatus(OrderStatusEnum.PAY_SUCCESS.getCode());
    orderMapper.update(order);
    LOGGER.info("=========进行订单confirm操作完成================");
}
// 回滚方法
public void cancelOrderStatus(Order order) {
    order.setStatus(OrderStatusEnum.PAY_FAIL.getCode());
    orderMapper.update(order);
    LOGGER.info("=========进行订单cancel操作完成================");
}
```

在try阶段如果用到了feignClient，要在feignClient方法上也使用@Hmily注解

```java
@Hmily
@RequestMapping("/inventory-service/inventory/mockWithTryException")
Boolean mockWithTryException(@RequestBody InventoryDTO inventoryDTO);
```

官方demo地址https://dromara.org/zh-cn/docs/hmily/quick-start-springcloud.html