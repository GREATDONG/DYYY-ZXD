+ (void)parseAndDownloadVideoWithShareLink:(NSString *)shareLink apiKey:(NSString *)apiKey {
    [self parseAndDownloadVideoWithShareLink:shareLink apiKey:apiKey retryCount:0];
}

+ (void)parseAndDownloadVideoWithShareLink:(NSString *)shareLink apiKey:(NSString *)apiKey retryCount:(NSInteger)retryCount {
    if (shareLink.length == 0 || apiKey.length == 0) {
        [DYYYUtils showToast:@"分享链接或API密钥无效"];
        return;
    }

    // 新的 API 接口
    NSString *apiUrl = [NSString stringWithFormat:@"https://api.qsy.ink/api/douyin?key=%@&url=%@", apiKey, [shareLink stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];

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
                                                            // 自动重试机制
                                                            if (retryCount < 3) {
                                                                [DYYYUtils showToast:[NSString stringWithFormat:@"请求失败,重试 %ld/3...", (long)(retryCount + 1)]];
                                                                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
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
                                                            [DYYYUtils showToast:@"解析接口返回数据失败"];
                                                            return;
                                                        }

                                                        NSInteger code = [json[@"code"] integerValue];
                                                        if (code != 0 && code != 200) {
                                                            [DYYYUtils showToast:[NSString stringWithFormat:@"接口返回错误: %@", json[@"msg"] ?: @"未知错误"]];
                                                            return;
                                                        }

                                                        NSDictionary *dataDict = json[@"data"];
                                                        if (!dataDict) {
                                                            [DYYYUtils showToast:@"接口返回数据为空"];
                                                            return;
                                                        }

                                                        // 交给handleVideoData处理数据
                                                        [self handleVideoData:dataDict];
                                                    } @catch (NSException *exception) {
                                                        [DYYYUtils showToast:@"发生异常,请重试"];
                                                    }
                                                  });
                                                }];

    [dataTask resume];
}
