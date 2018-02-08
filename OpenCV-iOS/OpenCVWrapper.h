//
//  OpenCVWrapper.h
//  OpenCV-iOS
//
//  Created by TerryLiu on 2/2/18.
//  Copyright © 2018 TerryLiu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIkit.h>

@interface OpenCVWrapper : NSObject
+ (NSString *)OpenCVVString;
+ (UIImage *)DetectFeatures:(UIImage *)image;
+ (UIImage *)SobelFilter:(UIImage *)image;
@end
