//
//  XlsxReader.h
//  LocsUtil
//
//  Created by Martin Krasnocka on 17/10/2017.
//  Copyright © 2017 Martin Krasnocka. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XlsxReader : NSObject

- (NSArray *) loadXlsxFromFileAtPath:(NSString *)filePath;

@end
