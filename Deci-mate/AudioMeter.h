//
//  AudioMeter.h
//  
//
//  Created by Wilson Zhao on 7/11/15.
//
//

#import <Foundation/Foundation.h>
@protocol AudioMeterDelegate <NSObject>
@required
- (void) newDataValue: (Float32)value;
@end

@interface AudioMeter : NSObject
- (void) initAudioMeter;
- (void) changeAccumulatorTo:(UInt32)length;
-(void) pushToDelegate: (Float32)value;

@property UInt32 accumulatorLength;
@property (nonatomic, weak) id<AudioMeterDelegate> delegate;


@end
