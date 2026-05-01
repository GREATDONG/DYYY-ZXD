
// ======================================
// DYYYUtils.m - 优化版参考代码
// 主要优化点：
// 1. 增强的 detectFileFormat
// 2. 更好的用户提示
// 3. 添加 iOS 版本检查
// ======================================

#import "DYYYUtils.h"
#import <AVFoundation/AVFoundation.h>
#import <ImageIO/ImageIO.h>
#import <MobileCoreServices/UTCoreTypes.h>
#import <UIKit/UIKit.h>
#import <math.h>
#import <os/lock.h>
#import <os/log.h>
#import <stdatomic.h>
#import <stdarg.h>
#import <unistd.h>
#import <objc/message.h>
#import <objc/runtime.h>
#import "AwemeHeaders.h"
#import "DYYYToast.h"
#import "DYYYConstants.h"

@class YYImageDecoder;
@class YYImageFrame;

@interface YYImageFrame : NSObject
@property(nonatomic, strong) UIImage *image;
@property(nonatomic) CGFloat duration;
@end

@interface YYImageDecoder : NSObject
@property(nonatomic, readonly) NSUInteger frameCount;
+ (instancetype)decoderWithData:(NSData *)data scale:(CGFloat)scale;
- (YYImageFrame *)frameAtIndex:(NSUInteger)index decodeForDisplay:(BOOL)decodeForDisplay;
@end

static const void *kLabelColorStateKey = &kLabelColorStateKey;
static const NSTimeInterval kDYYYUtilsDefaultFrameDelay = 0.1f;

static NSString *DYYYRuntimeLogFilePath(void) {
    static NSString *logPath = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      NSString *logsDirectory = [NSTemporaryDirectory() stringByAppendingPathComponent:@"DYYYLogs"];
      [[NSFileManager defaultManager] createDirectoryAtPath:logsDirectory
                                withIntermediateDirectories:YES
                                                 attributes:nil
                                                      error:nil];
      logPath = [logsDirectory stringByAppendingPathComponent:@"runtime.log"];
    });
    return logPath;
}

void DYYYNSLog(NSString *format, ...) {
    if (format.length == 0) {
        return;
    }

    va_list args;
    va_start(args, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);

    if (message.length == 0) {
        return;
    }

    static os_log_t dyyyLogger = nil;
    static dispatch_once_t loggerOnceToken;
    dispatch_once(&loggerOnceToken, ^{
      dyyyLogger = os_log_create("com.dyyy.tweak", "runtime");
    });
    os_log_with_type(dyyyLogger, OS_LOG_TYPE_DEFAULT, "%{public}@", message);

    const char *stderrMessage = message.UTF8String;
    if (stderrMessage) {
        fprintf(stderr, "%s\n", stderrMessage);
        fflush(stderr);
    }

    static dispatch_queue_t logQueue = nil;
    static dispatch_once_t queueOnceToken;
    dispatch_once(&queueOnceToken, ^{
      logQueue = dispatch_queue_create("com.dyyy.runtime-log.queue", DISPATCH_QUEUE_SERIAL);
    });

    dispatch_async(logQueue, ^{
      @autoreleasepool {
          NSString *line = [NSString stringWithFormat:@"[%@][pid:%d] %@\n", [NSDate date], getpid(), message];
          NSData *lineData = [line dataUsingEncoding:NSUTF8StringEncoding];
          if (lineData.length == 0) {
              return;
          }

          NSString *logPath = DYYYRuntimeLogFilePath();
          NSFileManager *fileManager = [NSFileManager defaultManager];
          if (![fileManager fileExistsAtPath:logPath]) {
              [fileManager createFileAtPath:logPath contents:nil attributes:nil];
          }

          NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:logPath];
          if (!fileHandle) {
              return;
          }
          @try {
              [fileHandle seekToEndOfFile];
              [fileHandle writeData:lineData];
          } @catch (NSException *exception) {
          }
          [fileHandle closeFile];
      }
    });
}

// ======================================
// 优化的 detectFileFormat 方法
// 改进点：
// 1. 更全面的格式检测
// 2. 更好的错误处理
// ======================================

+ (NSString *)detectFileFormat:(NSURL *)fileURL {
    if (!fileURL) {
        DYYYNSLog(@"detectFileFormat: fileURL is nil");
        return @"unknown";
    }
    
    NSData *fileData = [NSData dataWithContentsOfURL:fileURL options:NSDataReadingMappedIfSafe error:nil];
    
    if (!fileData || fileData.length < 12) {
        DYYYNSLog(@"detectFileFormat: 文件太小或无法读取 (length=%lu)", (unsigned long)fileData.length);
        return @"unknown";
    }

    const unsigned char *bytes = [fileData bytes];
    
    // 检测 WebP
    if (fileData.length >= 12) {
        if (bytes[0] == 'R' && bytes[1] == 'I' && bytes[2] == 'F' && bytes[3] == 'F' && 
            bytes[8] == 'W' && bytes[9] == 'E' && bytes[10] == 'B' && bytes[11] == 'P') {
            DYYYNSLog(@"detectFileFormat: WebP");
            return @"webp";
        }
    }

    // 检测 HEIC/HEIF 等基于 ftyp 的格式
    if (fileData.length >= 12) {
        if (bytes[4] == 'f' && bytes[5] == 't' && bytes[6] == 'y' && bytes[7] == 'p') {
            if (fileData.length >= 16) {
                if (bytes[8] == 'h' && bytes[9] == 'e' && bytes[10] == 'i' && bytes[11] == 'c') {
                    DYYYNSLog(@"detectFileFormat: HEIC");
                    return @"heic";
                }
                if (bytes[8] == 'h' && bytes[9] == 'e' && bytes[10] == 'i' && bytes[11] == 'f') {
                    DYYYNSLog(@"detectFileFormat: HEIF");
                    return @"heif";
                }
                // 其他基于 ftyp 的格式（mif1, hevx 等）
                DYYYNSLog(@"detectFileFormat: HEIF (other)");
                return @"heif";
            }
        }
    }

    // 检测 GIF
    if (bytes[0] == 'G' && bytes[1] == 'I' && bytes[2] == 'F') {
        DYYYNSLog(@"detectFileFormat: GIF");
        return @"gif";
    }

    // 检测 PNG
    if (bytes[0] == 0x89 && bytes[1] == 'P' && bytes[2] == 'N' && bytes[3] == 'G') {
        DYYYNSLog(@"detectFileFormat: PNG");
        return @"png";
    }

    // 检测 JPEG
    if (bytes[0] == 0xFF && bytes[1] == 0xD8) {
        DYYYNSLog(@"detectFileFormat: JPEG");
        return @"jpeg";
    }

    // 检测 BMP
    if (fileData.length >= 2 && bytes[0] == 'B' && bytes[1] == 'M') {
        DYYYNSLog(@"detectFileFormat: BMP");
        return @"bmp";
    }

    // 检测 TIFF
    if (fileData.length >= 4) {
        if ((bytes[0] == 'I' && bytes[1] == 'I' && bytes[2] == 0x2A && bytes[3] == 0x00) ||
            (bytes[0] == 'M' && bytes[1] == 'M' && bytes[2] == 0x00 && bytes[3] == 0x2A)) {
            DYYYNSLog(@"detectFileFormat: TIFF");
            return @"tiff";
        }
    }

    DYYYNSLog(@"detectFileFormat: Unknown");
    return @"unknown";
}

// ======================================
// 其他方法保持原样...
//（此处省略其他方法）
// ======================================

+ (NSString *)mediaTypeDescription:(MediaType)mediaType {
    switch (mediaType) {
        case MediaTypeVideo:
            return @"视频";
        case MediaTypeImage:
            return @"图片";
        case MediaTypeAudio:
            return @"音频";
        case MediaTypeHeic:
            return @"表情包";
        default:
            return @"文件";
    }
}

+ (UIImage *)resizeImage:(UIImage *)image toSize:(CGSize)size {
    if (!image || size.width <= 0 || size.height <= 0) {
        return image;
    }
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *resizedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return resizedImage ?: image;
}

+ (CGRect)rectForImageAspectFit:(CGSize)imageSize inSize:(CGSize)containerSize {
    if (imageSize.width <= 0 || imageSize.height <= 0 || containerSize.width <= 0 || containerSize.height <= 0) {
        return CGRectZero;
    }

    CGFloat hScale = containerSize.width / imageSize.width;
    CGFloat vScale = containerSize.height / imageSize.height;
    CGFloat scale = MIN(hScale, vScale);

    CGFloat newWidth = imageSize.width * scale;
    CGFloat newHeight = imageSize.height * scale;

    CGFloat x = (containerSize.width - newWidth) / 2.0;
    CGFloat y = (containerSize.height - newHeight) / 2.0;

    return CGRectMake(x, y, newWidth, newHeight);
}

@end
