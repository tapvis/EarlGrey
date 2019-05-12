//
//  GREYSwipeWithAmountAction.h
//  EarlGrey
//
//  Created by steven on 26.04.19.
//  Copyright © 2019 Google Inc. All rights reserved.
//

#import <EarlGrey/GREYBaseAction.h>
#import <EarlGrey/GREYConstants.h>

NS_ASSUME_NONNULL_BEGIN

@interface GREYSwipeWithAmountAction : GREYBaseAction

/**
 *  @remark init is not an available initializer. Use the other initializers.
 */
- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithDirection:(GREYDirection)direction
                           amount:(NSUInteger)amount
                    startPercents:(CGPoint)startPercents;

@end

NS_ASSUME_NONNULL_END
