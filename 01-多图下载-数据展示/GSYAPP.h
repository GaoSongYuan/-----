//
//  GSYAPP.h
//  01-多图下载-数据展示
//
//  Created by Song on 17/5/15.
//  Copyright © 2017年 Song. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GSYAPP : NSObject

@property(nonatomic,strong) NSString *name;
@property(nonatomic,strong) NSString *icon;
@property(nonatomic,strong) NSString *download;

+(instancetype)appWithDict:(NSDictionary *)dict;

@end
