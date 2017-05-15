//
//  GSYAPP.m
//  01-多图下载-数据展示
//
//  Created by Song on 17/5/15.
//  Copyright © 2017年 Song. All rights reserved.
//

#import "GSYAPP.h"

@implementation GSYAPP

+(instancetype)appWithDict:(NSDictionary *)dict {
    GSYAPP *appM = [[GSYAPP alloc] init];
    [appM setValuesForKeysWithDictionary:dict];
    return appM;
}

@end
