# 一、介绍

swagger是一种文档生成工具，可以根据代码写的接口注解生成接口文档。

#  二、使用

1.导入依赖

```XML
<dependency>
    <groupId>io.springfox</groupId>
    <artifactId>springfox-swagger2</artifactId>
    <version>2.9.2</version>
</dependency>
<!--springfox-swagger-ui官方提供的一个ui库，这两个ui库选择其中一个就可以-->
<dependency>
    <groupId>io.springfox</groupId>
    <artifactId>springfox-swagger-ui</artifactId>
    <version>2.9.2</version>
</dependency>
<!--swagger-bootstrap-ui是国内开发的一个swaggerUI,样式是bootstrap风格的-->
<dependency>
    <groupId>com.github.xiaoymin</groupId>
    <artifactId>swagger-bootstrap-ui</artifactId>
    <version>1.9.6</version>
</dependency>
```

2.配置swagger

```java
@EnableSwagger2
@Configuration
public class WebConfig {

    @Bean
    public Docket createRestApi() {
        return new Docket(DocumentationType.SWAGGER_2)
                .apiInfo(getApiInfo()) //生成API基本信息
                .select()   //配置要生成文档的包与路径
                .apis(RequestHandlerSelectors.basePackage("com.xxx.bootdemo01"))   //RequestHandlerSelectors.any()代表所有包都将生成API文档，springBoot工程一般指定父级包防止springBoot内部的组件里的信息也被文档展示出来
                .paths(PathSelectors.any()) //配置任意路径都将生成文档
                .build();
    }

    public ApiInfo getApiInfo() {
        return new ApiInfoBuilder().title("swagger")
                .description("swagger测试")
                .termsOfServiceUrl("http://localhost:8080/")
                .contact("546128288@qq.com")
                .version("1.0")
                .build();
    }
}
```

3.访问接口文档

swagger-bootstrap-ui 访问路径：http://localhost:8080/doc.html

springfox-swagger-ui 访问路径：http://localhost:8080/swagger-ui.html

# 三、常用注解

| 名称                | 描述                                 |
| ------------------- | ------------------------------------ |
| @Api()              | 应用于resource类上，表示一个模块名称 |
| @ApiOperation()     | 用于接口方法上                       |
| @ApiParam()         | 应用于请求参数上，用来描述参数信息   |
| @ApiModel()         | 应用于实体类上，用来描述实体类       |
| @ApiModelProperty() | 应用于实体类字段上，用来描述字段     |

使用示例

```java
@RestController
@Api(value = "demo", tags = {"demo"})
public class DemoResource {

    private static final Logger logger = LoggerFactory.getLogger(DemoResource.class);

    @Autowired
    private DemoService demoService;

    @GetMapping("/demo")
    @ApiOperation("查询demo")
    public User demo() {
        logger.warn("访问demo接口");
        return new User();
    }
}
```

```java
@ApiModel(value = "user", description = "用户实体类")
public class User {

    @ApiModelProperty(name = "name", value = "用户名")
    private String name;
    @ApiModelProperty(name = "pass", value = "密码")
    private String pass;
}
```

# 四、SpringBoot快速整合

1. 引用依赖

```xml
<dependency>
    <groupId>com.spring4all</groupId>
    <artifactId>swagger-spring-boot-starter</artifactId>
    <version>1.7.0.RELEASE</version>
</dependency>
```

2. 添加配置

```yml
swagger:
  base-package: com.cloud.member.service
  title: 会员服务接口
  description: 会员服务接口
  version: 1.1
  terms-of-service-url: www.cloud.com
  contact:
    name: lzj
    email: 611111@qq.com
```

3. 开启swagger

```java
@SpringBootApplication
@EnableSwagger2Doc
public class CloudApplication {
    
    public static void main(String[] args) {
        SpringApplication.run(CloudApplication.class, args);
    }
}
```

4. 访问swagger 

默认地址为/swagger-ui.html

# 五、分布式zuul网关整合多个项目的swagger

1. 添加依赖

```xml
<dependency>
    <groupId>com.spring4all</groupId>
    <artifactId>swagger-spring-boot-starter</artifactId>
    <version>1.7.0.RELEASE</version>
</dependency>
```

2. 整合多个项目的swagger

```java
@EnableZuulProxy
@SpringBootApplication
@EnableSwagger2Doc
public class ZuulApplication {

    public static void main(String[] args) {
        SpringApplication.run(ZuulApplication.class, args);
    }

    // 添加文档来源
    @Component
    @Primary
    class DocumentationConfig implements SwaggerResourcesProvider {
        @Override
        public List<SwaggerResource> get() {
            List resources = new ArrayList();
            resources.add(swaggerResource("cloud-mall-member", "/cloud-mall-member/v2/api-docs", "2.0"));
            resources.add(swaggerResource("cloud-mall-weixin", "/cloud-mall-weixin/v2/api-docs", "2.0"));
            return resources;
        }

        private SwaggerResource swaggerResource(String name, String location, String version) {
            SwaggerResource swaggerResource = new SwaggerResource();
            swaggerResource.setName(name);
            swaggerResource.setLocation(location);
            swaggerResource.setSwaggerVersion(version);
            return swaggerResource;
        }

    }
}
```

