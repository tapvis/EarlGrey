//
//  GREYSwipeWithAmountAction.m
//  EarlGrey
//
//  Created by steven on 26.04.19.
//  Copyright © 2019 Google Inc. All rights reserved.
//

#import "Action/GREYSwipeWithAmountAction.h"

#import "Action/GREYPathGestureUtils.h"
#import "Additions/NSError+GREYAdditions.h"
#import "Additions/NSObject+GREYAdditions.h"
#import "Additions/NSString+GREYAdditions.h"
#import "Assertion/GREYAssertionDefines.h"
#import "Assertion/GREYAssertions+Internal.h"
#import "Common/GREYError.h"
#import "Common/GREYThrowDefines.h"
#import "Event/GREYSyntheticEvents.h"
#import "Matcher/GREYAllOf.h"
#import "Matcher/GREYMatcher.h"
#import "Matcher/GREYMatchers.h"
#import "Matcher/GREYNot.h"

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
    self = [super initWithName:name
                   constraints:grey_allOf(grey_interactable(),
                                          grey_not(grey_systemAlertViewShown()),
                                          grey_kindOfClass([UIView class]),
                                          grey_respondsToSelector(@selector(accessibilityFrame)),
                                          nil)];
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
                [GREYAssertions grey_raiseExceptionNamed:kGREYGenericFailureException
                                        exceptionDetails:@""
                                               withError:error];
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
                            forDuration:_duration
                             expendable:YES];
    return YES;
}

@end
