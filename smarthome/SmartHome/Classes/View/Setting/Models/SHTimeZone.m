//
//  SHTimeZone.m
//  SmartHome
//
//  Created by ZJ on 2017/7/18.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import "SHTimeZone.h"

@interface SHTimeZone ()

@property (nonatomic) SHCameraObject *shCameraObj;

@property (nonatomic, strong) NSMutableArray *pacificArray;
@property (nonatomic, strong) NSMutableArray *americaArray;
@property (nonatomic, strong) NSMutableArray *antarcticaArray;
@property (nonatomic, strong) NSMutableArray *atlanticArray;
@property (nonatomic, strong) NSMutableArray *africaArray;
@property (nonatomic, strong) NSMutableArray *europeArray;
@property (nonatomic, strong) NSMutableArray *asiaArray;
@property (nonatomic, strong) NSMutableArray *indianArray;
@property (nonatomic, strong) NSMutableArray *australiaArray;

@end

@implementation SHTimeZone

- (NSMutableArray *)pacificArray {
    if (_pacificArray == nil) {
        _pacificArray = [NSMutableArray array];
    }
    
    return _pacificArray;
}

- (NSMutableArray *)americaArray {
    if (_americaArray == nil) {
        _americaArray = [NSMutableArray array];
    }
    
    return _americaArray;
}

- (NSMutableArray *)antarcticaArray {
    if (_antarcticaArray == nil) {
        _antarcticaArray = [NSMutableArray array];
    }
    
    return _antarcticaArray;
}

- (NSMutableArray *)atlanticArray {
    if (_atlanticArray == nil) {
        _atlanticArray = [NSMutableArray array];
    }
    
    return _atlanticArray;
}

- (NSMutableArray *)africaArray {
    if (_africaArray == nil) {
        _africaArray = [NSMutableArray array];
    }
    
    return _africaArray;
}

- (NSMutableArray *)europeArray {
    if (_europeArray == nil) {
        _europeArray = [NSMutableArray array];
    }
    
    return _europeArray;
}

- (NSMutableArray *)asiaArray {
    if (_asiaArray == nil) {
        _asiaArray = [NSMutableArray array];
    }
    
    return _asiaArray;
}

- (NSMutableArray *)indianArray {
    if (_indianArray == nil) {
        _indianArray = [NSMutableArray array];
    }
    
    return _indianArray;
}

- (NSMutableArray *)australiaArray {
    if (_australiaArray == nil) {
        _australiaArray = [NSMutableArray array];
    }
    
    return _australiaArray;
}

- (void)cleanArray {
    [self.pacificArray removeAllObjects];
    [self.americaArray removeAllObjects];
    [self.antarcticaArray removeAllObjects];
    [self.atlanticArray removeAllObjects];
    [self.africaArray removeAllObjects];
    [self.europeArray removeAllObjects];
    [self.asiaArray removeAllObjects];
    [self.indianArray removeAllObjects];
    [self.australiaArray removeAllObjects];
}

- (NSMutableDictionary *)timeZoneDict {
    if (_timeZoneDict == nil) {
        _timeZoneDict = [NSMutableDictionary dictionaryWithCapacity:9];
        
        [self loadTimeZone];
        
        [_timeZoneDict setObject:self.asiaArray forKey:@"Asia"];
        [_timeZoneDict setObject:self.americaArray forKey:@"America"];
        [_timeZoneDict setObject:self.africaArray forKey:@"Africa"];
        [_timeZoneDict setObject:self.atlanticArray forKey:@"Atlantic"];
        [_timeZoneDict setObject:self.australiaArray forKey:@"Australia"];
        [_timeZoneDict setObject:self.antarcticaArray forKey:@"Antarctica"];
        [_timeZoneDict setObject:self.europeArray forKey:@"Europe"];
        [_timeZoneDict setObject:self.pacificArray forKey:@"Pacific"];
        [_timeZoneDict setObject:self.indianArray forKey:@"Indian"];
    }
    
    return _timeZoneDict;
}

- (void)loadTimeZone {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"TimeZone.json" ofType:nil];
    NSData *json = [NSData dataWithContentsOfFile:path];
    NSArray *oTimeZoneArr = [NSJSONSerialization JSONObjectWithData:json options:0 error:NULL];
    
    [self cleanArray];
    
    for (NSDictionary *dict in oTimeZoneArr) {
        [self timeZoneWithDict:dict];
    }
}

- (void)timeZoneWithDict:(NSDictionary *)dict {
    NSArray *utc = dict[@"utc"];

    [utc enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj containsString:@"/"] && ![obj containsString:@"Etc"]) {
            SHTimeZone *tz = [SHTimeZone new];
            tz.offset = [dict[@"offset"] floatValue];
            tz.isdst = [dict[@"istst"] boolValue];
            tz.city = obj;
            
            NSArray *tempArr = [obj componentsSeparatedByString:@"/"];
            tz.locate = tempArr.firstObject;
            tz.detailCity = tempArr.lastObject;
            
            [self setContinentArray:tz];
        }
    }];
}

- (void)setContinentArray:(SHTimeZone *)timeZone {
    if ([timeZone.locate containsString:@"Pacific"]) {
        [self.pacificArray addObject:timeZone];
    } else if ([timeZone.locate containsString:@"America"]) {
        [self.americaArray addObject:timeZone];
    } else if ([timeZone.locate containsString:@"Antarctica"]) {
        [self.antarcticaArray addObject:timeZone];
    } else if ([timeZone.locate containsString:@"Atlantic"]) {
        [self.atlanticArray addObject:timeZone];
    } else if ([timeZone.locate containsString:@"Africa"]) {
        [self.africaArray addObject:timeZone];
    } else if ([timeZone.locate containsString:@"Europe"]) {
        [self.europeArray addObject:timeZone];
    } else if ([timeZone.locate containsString:@"Asia"]) {
        [self.asiaArray addObject:timeZone];
    } else if ([timeZone.locate containsString:@"Indian"]) {
        [self.indianArray addObject:timeZone];
    } else if ([timeZone.locate containsString:@"Australia"]) {
        [self.australiaArray addObject:timeZone];
    }
}

+ (instancetype)timeZoneWithCamera:(SHCameraObject *)cameraObj {
    SHTimeZone *tz = [[self alloc] init];
    tz.shCameraObj = cameraObj;
    
    return tz;
}

- (SHSettingData *)prepareTimeZoneData {
    NSArray *tempArray = [self prepareDetailData];
    
    SHSettingData *tzData = [[SHSettingData alloc] init];
    tzData.textLabel = NSLocalizedString(@"SETTING_TIMEZONE", nil);
    tzData.detailTextLabel = tempArray.firstObject;
    tzData.detailType = SettingDetailTypeTimeZone;
    tzData.detailData = self.timeZoneDict.allKeys;
    tzData.detailLastItem = [tempArray[1] integerValue];
    tzData.detailOriginalData = @[self.timeZoneDict, tempArray.lastObject, tempArray[2]];
    
    return tzData;
}

- (ICatchTimeZone)retrieveCurrentTimeZone {
    if (!_curResult) {
        SHGettingProperty *currentVSPro = [SHGettingProperty gettingPropertyWithControl:_shCameraObj.sdk.control];
        [currentVSPro addProperty:TRANS_PROP_CAMERA_TIME_ZONE];
        _curResult = [currentVSPro submit];
    }
    
    SHPropertyQueryResult *result = _curResult;
    
    NSString *curTimeZone = [result praseString:TRANS_PROP_CAMERA_TIME_ZONE];
    SHLogInfo(SHLogTagAPP, @"retrieveCurrentTimeZoneWithPropertyQueryResult: %@", curTimeZone);
    
	ICatchTimeZone icatchTimeZone;
    ICatchTimeZone::parseString(curTimeZone.UTF8String, icatchTimeZone);
    
    return icatchTimeZone;
}

- (NSArray *)prepareDetailData {
    __block NSString *detailString = nil;
    NSInteger detailLastItem1;
    __block NSInteger detailLastItem2;
    __block NSString *detailCity = nil;
    
    ICatchTimeZone iTZ = [self retrieveCurrentTimeZone];
    NSString *city = [NSString stringWithFormat:@"%s", iTZ.getCity().c_str()];
    if (![city isEqualToString:@"none"]) {
        NSArray *temp = [city componentsSeparatedByString:@"/"];
        NSString *key = temp.firstObject;
        detailCity = temp.lastObject;
        
        key = [key convertToCaps];
        city = [city convertToCaps];
        detailCity = [detailCity convertToCaps];
        
        detailLastItem1 = [self.timeZoneDict.allKeys indexOfObject:key];
        
        NSArray *curTZArray = self.timeZoneDict[key];
        [curTZArray enumerateObjectsUsingBlock:^(SHTimeZone *obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj.city isEqualToString:city]) {
                *stop = YES;
                detailLastItem2 = idx;
                detailString = city;
            }
        }];
    } else {
        NSString *locate = [NSString stringWithFormat:@"%s", iTZ.getLocate().c_str()];
		float timezone = std::stoi(iTZ.getTimeZone());
        //NSString *daylight = [NSString stringWithFormat:@"%s", iTZ.getDaylight().c_str()];
		float daylight = std::stoi(iTZ.getDaylight());
        
        locate = [locate convertToCaps];
//        timezone = [timezone convertToCaps];
//        daylight = [daylight convertToCaps];
		
        detailLastItem1 = [self.timeZoneDict.allKeys indexOfObject:locate];

        NSArray *curTZArray = self.timeZoneDict[locate];
        [curTZArray enumerateObjectsUsingBlock:^(SHTimeZone* obj, NSUInteger idx, BOOL * _Nonnull stop) {
//		    float tempTimeZone = [NSString stringWithFormat:@"%.1f", obj.offset];
//            float tempDaylight = [NSString stringWithFormat:@"%.1f", obj.isdst * 1.0];
			
            if (timezone == obj.offset && daylight == obj.isdst) {
                *stop = YES;
                
                ICatchTimeZone *iTimeZone = new ICatchTimeZone();
                
                iTimeZone->setCity([obj.city convertToLowercasee].UTF8String);
                iTimeZone->setLocate([locate convertToLowercasee].UTF8String);
				iTimeZone->setTimeZone(std::to_string(timezone));
                iTimeZone->setDaylight(std::to_string(daylight));
                
                SHSettingProperty *setPro = [SHSettingProperty settingPropertyWithControl:_shCameraObj.sdk.control];
                NSString *strValue = [NSString stringWithFormat:@"%s", (iTimeZone->toString()).c_str()];
                [setPro addProperty:TRANS_PROP_CAMERA_TIME_ZONE withStringValue:strValue];
                [setPro submit];
                
                detailLastItem2 = idx;
                detailString = obj.city;
                detailCity = obj.detailCity;
            }
        }];
    }
    
    if (detailString == nil) {
        detailString = @" ";
    }
    
    return @[detailString, @(detailLastItem1), @(detailLastItem2), detailCity];
}

@end
