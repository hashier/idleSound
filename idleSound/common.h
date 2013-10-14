//
//  common.h
//  Common helper stuff
//
//  Created by Christopher Loessl.
//  Copyright (c) 2013 Christopher Loessl. All rights reserved.
//

#ifndef hashier_common_h
#define hashier_common_h

#ifdef DEBUG

#define DLog(...) NSLog(@"(%@:%d %s) %@", [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__, __PRETTY_FUNCTION__, [NSString stringWithFormat:__VA_ARGS__])

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

#define IS_WIDESCREEN ( fabs( ( double )[ [ UIScreen mainScreen ] bounds ].size.height - ( double )568 ) < DBL_EPSILON )
#define IS_IPHONE ( [ [ [ UIDevice currentDevice ] model ] isEqualToString: @"iPhone" ] )
#define IS_IPOD   ( [ [ [ UIDevice currentDevice ] model ] isEqualToString: @"iPod touch" ] )
#define IS_IPHONE_5 ( IS_IPHONE && IS_WIDESCREEN )

#else
#define DLog(...)
#endif

#endif
