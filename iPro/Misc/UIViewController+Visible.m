//
//  UIView+Visible.m
//  KuaiPan
//
//  Created by zhang fan on 14-9-3.
//
//

#import "UIViewController+Visible.h"

@implementation UIViewController (Visible)

- (BOOL)visible
{
	return [self isViewLoaded] && self.view.window && !self.view.hidden;
}

@end
