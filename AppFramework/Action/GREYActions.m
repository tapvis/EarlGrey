//
// Copyright 2017 Google Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import "AppFramework/Action/GREYActions.h"

#include <mach/mach_time.h>

#import "AppFramework/Action/GREYAction.h"
#import "AppFramework/Action/GREYActionBlock.h"
#import "AppFramework/Action/GREYChangeStepperAction.h"
#import "AppFramework/Action/GREYMultiFingerSwipeAction.h"
#import "AppFramework/Action/GREYPickerAction.h"
#import "AppFramework/Action/GREYPinchAction.h"
#import "AppFramework/Action/GREYScrollAction.h"
#import "AppFramework/Action/GREYScrollToContentEdgeAction.h"
#import "AppFramework/Action/GREYSlideAction.h"
#import "AppFramework/Action/GREYSwipeAction.h"
#import "AppFramework/Action/GREYSwipeWithAmountAction.h"
#import "AppFramework/Action/GREYTapAction.h"
#import "AppFramework/Additions/NSObject+GREYApp.h"
#import "AppFramework/Additions/UISwitch+GREYApp.h"
#import "AppFramework/Core/GREYInteraction.h"
#import "AppFramework/IdlingResources/GREYUIWebViewIdlingResource.h"
#import "AppFramework/Keyboard/GREYKeyboard.h"
#import "AppFramework/Matcher/GREYAllOf.h"
#import "AppFramework/Matcher/GREYAnyOf.h"
#import "AppFramework/Matcher/GREYMatchers.h"
#import "AppFramework/Matcher/GREYNot.h"
#import "AppFramework/Synchronization/GREYSyncAPI.h"
#import "AppFramework/Synchronization/GREYUIThreadExecutor.h"
#import "CommonLib/Additions/NSObject+GREYCommon.h"
#import "CommonLib/Additions/NSString+GREYCommon.h"
#import "CommonLib/Assertion/GREYFatalAsserts.h"
#import "CommonLib/Assertion/GREYThrowDefines.h"
#import "CommonLib/Config/GREYConfiguration.h"
#import "CommonLib/Error/GREYError.h"
#import "CommonLib/Error/NSError+GREYCommon.h"
#import "CommonLib/GREYAppleInternals.h"
#import "CommonLib/Matcher/GREYMatcher.h"
#import "UILib/GREYScreenshotUtil.h"
#import "Service/Sources/EDORemoteVariable.h"

static Class gWebAccessibilityObjectWrapperClass;
static Class gAccessibilityTextFieldElementClass;

@implementation GREYActions

+ (void)initialize {
  if (self == [GREYActions class]) {
    gWebAccessibilityObjectWrapperClass = NSClassFromString(@"WebAccessibilityObjectWrapper");
    gAccessibilityTextFieldElementClass = NSClassFromString(@"UIAccessibilityTextFieldElement");
  }
}

+ (id<GREYAction>)actionForSwipeFastInDirection:(GREYDirection)direction {
  return [[GREYSwipeAction alloc] initWithDirection:direction duration:kGREYSwipeFastDuration];
}

+ (id<GREYAction>)actionForSwipeSlowInDirection:(GREYDirection)direction {
  return [[GREYSwipeAction alloc] initWithDirection:direction duration:kGREYSwipeSlowDuration];
}

+ (id<GREYAction>)actionForSwipeFastInDirection:(GREYDirection)direction
                         xOriginStartPercentage:(CGFloat)xOriginStartPercentage
                         yOriginStartPercentage:(CGFloat)yOriginStartPercentage {
  return [[GREYSwipeAction alloc]
      initWithDirection:direction
               duration:kGREYSwipeFastDuration
          startPercents:CGPointMake(xOriginStartPercentage, yOriginStartPercentage)];
}

+ (id<GREYAction>)actionForSwipeSlowInDirection:(GREYDirection)direction
                         xOriginStartPercentage:(CGFloat)xOriginStartPercentage
                         yOriginStartPercentage:(CGFloat)yOriginStartPercentage {
  return [[GREYSwipeAction alloc]
      initWithDirection:direction
               duration:kGREYSwipeSlowDuration
          startPercents:CGPointMake(xOriginStartPercentage, yOriginStartPercentage)];
}

+ (id<GREYAction>)actionForSwipeInDirection:(GREYDirection)direction
                                 withAmount:(NSUInteger)amount
                     xOriginStartPercentage:(CGFloat)xOriginStartPercentage
                     yOriginStartPercentage:(CGFloat)yOriginStartPercentage {
    return [[GREYSwipeWithAmountAction alloc] initWithDirection:direction
                                                         amount:amount
                                                  startPercents:CGPointMake(xOriginStartPercentage,
                                                                            yOriginStartPercentage)];
}

+ (id<GREYAction>)actionForMultiFingerSwipeSlowInDirection:(GREYDirection)direction
                                           numberOfFingers:(NSUInteger)numberOfFingers {
  return [[GREYMultiFingerSwipeAction alloc] initWithDirection:direction
                                                      duration:kGREYSwipeSlowDuration
                                               numberOfFingers:numberOfFingers];
}

+ (id<GREYAction>)actionForMultiFingerSwipeFastInDirection:(GREYDirection)direction
                                           numberOfFingers:(NSUInteger)numberOfFingers {
  return [[GREYMultiFingerSwipeAction alloc] initWithDirection:direction
                                                      duration:kGREYSwipeFastDuration
                                               numberOfFingers:numberOfFingers];
}

+ (id<GREYAction>)actionForMultiFingerSwipeSlowInDirection:(GREYDirection)direction
                                           numberOfFingers:(NSUInteger)numberOfFingers
                                    xOriginStartPercentage:(CGFloat)xOriginStartPercentage
                                    yOriginStartPercentage:(CGFloat)yOriginStartPercentage {
  return [[GREYMultiFingerSwipeAction alloc]
      initWithDirection:direction
               duration:kGREYSwipeSlowDuration
        numberOfFingers:numberOfFingers
          startPercents:CGPointMake(xOriginStartPercentage, yOriginStartPercentage)];
}

+ (id<GREYAction>)actionForMultiFingerSwipeFastInDirection:(GREYDirection)direction
                                           numberOfFingers:(NSUInteger)numberOfFingers
                                    xOriginStartPercentage:(CGFloat)xOriginStartPercentage
                                    yOriginStartPercentage:(CGFloat)yOriginStartPercentage {
  return [[GREYMultiFingerSwipeAction alloc]
      initWithDirection:direction
               duration:kGREYSwipeFastDuration
        numberOfFingers:numberOfFingers
          startPercents:CGPointMake(xOriginStartPercentage, yOriginStartPercentage)];
}

+ (id<GREYAction>)actionForPinchFastInDirection:(GREYPinchDirection)pinchDirection
                                      withAngle:(double)angle {
  return [[GREYPinchAction alloc] initWithDirection:pinchDirection
                                           duration:kGREYPinchFastDuration
                                         pinchAngle:angle];
}

+ (id<GREYAction>)actionForPinchSlowInDirection:(GREYPinchDirection)pinchDirection
                                      withAngle:(double)angle {
  return [[GREYPinchAction alloc] initWithDirection:pinchDirection
                                           duration:kGREYPinchSlowDuration
                                         pinchAngle:angle];
}

+ (id<GREYAction>)actionForMoveSliderToValue:(float)value {
  return [[GREYSlideAction alloc] initWithSliderValue:value];
}

+ (id<GREYAction>)actionForSetStepperValue:(double)value {
  return [[GREYChangeStepperAction alloc] initWithValue:value];
}

+ (id<GREYAction>)actionForTap {
  return [[GREYTapAction alloc] initWithType:kGREYTapTypeShort];
}

+ (id<GREYAction>)actionForTapAtPoint:(CGPoint)point {
  return [[GREYTapAction alloc] initWithType:kGREYTapTypeShort numberOfTaps:1 location:point];
}

+ (id<GREYAction>)actionForLongPress {
  return [GREYActions actionForLongPressWithDuration:kGREYLongPressDefaultDuration];
}

+ (id<GREYAction>)actionForLongPressWithDuration:(CFTimeInterval)duration {
  return [[GREYTapAction alloc] initLongPressWithDuration:duration];
}

+ (id<GREYAction>)actionForLongPressAtPoint:(CGPoint)point duration:(CFTimeInterval)duration {
  return [[GREYTapAction alloc] initLongPressWithDuration:duration location:point];
}

+ (id<GREYAction>)actionForMultipleTapsWithCount:(NSUInteger)count {
  return [[GREYTapAction alloc] initWithType:kGREYTapTypeMultiple numberOfTaps:count];
}

+ (id<GREYAction>)actionForMultipleTapsWithCount:(NSUInteger)count atPoint:(CGPoint)point {
  return
      [[GREYTapAction alloc] initWithType:kGREYTapTypeMultiple numberOfTaps:count location:point];
}

// The |amount| is in points
+ (id<GREYAction>)actionForScrollInDirection:(GREYDirection)direction amount:(CGFloat)amount {
  return [[GREYScrollAction alloc] initWithDirection:direction amount:amount];
}

+ (id<GREYAction>)actionForScrollInDirection:(GREYDirection)direction
                                      amount:(CGFloat)amount
                      xOriginStartPercentage:(CGFloat)xOriginStartPercentage
                      yOriginStartPercentage:(CGFloat)yOriginStartPercentage {
  return [[GREYScrollAction alloc]
       initWithDirection:direction
                  amount:amount
      startPointPercents:CGPointMake(xOriginStartPercentage, yOriginStartPercentage)];
}

+ (id<GREYAction>)actionForScrollToContentEdge:(GREYContentEdge)edge {
  return [[GREYScrollToContentEdgeAction alloc] initWithEdge:edge];
}

+ (id<GREYAction>)actionForScrollToContentEdge:(GREYContentEdge)edge
                        xOriginStartPercentage:(CGFloat)xOriginStartPercentage
                        yOriginStartPercentage:(CGFloat)yOriginStartPercentage {
  return [[GREYScrollToContentEdgeAction alloc]
            initWithEdge:edge
      startPointPercents:CGPointMake(xOriginStartPercentage, yOriginStartPercentage)];
}

+ (id<GREYAction>)actionForTurnSwitchOn:(BOOL)on {
  id<GREYMatcher> systemAlertShownMatcher = [GREYMatchers matcherForSystemAlertViewShown];
  NSArray *constraintMatchers = @[
    [[GREYNot alloc] initWithMatcher:systemAlertShownMatcher],
    [GREYMatchers matcherForRespondsToSelector:@selector(isOn)]
  ];
  id<GREYMatcher> constraints = [[GREYAllOf alloc] initWithMatchers:constraintMatchers];
  NSString *actionName =
      [NSString stringWithFormat:@"Turn switch to %@ state", [UISwitch grey_stringFromOnState:on]];
  return [GREYActionBlock
      actionWithName:actionName
         constraints:constraints
        performBlock:^BOOL(id switchView, __strong NSError **errorOrNil) {
          __block BOOL toggleSwitch = NO;
          grey_execute_sync_on_main_thread(^{
            toggleSwitch = ([switchView isOn] && !on) || (![switchView isOn] && on);
          });
          if (toggleSwitch) {
            id<GREYAction> longPressAction =
                [GREYActions actionForLongPressWithDuration:kGREYLongPressDefaultDuration];
            return [longPressAction perform:switchView error:errorOrNil];
          }
          return YES;
        }];
}

+ (id<GREYAction>)actionForTypeText:(NSString *)text {
  return [GREYActions grey_actionForTypeText:text atUITextPosition:nil];
}

+ (id<GREYAction>)actionForTypeText:(NSString *)text atPosition:(NSInteger)position {
  NSString *actionName =
      [NSString stringWithFormat:@"Action to type \"%@\" at position %ld", text, (long)position];
  id<GREYMatcher> protocolMatcher =
      [GREYMatchers matcherForConformsToProtocol:@protocol(UITextInput)];
  GREYPerformBlock block = ^BOOL(id element, __strong NSError **errorOrNil) {
    __block UITextPosition *textPosition;
    grey_execute_sync_on_main_thread(^{
      if (position >= 0) {
        textPosition = [element positionFromPosition:[element beginningOfDocument] offset:position];
        if (!textPosition) {
          // Text position will be nil if the computed text position is greater than the length
          // of the backing string or less than zero. Since position is positive, the computed
          // value was past the end of the text field.
          textPosition = [element endOfDocument];
        }
      } else {
        // Position is negative. -1 should map to the end of the text field.
        textPosition = [element positionFromPosition:[element endOfDocument] offset:position + 1];
        if (!textPosition) {
          // Since position is positive, the computed value was past beginning of the text
          // field.
          textPosition = [element beginningOfDocument];
        }
      }
    });

    id<GREYAction> action = [GREYActions grey_actionForTypeText:text atUITextPosition:textPosition];
    return [action perform:element error:errorOrNil];
  };
  return [GREYActionBlock actionWithName:actionName constraints:protocolMatcher performBlock:block];
}

+ (id<GREYAction>)actionForReplaceText:(NSString *)text {
  return [GREYActions grey_actionForReplaceText:text];
}

+ (id<GREYAction>)actionForClearText {
  NSArray *constraintMatchers = @[
    [GREYMatchers matcherForRespondsToSelector:@selector(text)],
    [GREYMatchers matcherForKindOfClass:gAccessibilityTextFieldElementClass],
    [GREYMatchers matcherForKindOfClass:gWebAccessibilityObjectWrapperClass],
    [GREYMatchers matcherForConformsToProtocol:@protocol(UITextInput)]
  ];
  id<GREYMatcher> constraints = [[GREYAnyOf alloc] initWithMatchers:constraintMatchers];
  return [GREYActionBlock
      actionWithName:@"Clear text"
         constraints:constraints
        performBlock:^BOOL(id element, __strong NSError **errorOrNil) {
          __block NSString *currentText;
          if ([element grey_isWebAccessibilityElement]) {
            [GREYActions grey_setText:@"" onWebElement:element];
            return YES;
          } else if ([element isKindOfClass:gAccessibilityTextFieldElementClass]) {
            element = [element textField];
          } else {
            grey_execute_sync_on_main_thread(^{
              if ([element respondsToSelector:@selector(text)]) {
                currentText = [element text];
              } else {
                UITextRange *range = [element textRangeFromPosition:[element beginningOfDocument]
                                                         toPosition:[element endOfDocument]];
                currentText = [element textInRange:range];
              }
            });
          }

          NSMutableString *deleteStr = [[NSMutableString alloc] init];
          for (NSUInteger i = 0; i < currentText.length; i++) {
            [deleteStr appendString:@"\b"];
          }

          if (deleteStr.length == 0) {
            return YES;
          } else if ([element conformsToProtocol:@protocol(UITextInput)]) {
            __block UITextPosition *endPosition;
            grey_execute_sync_on_main_thread(^{
              endPosition = [element endOfDocument];
            });
            id<GREYAction> typeAtEnd =
                [GREYActions grey_actionForTypeText:deleteStr atUITextPosition:endPosition];
            return [typeAtEnd perform:element error:errorOrNil];
          } else {
            return [[GREYActions actionForTypeText:deleteStr] perform:element error:errorOrNil];
          }
        }];
}

+ (id<GREYAction>)actionForSetDate:(NSDate *)date {
  id<GREYMatcher> systemAlertShownMatcher = [GREYMatchers matcherForSystemAlertViewShown];
  NSArray *constraintMatcher = @[
    [GREYMatchers matcherForInteractable],
    [[GREYNot alloc] initWithMatcher:systemAlertShownMatcher],
    [GREYMatchers matcherForKindOfClass:[UIDatePicker class]]
  ];
  id<GREYMatcher> constraints = [[GREYAllOf alloc] initWithMatchers:constraintMatcher];
  return [[GREYActionBlock alloc]
      initWithName:[NSString stringWithFormat:@"Set date to %@", date]
       constraints:constraints
      performBlock:^BOOL(UIDatePicker *datePicker, __strong NSError **errorOrNil) {
        grey_execute_sync_on_main_thread(^{
          NSDate *previousDate = [datePicker date];
          [datePicker setDate:date animated:YES];
          // Changing the data programmatically does not fire the "value changed" events,
          // So we have to trigger the events manually if the value changes.
          if (![date isEqualToDate:previousDate]) {
            [datePicker sendActionsForControlEvents:UIControlEventValueChanged];
          }
        });
        return YES;
      }];
}

+ (id<GREYAction>)actionForSetPickerColumn:(NSInteger)column toValue:(NSString *)value {
  return [[GREYPickerAction alloc] initWithColumn:column value:value];
}

+ (id<GREYAction>)actionForJavaScriptExecution:(NSString *)js
                                        output:(EDORemoteVariable<NSString *> *)outResult {
  // TODO: JS Errors should be propagated up.
  id<GREYMatcher> systemAlertShownMatcher = [GREYMatchers matcherForSystemAlertViewShown];
  NSArray *webViewMatchers = @[
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    // TODO: Perform a scan of UIWebView usage and deprecate if possible. // NOLINT
    [GREYMatchers matcherForKindOfClass:[UIWebView class]],
#pragma clang diagnostic pop
    [GREYMatchers matcherForKindOfClass:[WKWebView class]]
  ];
  NSArray *constraintMatchers = @[
    [[GREYNot alloc] initWithMatcher:systemAlertShownMatcher],
    [[GREYAnyOf alloc] initWithMatchers:webViewMatchers]
  ];
  id<GREYMatcher> constraints = [[GREYAllOf alloc] initWithMatchers:constraintMatchers];
  return [[GREYActionBlock alloc]
      initWithName:@"Execute JavaScript"
       constraints:constraints
      performBlock:^BOOL(id webView, __strong NSError **errorOrNil) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        if ([webView isKindOfClass:[UIWebView class]]) {
          grey_execute_sync_on_main_thread(^{
            NSString *result = [self grey_javaScriptAction:js forUIWebView:(UIWebView *)webView];
            if (outResult && result) {
              outResult.object = result;
            }
          });
        }
#pragma clang diagnostic pop
        if ([webView isKindOfClass:[WKWebView class]]) {
          dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
          __block NSError *localError = nil;
          grey_execute_sync_on_main_thread(^{
            [webView evaluateJavaScript:js
                      completionHandler:^(id result, NSError *error) {
                        if (result) {
                          // Populate the javascript result for the user to get back.
                          outResult.object = [NSString stringWithFormat:@"%@", result];
                        }
                        if (error) {
                          localError = error;
                        }
                        dispatch_semaphore_signal(semaphore);
                      }];
          });
          // Wait for the interaction timeout for the semaphore to return.
          CFTimeInterval interactionTimeout =
              GREY_CONFIG_DOUBLE(kGREYConfigKeyInteractionTimeoutDuration);
          long evaluationTimedOut = dispatch_semaphore_wait(
              semaphore,
              dispatch_time(DISPATCH_TIME_NOW, (int64_t)(interactionTimeout * NSEC_PER_SEC)));
          if (evaluationTimedOut) {
            GREYPopulateErrorOrLog(errorOrNil, kGREYInteractionErrorDomain,
                                   kGREYWKWebViewInteractionFailedErrorCode,
                                   @"Interaction with WKWebView failed because of timeout");
            return NO;
          }
          if (localError) {
            GREYPopulateErrorOrLog(errorOrNil, kGREYInteractionErrorDomain,
                                   kGREYWKWebViewInteractionFailedErrorCode,
                                   @"Interaction with WKWebView failed for an internal reason");
            return NO;
          } else {
            return YES;
          }
        }
        return YES;
      }];
}

+ (id<GREYAction>)actionForSnapshot:(EDORemoteVariable<UIImage *> *)outImage {
  GREYThrowOnNilParameter(outImage);

  return [[GREYActionBlock alloc]
      initWithName:@"Element Snapshot"
       constraints:nil
      performBlock:^BOOL(id element, __strong NSError **errorOrNil) {
        UIImage __block *snapshot = nil;
        grey_execute_sync_on_main_thread(^{
          snapshot = [GREYScreenshotUtil snapshotElement:element];
        });
        if (snapshot == nil) {
          GREYPopulateErrorOrLog(errorOrNil, kGREYInteractionErrorDomain,
                                 kGREYInteractionActionFailedErrorCode,
                                 @"Failed to take snapshot. Snapshot is nil.");
          return NO;
        } else {
          outImage.object = snapshot;
          return YES;
        }
      }];
}

#pragma mark - Private

/**
 *  Sets WebView input text value.
 *
 *  @param element The element to target
 *  @param text The text to set
 */
+ (void)grey_setText:(NSString *)text onWebElement:(id)element {
  // Input tags can be identified by having the 'title' attribute set, or current value.
  // Associating a <label> tag to the input tag does NOT result in an iOS accessibility element.
  if (!text) {
    text = @"";
  }
  // Must escape ' or the JS will be invalid.
  text = [text stringByReplacingOccurrencesOfString:@"\'" withString:@"\\\'"];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
  // TODO: Perform a scan of UIWebView usage and deprecate if possible. // NOLINT
  NSString *xPathResultType = @"XPathResult.FIRST_ORDERED_NODE_TYPE";
  NSString *xPathForTitle =
      [NSString stringWithFormat:@"//input[@title=\"%@\" or @value=\"%@\"]",
                                 [element accessibilityLabel], [element accessibilityLabel]];
  NSString *format =
      @"document.evaluate('%@', document, null, %@, null).singleNodeValue.value"
      @"= '%@';";
  NSString *jsForTitle =
      [[NSString alloc] initWithFormat:format, xPathForTitle, xPathResultType, text];
  UIWebView *parentWebView = (UIWebView *)[element grey_viewContainingSelf];
  [parentWebView stringByEvaluatingJavaScriptFromString:jsForTitle];
#pragma clang diagnostic pop
}

/**
 *  Set the UITextField text value directly, bypassing the iOS keyboard.
 *
 *  @param text The text to be typed.
 *
 *  @return @c YES if the action succeeded, else @c NO. If an action returns @c NO, it does not
 *          mean that the action was not performed at all but somewhere during the action execution
 *          the error occurred and so the UI may be in an unrecoverable state.
 */
+ (id<GREYAction>)grey_actionForReplaceText:(NSString *)text {
  SEL setTextSelector = NSSelectorFromString(@"setText:");
  NSArray *constraintMatchers = @[
    [GREYMatchers matcherForRespondsToSelector:setTextSelector],
    [GREYMatchers matcherForKindOfClass:gAccessibilityTextFieldElementClass],
    [GREYMatchers matcherForKindOfClass:gWebAccessibilityObjectWrapperClass]
  ];
  id<GREYMatcher> constraints = [[GREYAnyOf alloc] initWithMatchers:constraintMatchers];
  NSString *replaceActionName = [NSString stringWithFormat:@"Replace with text: \"%@\"", text];
  return [GREYActionBlock
      actionWithName:replaceActionName
         constraints:constraints
        performBlock:^BOOL(id element, __strong NSError **errorOrNil) {
          if ([element grey_isWebAccessibilityElement]) {
            [GREYActions grey_setText:text onWebElement:element];
          } else {
            if ([element isKindOfClass:gAccessibilityTextFieldElementClass]) {
              element = [element textField];
            }

            NSNotificationCenter *defaultCenter = NSNotificationCenter.defaultCenter;
            BOOL elementIsUIControl = [element isKindOfClass:[UIControl class]];
            BOOL elementIsUITextField = [element isKindOfClass:[UITextField class]];
            grey_execute_sync_on_main_thread(^{
              // Did begin editing notifications.
              if (elementIsUIControl) {
                [element sendActionsForControlEvents:UIControlEventEditingDidBegin];
              }

              if (elementIsUITextField) {
                NSNotification *notification =
                    [NSNotification notificationWithName:UITextFieldTextDidBeginEditingNotification
                                                  object:element];
                [defaultCenter postNotification:notification];
              }

              // Actually change the text.
              [element setText:text];

              // Did change editing notifications.
              if (elementIsUIControl) {
                [element sendActionsForControlEvents:UIControlEventEditingChanged];
              }
              if (elementIsUITextField) {
                NSNotification *notification =
                    [NSNotification notificationWithName:UITextFieldTextDidChangeNotification
                                                  object:element];
                [defaultCenter postNotification:notification];
              }

              // Did end editing notifications.
              if (elementIsUIControl) {
                [element sendActionsForControlEvents:UIControlEventEditingDidEndOnExit];
                [element sendActionsForControlEvents:UIControlEventEditingDidEnd];
              }
              if (elementIsUITextField) {
                NSNotification *notification =
                    [NSNotification notificationWithName:UITextFieldTextDidEndEditingNotification
                                                  object:element];
                [defaultCenter postNotification:notification];
              }
            });
          }
          return YES;
        }];
}

/**
 *  Performs typing in the provided element by turning off autocorrect. In case of OS versions
 *  that provide an easy API to turn off autocorrect from the settings, we do that, else we obtain
 *  the element being typed in, and turn off autocorrect for that element while being typed on.
 *
 *  @param      text           The text to be typed.
 *  @param      firstResponder The element the action is to be performed on.
 *                             This must not be @c nil.
 *  @param[out] errorOrNil     Error that will be populated on failure. The implementing class
 *                             should handle the behavior when it is @c nil by, for example,
 *                             logging the error or throwing an exception.
 *
 *  @return @c YES if the action succeeded, else @c NO. If an action returns @c NO, it does not
 *          mean that the action was not performed at all but somewhere during the action execution
 *          the error occurred and so the UI may be in an unrecoverable state.
 */
+ (BOOL)grey_disableAutoCorrectForDelegateAndTypeText:(NSString *)text
                                     inFirstResponder:(id)firstResponder
                                            withError:(__strong NSError **)errorOrNil {
  // If you're clearing the text label or if the first responder does not have an
  // autocorrectionType option then you do not need to have the autocorrect turned off.
  NSCharacterSet *set = [NSCharacterSet characterSetWithCharactersInString:@"\b"];
  if ([text stringByTrimmingCharactersInSet:set].length == 0 ||
      ![firstResponder respondsToSelector:@selector(autocorrectionType)]) {
    return [GREYKeyboard typeString:text inFirstResponder:firstResponder error:errorOrNil];
  }

  // Obtain the current delegate from the keyboard. This can only be called when the keyboard is
  // up. The original delegate has to be passed here in order to change the autocorrection type
  // since we reset the delegate in the grey_setAutocorrectionType:forIntance:
  // withOriginalKeyboardDelegate:withKeyboardToggling method in order for the autocorrection type
  // change to take effect.
  BOOL toggleKeyboard = iOS8_1_OR_ABOVE();
  id keyboardInstance = [UIKeyboardImpl sharedInstance];
  id originalKeyboardDelegate = [keyboardInstance delegate];
  UITextAutocorrectionType originalAutoCorrectionType =
      [originalKeyboardDelegate autocorrectionType];
  // For a copy of the keyboard's delegate, turn the autocorrection off. Set this copy back
  // as the delegate.
  if (toggleKeyboard) {
    [keyboardInstance hideKeyboard];
  }
  [originalKeyboardDelegate setAutocorrectionType:UITextAutocorrectionTypeNo];
  [keyboardInstance setDelegate:originalKeyboardDelegate];
  if (toggleKeyboard) {
    [keyboardInstance showKeyboard];
  }
  // Type the string in the delegate text field.
  BOOL typingResult =
      [GREYKeyboard typeString:text inFirstResponder:firstResponder error:errorOrNil];

  // Reset the keyboard delegate's autocorrection back to the original one.
  [originalKeyboardDelegate setAutocorrectionType:originalAutoCorrectionType];
  [keyboardInstance setDelegate:originalKeyboardDelegate];
  return typingResult;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
// TODO: Perform a scan of UIWebView usage and deprecate if possible. // NOLINT
/**
 *  Injects javascript into a UIWebView and then returns the result back.
 *
 *  js      An NSString for the javascript to be injected.
 *  webView The UIWebView to be interacted with.
 */
+ (NSString *)grey_javaScriptAction:(NSString *)js forUIWebView:(UIWebView *)webView {
  NSString *result;
  UIWebView *uiWebView = webView;
  result = [uiWebView stringByEvaluatingJavaScriptFromString:js];
  // TODO: Delay should be removed once webview sync is stable. // NOLINT
  [[GREYUIThreadExecutor sharedInstance] drainForTime:0.5];  // Wait for actions to register.
  return result;
}
#pragma clang diagnostic pop

#pragma mark - Package Internal

+ (id<GREYAction>)grey_actionForTypeText:(NSString *)text
                        atUITextPosition:(UITextPosition *)position {
  id<GREYMatcher> systemAlertShownMatcher = [GREYMatchers matcherForSystemAlertViewShown];
  id<GREYMatcher> actionBlockMatcher = [[GREYNot alloc] initWithMatcher:systemAlertShownMatcher];
  return [GREYActionBlock
      actionWithName:[NSString stringWithFormat:@"Type '%@'", text]
         constraints:actionBlockMatcher
        performBlock:^BOOL(id element, __strong NSError **errorOrNil) {
          __block UIView *expectedFirstResponderView;
          if (![element isKindOfClass:[UIView class]]) {
            grey_execute_sync_on_main_thread(^{
              expectedFirstResponderView = [element grey_viewContainingSelf];
            });
          } else {
            expectedFirstResponderView = element;
          }

          // If expectedFirstResponderView or one of its ancestors isn't the first responder, tap
          // on it so it becomes the first responder.
          __block BOOL elementMatched = NO;
          grey_execute_sync_on_main_thread(^{
            elementMatched = [expectedFirstResponderView isFirstResponder];
            if (!elementMatched) {
              id<GREYMatcher> firstResponderMatcher = [GREYMatchers matcherForFirstResponder];
              id<GREYMatcher> ancestorMatcher =
                  [GREYMatchers matcherForAncestor:firstResponderMatcher];
              elementMatched = [ancestorMatcher matches:expectedFirstResponderView];
            }
          });
          if (!elementMatched) {
            // Tap on the element to make expectedFirstResponderView a first responder.
            if (![[GREYActions actionForTap] perform:element error:errorOrNil]) {
              return NO;
            }
            // Wait for keyboard to show up and any other UI changes to take effect.
            if (![GREYKeyboard waitForKeyboardToAppear]) {
              NSString *description =
                  @"Keyboard did not appear after tapping on element [E]. "
                  @"Are you sure that tapping on this element will bring up the keyboard?";
              __block NSString *elementDescription;
              grey_execute_sync_on_main_thread(^{
                elementDescription = [element grey_description];
              });
              NSDictionary *glossary = @{@"E" : elementDescription};
              GREYPopulateErrorNotedOrLog(errorOrNil, kGREYInteractionErrorDomain,
                                          kGREYInteractionActionFailedErrorCode, description,
                                          glossary);
              return NO;
            }
          }

          // If a position is given, move the text cursor to that position.
          __block id firstResponder = nil;
          __block NSDictionary *errorGlossary = nil;
          grey_execute_sync_on_main_thread(^{
            firstResponder = [[expectedFirstResponderView window] firstResponder];
            if (position) {
              if ([firstResponder conformsToProtocol:@protocol(UITextInput)]) {
                UITextRange *newRange =
                    [firstResponder textRangeFromPosition:position toPosition:position];
                [firstResponder setSelectedTextRange:newRange];
              } else {
                errorGlossary = @{
                  @"F" : [firstResponder description],
                  @"E" : [expectedFirstResponderView description]
                };
              }
            }
          });

          if (errorGlossary) {
            NSString *description =
                @"First responder [F] of element [E] does not conform to @UITextInput protocol.";
            GREYPopulateErrorNotedOrLog(errorOrNil, kGREYInteractionErrorDomain,
                                        kGREYInteractionActionFailedErrorCode, description,
                                        errorGlossary);
            return NO;
          }

          if (iOS8_2_OR_ABOVE()) {
            // Directly perform the typing since for iOS8.2 and above, we directly turn off
            // Autocorrect and Predictive Typing from the settings.
            return [GREYKeyboard typeString:text inFirstResponder:firstResponder error:errorOrNil];
          } else {
            // Perform typing. If this is pre-iOS8.2, then we simply turn the autocorrection
            // off the current textfield being typed in.
            return [self grey_disableAutoCorrectForDelegateAndTypeText:text
                                                      inFirstResponder:firstResponder
                                                             withError:errorOrNil];
          }
        }];
}

@end
