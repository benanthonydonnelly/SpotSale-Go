//
//  UISheetPresentationControllerDetent+Private.h
//  SpotSale Go
//
//  Created by Ben-Anthony Donnelly on 14/09/2022.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UISheetPresentationControllerDetent (Private)
+ (UISheetPresentationControllerDetent *)_detentWithIdentifier:(NSString *)identifier constant:(CGFloat)constant;
@end

NS_ASSUME_NONNULL_END
