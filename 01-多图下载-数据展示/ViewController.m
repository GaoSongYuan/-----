//
//  ViewController.m
//  01-多图下载-数据展示
//
//  Created by Song on 17/5/15.
//  Copyright © 2017年 Song. All rights reserved.
//

#import "ViewController.h"
#import "GSYAPP.h"

@interface ViewController ()

@property(nonatomic,strong) NSArray *apps; // 应用

@property(nonatomic,strong) NSMutableDictionary *images; // 下载的图片

@property(nonatomic,strong) NSOperationQueue *queue; // 队列

@property(nonatomic,strong) NSMutableDictionary *operations; // 操作缓存

@end

@implementation ViewController

#pragma mark - 懒加载
-(NSMutableDictionary *)operations {
    if (_operations == nil) {
        _operations = [NSMutableDictionary dictionary];
    }
    return _operations;
}

-(NSOperationQueue *)queue {
    if (_queue == nil) {
        _queue = [[NSOperationQueue alloc] init];
    }
    return _queue;
}

-(NSMutableDictionary *)images {
    if (_images == nil) {
        _images = [NSMutableDictionary dictionary];
    }
    return _images;
}

-(NSArray *)apps {
    if (_apps == nil) {
        
        // 沙盒路径
        NSLog(@"%@",[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)lastObject]);
        
        // 获取plist路径
        NSString *path = [[NSBundle mainBundle]pathForResource:@"apps.plist" ofType:nil];
        
        // 加载字典数组
        NSArray *dictArray = [NSArray arrayWithContentsOfFile:path];
        
        // 字典数组 -> 模型数组
        NSMutableArray *arrayM = [NSMutableArray array];
        for (NSDictionary *dict in dictArray) {
            [arrayM addObject:[GSYAPP appWithDict:dict]];
        }
        _apps = arrayM;
    }
    return _apps;
}


#pragma mark - UITableViewDatasource
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.apps.count;
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *ID = @"app";
    //1.创建cell
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ID];
    
    //2.设置cell的数据
    // 2.1 拿到改行cell对应的数据
    GSYAPP *appM = self.apps[indexPath.row];
    
    // 2.2 设置标题
    cell.textLabel.text = appM.name;
    
    // 2.3 设置子标题
    cell.detailTextLabel.text = appM.download;
    
    // 2.4 设置图片
    /*
     先去查看内存缓存中图片是否存在，如果存在就直接下载使用，如果不存在，就去检查磁盘缓存
     如果有磁盘缓存，就保存一份到内存，再设置图片，如果不存在，就下载（下载后同时存到 磁盘缓存 和 内存缓存中）
     */
    UIImage *image = [self.images objectForKey:appM.icon];
    if (image) {
        // 如果 内存缓存中 图片存在
        cell.imageView.image = image;
        NSLog(@"%zd使用内存缓存的图片",indexPath.row);
        
    } else { // 内存缓存中图片不存在，去检查磁盘缓存
        
        // 沙盒缓存路径
        NSString *caches = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)lastObject];
        // 获得图片的名称，不能包含/
        NSString *filename = [appM.icon lastPathComponent]; // 取最后面的节点，即图片文件的名称
        // 拼接图片的全路径
        NSString *fullPath = [caches stringByAppendingPathComponent:filename];
        
        // 检查磁盘缓存（即沙盒缓存）
        NSData *imageData = [NSData dataWithContentsOfFile:fullPath];
        
        if (imageData) { // 磁盘缓存中存在图片（内存缓存中不存在图片）
            
            UIImage *image = [UIImage imageWithData:imageData];
            cell.imageView.image = image; // 设置图片
            NSLog(@"%zd --- 磁盘缓存的图片",indexPath.row);
            // 把图片保存到内存缓存
            [self.images setObject:image forKey:appM.icon];
            
        } else { // 不存在, 直接下载
            
            // 检查该图片是否在下载，如果是在下载，就什么都不做，如果没有在下载，就去添加下载任务。
            NSBlockOperation *download = [self.operations objectForKey:appM.icon];
            if (download) {
                
            }else {
                
                // 先设置cell原来的图片 - 占位图片
                cell.imageView.image = [UIImage imageNamed:@"t01c3f62a27c3de7af5"];
                
                download = [NSBlockOperation blockOperationWithBlock:^{
                    NSURL *url = [NSURL URLWithString:appM.icon];
                    NSData *imageData = [NSData dataWithContentsOfURL:url];
                    UIImage *image = [UIImage imageWithData:imageData];
                    
                    NSLog(@"%zd --- 下载",indexPath.row);
                    
                    // 容错处理 - plist文件中的URL出错
                    if (image == nil) {
                        [self.operations removeObjectForKey:appM.icon];
                        return ;
                    }
                    
                    // 延时 - 网速慢的情况：
                    //                    [NSThread sleepForTimeInterval:2.0];
                    
                    // 把图片保存到内存缓存
                    [self.images setObject:image forKey:appM.icon];
                    
                    // 线程间通信 - 主线程 - 刷新
                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                        //                        cell.imageView.image = image;
                        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationLeft];
                    }];
                    
                    
                    
                    // 写数据到沙盒：
                    [imageData writeToFile:fullPath atomically:YES];
                    
                    // 移除图片的下载操作
                    [self.operations removeObjectForKey:appM.icon];
                }];
                
                // 添加操作到操作缓存中
                [self.operations setObject:download forKey:appM.icon];
                
                // 添加操作到队列
                [self.queue addOperation:download];
            }
        }
    }

    //3.返回cell
    return cell;
}


@end
