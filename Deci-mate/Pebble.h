//
//  Pebble.h
//  Deci-mate
//
//  Created by Brian Ng on 7/12/15.
//  Copyright (c) 2015 Innogen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <PebbleKit/PebbleKit.h>

@interface Pebble: NSObject

@property (strong, nonatomic) PBWatch *connectedWatch;