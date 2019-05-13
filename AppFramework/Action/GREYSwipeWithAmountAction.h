//
//  GREYSwipeWithAmountAction.h
//  EarlGrey
//
//  Created by steven on 26.04.19.
//  Copyright © 2019 Quantosparks GmbH All rights reserved.
//

#import "AppFramework/Action/GREYBaseAction.h"
#import "CommonLib/GREYConstants.h"

@interface GREYSwipeWithAmountAction : GREYBaseAction

/**
 *  @remark init is not an available initializer. Use the other initializers.
 */
- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithDirection:(GREYDirection)direction
                           amount:(NSUInteger)amount
                    startPercents:(CGPoint)startPercents;

@end
