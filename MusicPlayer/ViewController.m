//
//  ViewController.m
//  网络音乐下载
//
//  Created by THANAO on 19/8/16.
//  Copyright © 2016年 personal. All rights reserved.
//
#define kProgressPlistPath [NSHomeDirectory() stringByAppendingString:@"/Documents/kDicPlistPath.plist"]
#define kResumeDataPath [NSHomeDirectory() stringByAppendingString:@"/Documents/resumeData.plist"]
#define kMusicSavePath [NSHomeDirectory() stringByAppendingString:@"/Documents/flower.mp3"]

#import <AVFoundation/AVFoundation.h>

#import "ViewController.h"

@interface ViewController () <NSURLSessionDownloadDelegate> {
    AVAudioPlayer *_player; 
    NSURL *_targetURL;
    NSURLSessionDownloadTask *_downloadTask;
    NSURLSession *_session;
    CGFloat _progress;
    BOOL _isExists; // 判断音乐文件是否存在
    NSMutableDictionary *_progressDic;
    
    BOOL _isFirstCreate; // 判断AVAudioPlayer是否第一次创建
}
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (weak, nonatomic) IBOutlet UILabel *resultLabel;
@property (weak, nonatomic) IBOutlet UIButton *playButton;

@end

@implementation ViewController

#pragma mark - buttonAction
- (IBAction)startDownload:(UIButton *)sender {
    
    if (!_isExists) {
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
        dispatch_async(queue, ^{
            // 获取网络音乐的url
            NSURL *url = [NSURL URLWithString:@"http://m2.music.126.net/r22btSztTs6hPyS-SNYJSg==/3255653929909959.mp3"];
            _downloadTask = [_session downloadTaskWithURL:url];
            [_downloadTask resume];
        });
    }
}

- (IBAction)pauseAction:(UIButton *)sender {
    if (_downloadTask != nil && _downloadTask.state == NSURLSessionTaskStateRunning) {
        [_downloadTask cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
            [resumeData writeToFile:kResumeDataPath atomically:YES];
            
            _downloadTask = nil;
            NSNumber *progress = @(_progressView.progress);
            [_progressDic setObject:progress forKey:@"downloadProgress"];
            [_progressDic writeToFile:kProgressPlistPath atomically:YES];
        }];
    }
}
- (IBAction)resumeAction:(UIButton *)sender {
    if (_downloadTask != nil && _downloadTask.state == NSURLSessionTaskStateRunning) {
        return;
    }
    NSData *resumeData = [NSData dataWithContentsOfFile:kResumeDataPath];
    // 判断之前是否有任务
    if (!resumeData) {
        return;
    }
    
    _downloadTask = [_session downloadTaskWithResumeData:resumeData];
    [_downloadTask resume];
    
    [[NSFileManager defaultManager] removeItemAtPath:kResumeDataPath error:nil];
    [[NSFileManager defaultManager] removeItemAtPath:kProgressPlistPath error:nil];
    
}
- (IBAction)playAndStop:(UIButton *)sender {
    _targetURL = [NSURL fileURLWithPath:kMusicSavePath];
    
    if (!_isFirstCreate) {
        _player = [[AVAudioPlayer alloc] initWithContentsOfURL:_targetURL error:nil];
        _player.numberOfLoops = 10;
        [_player prepareToPlay];
        _isFirstCreate = YES;
    }
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!_isExists) {
                UIAlertController *alertCtrl = [UIAlertController alertControllerWithTitle:@"真抱歉！！！" message:@"歌曲未下载，或已被删除" preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *alertAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil];
                [alertCtrl addAction:alertAction];
                [self presentViewController:alertCtrl animated:YES completion:NULL];
                return;
            }
            if ([sender.currentTitle isEqualToString:@"播放"]) {
                [sender setTitle:@"暂停" forState:UIControlStateNormal];
                [_player play];
            } else {
                [sender setTitle:@"播放" forState:UIControlStateNormal];
                [_player stop];
            }
        });
    });
}

- (IBAction)deleteMusic:(UIButton *)sender {
    
    [[NSFileManager defaultManager] removeItemAtPath:kMusicSavePath error:nil];
    [[NSFileManager defaultManager] removeItemAtPath:kProgressPlistPath error:nil];
    _progressView.progress = 0;
    _progressView.hidden = NO;
    _resultLabel.text = @"未下载歌曲，请点击下载";
    [_playButton setTitle:@"播放" forState:UIControlStateNormal];
    _isExists = NO;
    _isFirstCreate = NO;
    [_player stop];
    
}
#pragma mark - NSURLSessionDownloadDelegate
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location {
    _resultLabel.text = @"下载已完成,可点击播放";
    _progressView.hidden = YES;
    NSFileManager *manager = [NSFileManager defaultManager];
    _targetURL = [NSURL fileURLWithPath:kMusicSavePath];
    [manager moveItemAtURL:location toURL:_targetURL error:nil];
    [manager removeItemAtPath:kResumeDataPath error:nil];
    _isExists = YES;
    
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    
    _progress = (CGFloat)totalBytesWritten / totalBytesExpectedToWrite;
    _progressView.progress = _progress;
}

#pragma mark
- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"%@", kMusicSavePath);
    _progressDic = [[NSMutableDictionary alloc] init];
    
    _player = [[AVAudioPlayer alloc] initWithContentsOfURL:_targetURL error:nil];
    _player.numberOfLoops = 10;
    [_player prepareToPlay];
    
    // 用于判断音乐是否已存在
    _isExists = [[NSFileManager defaultManager] fileExistsAtPath:kMusicSavePath];
    if (_isExists) {
        _progressView.hidden = YES;
        _resultLabel.text = @"已下载过歌曲,可直接播放";
        

    } else {
        _resultLabel.text = @"未下载歌曲，请点击下载";
        _progressView.hidden = NO;
        NSDictionary *dic = [[NSDictionary alloc] initWithContentsOfFile:kProgressPlistPath];
        _progressView.progress = [dic[@"downloadProgress"] floatValue];
    }
    
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    config.requestCachePolicy = NSURLRequestUseProtocolCachePolicy;
    config.allowsCellularAccess = YES;
    _session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
