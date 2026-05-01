# DYYY 优化应用指南

---

## 第一步：应用 GitHub Actions 构建优化

### 手动操作：

1. 打开你的 DYYY 项目文件夹
2. 找到 `.github/workflows/build.yml`
3. 用 `dyyy_optimized/build.yml` 的内容覆盖它

### 或者用命令行（在 macOS/Linux 上）：

```bash
cd DYYY  # 你的 DYYY 项目目录
cp f:/GITHUB/QCLAW/dyyy_optimized/build.yml .github/workflows/

# 提交更改
git add .github/workflows/build.yml
git commit -m "优化 GitHub Actions 构建配置"
git push
```

---

## 第二步：应用 Makefile 优化（可选但推荐）

### 手动操作：

1. 打开 DYYY 项目中的 `Makefile`
2. 参考 `dyyy_optimized/Makefile.optimized` 的改动
3. 主要改动：
   - 更新 C++ 标准从 c++11 到 c++17
   - 增强 CFLAGS 和 LDFLAGS
   - 添加更多 Frameworks
   - 改进提示信息（中文）

### 或者直接替换（如果你没有修改过 Makefile）：

```bash
cd DYYY
cp f:/GITHUB/QCLAW/dyyy_optimized/Makefile.optimized Makefile

# 提交更改
git add Makefile
git commit -m "优化 Makefile 编译配置"
git push
```

---

## 第三步：应用代码优化（重要！）

### 必须修改的文件：DYYYManager.m

**找到 `parseAndDownloadVideoWithShareLink` 方法，用下面的代码替换：**

```objc
+ (void)parseAndDownloadVideoWithShareLink:(NSString *)shareLink apiKey:(NSString *)apiKey {
    [self parseAndDownloadVideoWithShareLink:shareLink apiKey:apiKey retryCount:0];
}

+ (void)parseAndDownloadVideoWithShareLink:(NSString *)shareLink apiKey:(NSString *)apiKey retryCount:(NSInteger)retryCount {
    if (shareLink.length == 0 || apiKey.length == 0) {
        [DYYYUtils showToast:@"分享链接或API密钥无效"];
        return;
    }

    // 新的 API 接口
    NSString *apiUrl = [NSString stringWithFormat:@"https://api.qsy.ink/api/douyin?key=%@&url=%@", 
                        apiKey, 
                        [shareLink stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];

    NSURL *url = [NSURL URLWithString:apiUrl];
    if (!url) {
        [DYYYUtils showToast:@"API URL无效"];
        return;
    }

    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    config.timeoutIntervalForRequest = 60.0;
    config.timeoutIntervalForResource = 60.0;
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
    
    NSURLSessionDataTask *dataTask = [session dataTaskWithURL:url
                                           completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            @try {
                if (error) {
                    // 自动重试
                    if (retryCount < 3) {
                        [DYYYUtils showToast:[NSString stringWithFormat:@"请求失败，重试 %ld/3...", (long)(retryCount + 1)]];
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)),
                                    dispatch_get_main_queue(), ^{
                            [self parseAndDownloadVideoWithShareLink:shareLink apiKey:apiKey retryCount:retryCount + 1];
                        });
                        return;
                    }
                    [DYYYUtils showToast:[NSString stringWithFormat:@"请求失败: %@", error.localizedDescription]];
                    return;
                }

                if (!data) {
                    [DYYYUtils showToast:@"未获取到数据"];
                    return;
                }

                NSError *jsonError;
                NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
                
                if (jsonError) {
                    [DYYYUtils showToast:@"解析数据失败"];
                    return;
                }

                NSInteger code = [json[@"code"] integerValue];
                if (code != 0 && code != 200) {
                    NSString *msg = json[@"msg"] ?: @"未知错误";
                    [DYYYUtils showToast:[NSString stringWithFormat:@"错误: %@", msg]];
                    return;
                }

                NSDictionary *dataDict = json[@"data"];
                if (!dataDict) {
                    [DYYYUtils showToast:@"数据为空"];
                    return;
                }

                // 交给原方法处理
                [self handleVideoData:dataDict];
                
            } @catch (NSException *exception) {
                [DYYYUtils showToast:@"发生异常，请重试"];
            }
        });
    }];

    [dataTask resume];
}
```

### 可选优化：DYYYUtils.m

你可以查看 `dyyy_optimized/optimized_DYYYUtils.m` 中的 `detectFileFormat` 方法，它有更详细的格式检测和日志输出。

---

## 第四步：提交并推送所有更改

```bash
cd DYYY

# 检查改动
git status

# 提交所有改动
git add -u
git commit -m "适配抖音 38.4+ 版本：更新 API 接口，优化错误处理"

# 推送到 GitHub
git push
```

---

## 第五步：查看 GitHub Actions 构建

推送成功后：

1. 打开你的 GitHub 仓库页面
2. 点击 **Actions** 标签
3. 你会看到 **build deb** 工作流正在运行
4. 等待 5-10 分钟，直到构建完成
5. 构建成功后，下载 Artifacts 中的 `.deb` 文件

---

## 完成！

现在你的 DYYY 插件已经优化完成，可以在抖音 38.4+ 版本上使用了！
