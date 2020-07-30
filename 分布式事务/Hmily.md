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

# 二、实现原理

1. 使用的Spring AOP来对每一个加了@Hmily注解的方法做切面拦截，在切面中会根据事务上下文来进行判断当前切入点的角色，大致分为事务的发起者和事务的参与者，不同的角色使用不同的事务执行器进行切入点的执行处理。
2. 事务发起者会也是真个分布式事务的协调者，他会在try阶段成功后调用所有事务参与者的confirm，失败则会调用所有参与者的cancel方法。

```java
// StarterHmilyTransactionHandler事务发起者的处理器，下面时核心处理方法源码
public Object handler(final ProceedingJoinPoint point, 
                      final HmilyTransactionContext context) throws Throwable {
    Object returnValue;
    try {
        HmilyTransaction hmilyTransaction = this.hmilyTransactionExecutor.preTry(point);

        try {
            // 执行try阶段的业务
            returnValue = point.proceed();
            hmilyTransaction.setStatus(HmilyActionEnum.TRYING.getCode());
            this.hmilyTransactionExecutor.updateStatus(hmilyTransaction);
        } catch (Throwable var10) {
            // 如果try阶段异常则执行所有事务参与者的cancel业务	
            HmilyTransaction currentTransaction = this.hmilyTransactionExecutor
                .getCurrentTransaction();
            this.disruptorProviderManage.getProvider().onData(() -> {
                this.hmilyTransactionExecutor.cancel(currentTransaction);
            });
            throw var10;
        }

        // 如果 try阶段成功则执行所有参与者的confirm方法
        HmilyTransaction currentTransaction = this.hmilyTransactionExecutor
            .getCurrentTransaction();
        this.disruptorProviderManage.getProvider().onData(() -> {
            this.hmilyTransactionExecutor.confirm(currentTransaction);
        });
    } finally {
        HmilyTransactionContextLocal.getInstance().remove();
        this.hmilyTransactionExecutor.remove();
    }

    return returnValue;
}
```

# 三、使用TCC对业务性能的影响

**影响性能的原因**：

1. TCC本身对事务中的每个操作 都做了AOP切面处理这一步肯定时对性能有影响的
2. 其次是协调者还需要去执行所有参与者的confirm或者cancel，这里也是对性能有影响的点

**解决方案**：

1. 由于Hmily的实现是基于事务的发起者作为整个分布式事务的协调者，事务发起者本身就是一个微服务，本身就是需要做集群的，我们只需要根据实际业务场景来添加实例数量就可以