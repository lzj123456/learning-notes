# 一、官方文档

QQ互联平台官网https://connect.qq.com/，其中有很多可以接入的API文档说明

# 二、开发流程

## 1. 准备工作

首先要在QQ互联平台上注册账号信息，需要用到营业执照等，等账号审批下来后平台会提供AppID与、AppSecret，这两个需要在对接时使用的参数。然后在平台上配置好回调地址，就是一个网址类似http://www.xxx.com/qqLogin，这个地址就是我们自己提供的一个后台接口供QQ授权后进行请求的。

## 2. 登录流程

1. 当用户在网站上选择QQ登录后，前端后者后台去访问QQ授权页面，需要携带AppID、AppSecret、回调地址，这三个参数

2. 当用户在QQ授权页面中授权登陆后，会携带一个code参数请求我们在平台上提供的回调接口地址

3. 我们的回调接口接收到请求后，会根据code到腾讯平台获取QQ用户的access_token信息

4. 然后我们使用access_token获取用户open_id，open_id是一个QQ用户的唯一标识，可以用open_id与我们自己平台上的账号进行绑定

5. 然后我们可以根据业务需要，使用QQ的open_id查询在我们平台上是否已经有绑定的账号，没有进入绑定页面进行绑定，如果已经有绑定的账号则直接登录成功跳转首页或者返回成功状态码给前端

6. 使用open_id和access_token还可以获取到用户基本信息，例如：QQ头像、名称等，用在平台上展示

## 3. 后台接口编写

1. 导入腾讯提供的工具jar包，可以使用maven直接打入仓库

2. 把配置文件导入src下，并修改下面三个值

   ```properties
   app_ID = 101462456
   app_KEY = 4488033be77331e7cdcaed8ceadc10d5
   redirect_URI = http://shop.mayikt.com/qqLoginBack
   ```

   > qqconnectconfig.properties 文件名称

3. 编写拉去授权页面的接口，这一步可以前台直接访问也可以后台访问后重定向到返回的授权页面URL

```java
@RequestMapping("/qqAuth")
public String qqAuth(HttpServletRequest request) {
    try {
        String authorizeURL = new Oauth().getAuthorizeURL(request);
        return "redirect:" + authorizeURL;
    } catch (Exception e) {
        return "跳转到异常页面";
    }
}
```

4. 编写回调接口

```java
@RequestMapping("/qqLoginBack")
public String qqLoginBack(String code, HttpServletRequest request, HttpServletResponse response, HttpSession httpSession) {
    try {
        // 1.使用授权码获取accessToken,工具类会直接从request获取code值
        AccessToken accessTokenObj = (new Oauth()).getAccessTokenByRequest(request);
        if (accessTokenObj == null) {
            return "跳转异常页面";
        }
        String accessToken = accessTokenObj.getAccessToken();
        if (StringUtils.isEmpty(accessToken)) {
            return "跳转异常页面";
        }
        // 2.使用accessToken获取QQ用户openid
        OpenID openIDObj = new OpenID(accessToken);
        String openId = openIDObj.getUserOpenID();
        if (StringUtils.isEmpty(openId)) {
            return "跳转异常页面";
        }
        // 3.使用openid 查询数据库是否已经关联账号信息
        // 3.1 如果没有关联的账号,跳转到关联账号页面
        if (findByOpenId.getCode().equals(203)) {
            // 获取QQ用户基本信息，页面需要展示 QQ头像
            UserInfo qzoneUserInfo = new UserInfo(accessToken, openId);
            UserInfoBean userInfoBean = qzoneUserInfo.getUserInfo();
            // 用户的QQ头像
            String avatarURL100 = userInfoBean.getAvatar().getAvatarURL100();
            request.setAttribute("avatarURL100", avatarURL100);
            // 需要将openid存入在session中
            httpSession.setAttribute("自定义ket", openId);
            return "绑定页面";
        }
        // 3.2 如果能够查询到用户信息的话,直接自动登陆
        return "登录页面";

    } catch (Exception e) {
        return "跳转异常页面";
    }
}
```

5. 绑定账号接口

```java
@RequestMapping("/qqJointLogin")
public String qqJointLogin(@ModelAttribute("loginVo") LoginVO loginVo, Model model, HttpServletRequest request,
                           HttpServletResponse response, HttpSession httpSession) {

    // 1.获取用户openid
    String qqOpenId = (String) httpSession.getAttribute("获取openID");
    if (StringUtils.isEmpty(qqOpenId)) {
        return ERROR_500_FTL;
    }

    // 2.将vo转换dto
    UserLoginInpDTO userLoginInpDTO = BeansUtils.doToDto(loginVo, UserLoginInpDTO.class);
    userLoginInpDTO.setQqOpenId(qqOpenId);
    userLoginInpDTO.setLoginType(Constant.MEMBER_LOGIN_TYPE_PC);
    String info = webBrowserInfo(request);
    userLoginInpDTO.setDeviceInfor(info);
    // 3. 根据业务做处理，如果绑定的是已有账号，则根据绑定页面填写的信息寻找到已有账号绑定上QQ openID，并跳转首页
    // 4. 如果绑定的是新账号，则根据绑定页面填写的信息新增一个新账号并绑定QQ openID，然后跳转至首页
    return "跳转到登陆后的首页";
}
```

