//
//  AudioMeter.h
//  
//
//  Created by Wilson Zhao on 7/11/15.
//
//

#import <Foundation/Foundation.h>

@interface AudioMeter : NSObject
- (void) initAudioMeter;
- (void) changeAccumulatorTo:(UInt32)length;
@property UInt32 accumulatorLength;


@end
