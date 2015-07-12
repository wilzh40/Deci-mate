//
//  Pebble.m
//  Deci-mate
//
//  Created by Brian Ng on 7/12/15.
//  Copyright (c) 2015 Innogen. All rights reserved.
//

#import "Pebble.h"

@implementation Pebble: NSObject

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    
    _connectedWatch = [[PBPebbleCentral defaultCentral] lastConnectedWatch];
    NSLog(@"Last connected watch: %@", self.connectedWatch);
}

@end