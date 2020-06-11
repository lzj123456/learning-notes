# 一、XSS注入

XSS是通过向web站点注入前端脚本，在用户访问站点时进行触发可以进行cookie窃取等行为

## 1.1 存储型XSS

它通过向数据库注入XSS脚本在页面加载时渲染从数据库查询出来的数据进行触发，例如留言功能，我们向留言中写一段XSS脚本保存留言道数据库，当查看这个留言时就会触发这个xss脚本，如果对xss脚本做关键字符转义就不会有这个问题了。

## 1.2 反射型XSS

通过在URL的参数传输一段XSS脚本，当我们访问一个页面需要传参给服务器，然后服务端会把参数转发到另外一个页面时进行展示，这是也会触发XSS脚本。

### 1.3 DOM型XSS

也是通过URL传输一段XSS脚本，JS从url获取属性值并把此值生成DOM元素展示在页面时也会触发XSS脚本

## 1.4 防御

1. 前端防御，对接收到的参数进行转义，把< > “ ’等符号转义
2. 后端防御，对接收到的参数进行转义，前后端都有现成的类库可以使用
3. 富文本防御，由于富文本本身存储的数据就是HTML代码片段，所以不能进行转义只能进行过滤，一般使用白名单的方式只允许固定的一些内容存在，非法的内容会被过滤掉，也有很多现成的工具类库

# 二、CSRF

## 1. 原理

跨站请求伪造，它是在用户登录后利用登录信息，在用户不知情的情况下，以用户的名义完成非法操作。

场景：当用户登录成功后，无意间点击进入了黑客制造的一个页面，然后这个页面会利用用户已登录的cookie在页面加载时触发脚本做一些提交请求。

## 2. 防御

### 2.1 验证 HTTP Referer 字段

* 后端添加拦截器校验HTTP 头中有一个字段叫 Referer，（它记录了该 HTTP 请求的来源地址）是否为可信任来源（Referer值是否是指定页面，或者网站的域）
* 优点：简单易行，特别是对于当前现有的系统，不需要改变当前系统的任何已有代码和逻辑，没有风险，非常便捷。
* 不足：Referer 的值是由浏览器提供的，每个浏览器对于 Referer 的具体实现可能有差别，并不能保证浏览器自身没有安全漏洞，安全性依赖于第三方（低版本浏览器 IE6 或 FF2，有一些方法可以篡改 Referer 值），因为 Referer 值会记录下用户的访问来源，有些用户认为这样会侵犯到他们自己的隐私权，特别是有些组织担心 Referer 值会把组织内网中的某些信息泄露到外网中。因此，用户可以手动关闭浏览器 Referer。
* 难点：后端校验域名规则

### 2.2 token验证(前后端配合)

* 后端随机生成一个token返回给前端，前端把收到的token存入cookie和本地缓存一份，当发送请求的时候把token携带过去，可以放在参数上也可以用请求头携带，后端会校验参数token与cookie中的token是否一致，并判断token是否合法，由于CSRF攻击页面缓存中是不会有token的所以没办法再攻击成功
* 优点：无需依赖浏览器
* 不足：难以保证 token 本身的安全

### 2.3 Chrome 浏览器端启用 SameSite cookie

* SameSite 有两种模式，Lax跟Strict模式，默认启用Strict模式，可以自己指定模式：

* Strict模式规定 cookie 只允许相同的site使用，不应该在任何的 cross site request 被加上去。即a标签、form表单和XMLHttpRequest提交的内容，只要是提交到不同的site去，就不会带上cookie。

* Lax 模式打开了一些限制，例如a标签、form表单和XMLHttpRequest提交的内容，这些都会带上cookie。但是 POST 方法 的 form，或是只要是 POST, PUT, DELETE 这些方法，就不会带cookie。

* 优点：设置简单

* 不足：该方式目前仅Chrome支持，不兼容其他浏览器

* ```java
  response.setHeader("Set-Cookie", "key=value; HttpOnly; SameSite=strict")
  ```

### 2.4 验证码

* 验证码，强制用户必须与应用进行交互，才能完成最终请求。在通常情况下，验证码能很好遏制CSRF攻击。但是出于用户体验考虑，网站不能给所有的操作都加上验证码。因此验证码只能作为一种辅助手段，不能作为主要解决方案。

# 三、点击劫持

## 1. 原理

用来骗取用户的操作，原理是利用页面对用户可见的按钮与用户不可见的页面按钮重叠，当用户点击可见的按钮时同时也会触发不可见的页面按钮，如果使用<iframe>标签嵌入另一个页面，让嵌入页面中的按钮与用户可见的按钮重叠就可骗取用户的操作。

## 2. 防御

响应头增加X-Frame-Options避免网站被嵌入到其他网站iframe中，避免Clickjacking（点击劫持）攻击

X-Frame-Options取值

DENY：浏览器拒绝当前页面加载任何Frame页面
SAMEORIGIN：frame页面的地址只能为同源域名下的页面
ALLOW-FROM：origin为允许frame加载的页面地址


建议在java代码根源限制如：response.addHeader("x-frame-options","SAMEORIGIN");

# 四、URL跳转漏洞

http://www.test1.com?url=www.test2.com 上面这个连接如果网站获取参数url进行跳转的话就会有漏洞产生，黑客可以使用url传入一个恶意连接导致用户访问时被跳转到恶意网站

# 五、SQL注入

是指把传入的参数当作SQL语句来执行，例如：

```sql
--通过这条sql查询用户信息
select * from user where username='param1' and passowrd='param2'
--当我们登录时传入用户名为admin' --时，这就会导致不许要密码就能查到用户名
select * from user where username='admin' --' and passowrd='param2'

```

# 六、命令注入

与SQL注入类似，他是向调用系统命令的函数参数中做注入

```java
//这里通过参数param1传入要访问的url
Process cmd = Runtime.getRuntime().exec(curl + param1);
//命令注入,param1如果传 www.baidu.com&shutdown -now,这时就把额外的命令注入执行了
```

# 七、文件操作漏洞

## 1. 上传文件漏洞

我们上传文件时上传一个shell脚本，当我们获取到上传后的文件地址时在浏览器中执行这个地址就可以触发这个shell脚本的执行，这个漏洞还可以上传webshell等用来监控目标服务

解决方案：

对上传的文件类型做限制，并对指定路径下的文件做权限设置，只给写权限不给执行权限

## 2. 下载文件漏洞

下载文件时我们修改参数，尝试下载服务器上不同路径下的文件，来获取服务器上的信息

# 八、cookie安全

## 1. httpOnly

httpOnly只允许http传输时访问cookie，不允许js对cookie进行获取与修改，存储sessionId的cookie应该设置httpOnly属性，防止XSS攻击获取并篡改cookie信息。

配置方式

```xml
<!--在tomcat6及以下版本需要手动配置,以上版本默认就会对sessionCookie配置此属性-->
<Context useHttpOnly="true">
</Context>

在java中可以使用下面方式来配置
cookie.setHttpOnly(true);
也可以在响应头中设置
response.setHeader("Set-Cookie", "key=value; HttpOnly; SameSite=strict")
```

## 2. secure

secures属性只允许在https下传输token，在https场景下需要开启这个属性

配置方式

```java
cookie.setSecure(true);
```

# 九、TLS低版本漏洞

在使用HTTPS时TLS协议需要使用1.2版本以上，以下版本的TLS会存在安全漏洞

针对nginx设置，配置如：ssl_protocols TLSv1.2;

# 十、异常信息泄露

后端报错应该友好，不应该暴露出异常堆栈信息到前端。

包括程序正常捕获的异常、程序数据类型不匹配的异常等（比如接口接受int类型，但前端传了字符串导致类型不匹配异常；后端使用int，但是前端攻击者传一个大于最大int值的数据）

可以优化异常拦截器

# 十一、NoSQL注入

环境：使用mongodb存储用户信息，根据用户名密码进行查询用户信息，能查询到证明登陆成功，这里存在着注入风险，如果我们存入的密码时一个json对象那么mongodb的特性是能够执行这个json对象的他会当作一个命令来执行从而注入了额外的命令gt>0，所有用户的密码都值都是大于0的就会把用户信息查询出来。

解决方案：对输入的数据进行类型检测，不允许有json对象传入

# 二、安全测试工具

## 1. 敏感文件探测

通过"御剑"工具进行敏感文件探测，提供可能的敏感文件名称字典然后使用这个工具向站点请求这些文件，根据相应码来判断是否找到敏感文件。

## 2. 漏洞扫描工具

AWVS工具可以扫描web漏洞，扫描后会生成漏洞报告和漏洞详情信息可以查看

## 3. SQL注入工具

使用sqlmap可以扫描指定URL请求是否存在SQL注入漏洞，并且可以帮助我们dump目标数据库信息

## 4.在线工具

### 1. 搜索引擎高级搜索

可以使用高级搜索，搜索指定网站URL中包含？的链接，然后根据这些查询到的地址进行SQL注入测试

### 2. 网络空间搜索

https://www.zoomeye.org可以搜索指定服务器版本架设的网站，并且会提供相关服务器的漏洞信息，也可以搜索开放了指定端口的服务器地址信息等

### 3.安全圈

这个网站聚集了大量的web安全工具

# 安全方面资源

1. https://www.freebuf.com/ 专注于安全方面的论坛，其中包含一些公开课和专栏