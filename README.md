# RongRTCFilterDemo

1. 请登录官网获取 AppKey, 并使用自定义 userID 获取 token 后, 在 `ViewController.m` 中填写如下内容:
   
    ```objective-c
    self.appKey = @""; //请登录融云官网获取
    self.token = @""; //请使用自定义的userID获取此token
    ```
    
2. 请在 `pod install` 之前, 使用 `pod repo update` 更新本地资源

3. 使用 demo 中的 podfile , 通过 `pod install` 获取最新版本的融云SDK

4. pod 安装完成后, 请打开 pod 生成的 `RongRTCFilterDemo.xcworkspace`

5. 自定义美颜处理在 `ChatGPUImageHandler.m` 中
