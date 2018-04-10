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


+ (UIImage *)CannyEdge:(UIImage *)image;

+ (UIImage *)BilateralFilter:(UIImage *)image;

+ (UIImage *)DetectColor:(UIImage *)image;

+ (UIImage *)DetectFeatures:(UIImage *)image;


+(UIImage *)ORBMatching:(UIImage *)inputScene withTemplate:(UIImage *)inputObject withRedetect:(BOOL)redetect;

+(UIImage *)BRISKMatching:(UIImage *)inputScene withTemplate:(UIImage *)inputObject withRedetect:(BOOL)redetect;

+(UIImage *)AKAZEMatching:(UIImage *)inputScene withTemplate:(UIImage *)inputObject withRedetect:(BOOL)redetect;

+ (UIImage *)SURFMatching:(UIImage *)inputScene withTemplate:(UIImage *)inputObject withRedetect:(BOOL)redetect;



@end
