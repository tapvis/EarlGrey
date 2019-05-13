//
//  GREYSwipeWithAmountAction.m
//  EarlGrey
//
//  Created by steven on 26.04.19.
//  Copyright © 2019 Quantosparks GmbH All rights reserved.
//

#import "AppFramework/Action/GREYSwipeWithAmountAction.h"

#import "AppFramework/Action/GREYPathGestureUtils.h"
#import "AppFramework/Additions/NSException+GREYApp.h"
#import "AppFramework/Additions/NSObject+GREYApp.h"
#import "AppFramework/Error/GREYAppFailureHandler.h"
#import "AppFramework/Event/GREYSyntheticEvents.h"
#import "AppFramework/Matcher/GREYAllOf.h"
#import "AppFramework/Matcher/GREYMatchers.h"
#import "AppFramework/Matcher/GREYNot.h"
#import "AppFramework/Synchronization/GREYSyncAPI.h"
#import "CommonLib/Additions/NSObject+GREYCommon.h"
#import "CommonLib/Additions/NSString+GREYCommon.h"
#import "CommonLib/Assertion/GREYThrowDefines.h"
#import "CommonLib/Error/GREYError.h"
#import "CommonLib/Error/GREYErrorConstants.h"
#import "CommonLib/Error/NSError+GREYCommon.h"
#import "CommonLib/Exceptions/GREYFrameworkException.h"

@interface GREYPathGestureUtils (Internal)
+ (NSArray *)grey_touchPathWithStartPoint:(CGPoint)startPoint
                                 endPoint:(CGPoint)endPoint
                                 duration:(CFTimeInterval)duration
                      shouldCancelInertia:(BOOL)cancelInertia;
@end

//MARK: -

@implementation GREYSwipeWithAmountAction {
    /**
     *  The direction in which the content must be scrolled.
     */
    GREYDirection _direction;
    /**
     *  The duration within which the swipe action must be complete.
     */
    CFTimeInterval _duration;
    
    /**
     *  The amount of points that will be swiped. (The "length" of the swipe)
     */
    NSUInteger _amount;
    /**
     *  Start point for the swipe specified as percentage of swipped element's accessibility frame.
     */
    CGPoint _startPercents;
}

- (instancetype)initWithDirection:(GREYDirection)direction
                           amount:(NSUInteger)amount
                    startPercents:(CGPoint)startPercents {
    
    GREYThrowOnFailedConditionWithMessage(startPercents.x > 0.0f && startPercents.x < 1.0f,
                                          @"xOriginStartPercentage must be between 0 and 1, "
                                          @"exclusively");
    GREYThrowOnFailedConditionWithMessage(startPercents.y > 0.0f && startPercents.y < 1.0f,
                                          @"yOriginStartPercentage must be between 0 and 1, "
                                          @"exclusively");
    
    NSString *name =
        [NSString stringWithFormat:@"Swipe %@ with amount %lu",
         NSStringFromGREYDirection(direction),
         (unsigned long)amount];
    id<GREYMatcher> systemAlertShownMatcher = [GREYMatchers matcherForSystemAlertViewShown];
    NSArray *constraintMatchers = @[
                                    [GREYMatchers matcherForInteractable],
                                    [[GREYNot alloc] initWithMatcher:systemAlertShownMatcher],
                                    [GREYMatchers matcherForKindOfClass:[UIView class]],
                                    [GREYMatchers matcherForRespondsToSelector:@selector(accessibilityFrame)],
                                    ];
    self = [super initWithName:name constraints:[[GREYAllOf alloc] initWithMatchers:constraintMatchers]];
    if (self) {
        _duration = 0.5;
        _direction = direction;
        _amount = amount;
        _startPercents = startPercents;
    }
    return self;
}

#pragma mark - GREYAction

- (BOOL)perform:(id)element error:(__strong NSError **)errorOrNil {
    if (![self satisfiesConstraintsForElement:element error:errorOrNil]) {
        return NO;
    }
    
    UIWindow *window = [element window];
    if (!window) {
        if ([element isKindOfClass:[UIWindow class]]) {
            window = (UIWindow *)element;
        } else {
            NSString *errorDescription =
            [NSString stringWithFormat:@"Cannot swipe on view [V], as it has no window and "
             @"it isn't a window itself."];
            NSDictionary *glossary = @{ @"V" : [element grey_description]};
            GREYError *error;
            error = GREYErrorMake(kGREYSyntheticEventInjectionErrorDomain,
                                  kGREYOrientationChangeFailedErrorCode,
                                  errorDescription);
            error.descriptionGlossary = glossary;
            if (errorOrNil) {
                *errorOrNil = error;
            } else {
                [NSException grey_raise:kGREYGenericFailureException withError:error];
            }
            
            return NO;
        }
    }
    
    CGRect accessibilityFrame = [element accessibilityFrame];
    CGRect screenFrame = [window convertRect:[[UIScreen mainScreen] bounds] toWindow:nil];
    
    CGFloat startX = accessibilityFrame.origin.x + accessibilityFrame.size.width * _startPercents.x;
    CGFloat startY = accessibilityFrame.origin.y + accessibilityFrame.size.height * _startPercents.y;
    
    //startX and startY might be outside the screen.
    //Since touchpath is not created if it starts outside the screen,
    //we let it start inside the screen
    CGPoint startPoint =
    CGPointMake(MIN(startX, screenFrame.size.width-1),
                MIN(startY, screenFrame.size.height-1));
    
    CGPoint endPoint = startPoint;
    switch (_direction) {
        case kGREYDirectionLeft:  endPoint = CGPointMake(startPoint.x - _amount, startPoint.y); break;
        case kGREYDirectionRight: endPoint = CGPointMake(startPoint.x + _amount, startPoint.y); break;
        case kGREYDirectionUp:    endPoint = CGPointMake(startPoint.x, startPoint.y - _amount); break;
        case kGREYDirectionDown:  endPoint = CGPointMake(startPoint.x, startPoint.y + _amount); break;
    }
    
    NSArray *touchPath = [GREYPathGestureUtils grey_touchPathWithStartPoint:startPoint
                                                                   endPoint:endPoint
                                                                   duration:_duration
                                                        shouldCancelInertia:NO];
        
    
    [GREYSyntheticEvents touchAlongPath:touchPath
                       relativeToWindow:window
                            forDuration:_duration];
    return YES;
}

@end
