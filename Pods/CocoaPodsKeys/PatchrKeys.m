//
// Generated by CocoaPods-Keys
// on 31/07/2015
// For more information see https://github.com/orta/cocoapods-keys
//

#import <objc/runtime.h>
#import <Foundation/NSDictionary.h>
#import "PatchrKeys.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wincomplete-implementation"

@implementation PatchrKeys

#pragma clang diagnostic pop

+ (BOOL)resolveInstanceMethod:(SEL)name
{
  NSString *key = NSStringFromSelector(name);
  NSString * (*implementation)(PatchrKeys *, SEL) = NULL;

  if ([key isEqualToString:@"bingAccessKey"]) {
    implementation = _podKeysab65e9bbd339baf2a101c0c45e82610a;
  }

  if ([key isEqualToString:@"creativeSdkClientId"]) {
    implementation = _podKeysb2b3a4eeef502a37c4374d2cdc4b9f4f;
  }

  if ([key isEqualToString:@"creativeSdkClientSecret"]) {
    implementation = _podKeysad40c1de013e6d4091f36a72b8bd6d59;
  }

  if ([key isEqualToString:@"awsS3Key"]) {
    implementation = _podKeyse34fa92f188be998ae3b930eacc919f8;
  }

  if ([key isEqualToString:@"awsS3Secret"]) {
    implementation = _podKeys28e3120dfd5d3940bfdd3918b00dc7c8;
  }

  if ([key isEqualToString:@"parseApplicationId"]) {
    implementation = _podKeysa8de356b4723a098354412f8d205af6c;
  }

  if ([key isEqualToString:@"parseApplicationKey"]) {
    implementation = _podKeys3033ac68db3f90561a6df555a9885a2e;
  }

  if ([key isEqualToString:@"fabricApiKey"]) {
    implementation = _podKeysad84410498465e7cde85907b4b49a875;
  }

  if ([key isEqualToString:@"branchKey"]) {
    implementation = _podKeysa0b8dbdc39d299a103febb05c63e662e;
  }

  if (!implementation) {
    return [super resolveInstanceMethod:name];
  }

  return class_addMethod([self class], name, (IMP)implementation, "@@:");
}

static NSString *_podKeysab65e9bbd339baf2a101c0c45e82610a(PatchrKeys *self, SEL _cmd)
{
  
    
      char cString[44] = { PatchrKeysData[6414], PatchrKeysData[8441], PatchrKeysData[3464], PatchrKeysData[56], PatchrKeysData[10216], PatchrKeysData[1185], PatchrKeysData[8852], PatchrKeysData[1281], PatchrKeysData[6056], PatchrKeysData[6788], PatchrKeysData[1259], PatchrKeysData[6243], PatchrKeysData[1188], PatchrKeysData[606], PatchrKeysData[4485], PatchrKeysData[5802], PatchrKeysData[6367], PatchrKeysData[4069], PatchrKeysData[10121], PatchrKeysData[9139], PatchrKeysData[7717], PatchrKeysData[6993], PatchrKeysData[3843], PatchrKeysData[2973], PatchrKeysData[3408], PatchrKeysData[2439], PatchrKeysData[7536], PatchrKeysData[10453], PatchrKeysData[3416], PatchrKeysData[310], PatchrKeysData[1867], PatchrKeysData[2673], PatchrKeysData[10008], PatchrKeysData[8931], PatchrKeysData[6830], PatchrKeysData[5625], PatchrKeysData[1512], PatchrKeysData[6560], PatchrKeysData[3812], PatchrKeysData[1618], PatchrKeysData[10083], PatchrKeysData[10610], PatchrKeysData[882], '\0' };
    
    return [NSString stringWithCString:cString encoding:NSUTF8StringEncoding];
  
}

static NSString *_podKeysb2b3a4eeef502a37c4374d2cdc4b9f4f(PatchrKeys *self, SEL _cmd)
{
  
    
      char cString[33] = { PatchrKeysData[4818], PatchrKeysData[4612], PatchrKeysData[7566], PatchrKeysData[4166], PatchrKeysData[1200], PatchrKeysData[7911], PatchrKeysData[10787], PatchrKeysData[3532], PatchrKeysData[4367], PatchrKeysData[6633], PatchrKeysData[8019], PatchrKeysData[5486], PatchrKeysData[136], PatchrKeysData[8914], PatchrKeysData[8839], PatchrKeysData[9639], PatchrKeysData[5988], PatchrKeysData[822], PatchrKeysData[3179], PatchrKeysData[6255], PatchrKeysData[3198], PatchrKeysData[1167], PatchrKeysData[10953], PatchrKeysData[1431], PatchrKeysData[4593], PatchrKeysData[1370], PatchrKeysData[5343], PatchrKeysData[7097], PatchrKeysData[7315], PatchrKeysData[10700], PatchrKeysData[2556], PatchrKeysData[7031], '\0' };
    
    return [NSString stringWithCString:cString encoding:NSUTF8StringEncoding];
  
}

static NSString *_podKeysad40c1de013e6d4091f36a72b8bd6d59(PatchrKeys *self, SEL _cmd)
{
  
    
      char cString[37] = { PatchrKeysData[1501], PatchrKeysData[4697], PatchrKeysData[2990], PatchrKeysData[8507], PatchrKeysData[5443], PatchrKeysData[10454], PatchrKeysData[10710], PatchrKeysData[6505], PatchrKeysData[6232], PatchrKeysData[6714], PatchrKeysData[8404], PatchrKeysData[3757], PatchrKeysData[1374], PatchrKeysData[8729], PatchrKeysData[2381], PatchrKeysData[8103], PatchrKeysData[6876], PatchrKeysData[3895], PatchrKeysData[4299], PatchrKeysData[8717], PatchrKeysData[3748], PatchrKeysData[2819], PatchrKeysData[1545], PatchrKeysData[9100], PatchrKeysData[6401], PatchrKeysData[3762], PatchrKeysData[7750], PatchrKeysData[7530], PatchrKeysData[8358], PatchrKeysData[3620], PatchrKeysData[10942], PatchrKeysData[9438], PatchrKeysData[1926], PatchrKeysData[3925], PatchrKeysData[1786], PatchrKeysData[616], '\0' };
    
    return [NSString stringWithCString:cString encoding:NSUTF8StringEncoding];
  
}

static NSString *_podKeyse34fa92f188be998ae3b930eacc919f8(PatchrKeys *self, SEL _cmd)
{
  
    
      char cString[21] = { PatchrKeysData[2003], PatchrKeysData[3424], PatchrKeysData[5743], PatchrKeysData[4255], PatchrKeysData[8509], PatchrKeysData[9663], PatchrKeysData[2053], PatchrKeysData[1037], PatchrKeysData[1168], PatchrKeysData[6080], PatchrKeysData[6587], PatchrKeysData[5597], PatchrKeysData[6789], PatchrKeysData[8898], PatchrKeysData[8497], PatchrKeysData[7213], PatchrKeysData[445], PatchrKeysData[2265], PatchrKeysData[5283], PatchrKeysData[4362], '\0' };
    
    return [NSString stringWithCString:cString encoding:NSUTF8StringEncoding];
  
}

static NSString *_podKeys28e3120dfd5d3940bfdd3918b00dc7c8(PatchrKeys *self, SEL _cmd)
{
  
    
      char cString[41] = { PatchrKeysData[5868], PatchrKeysData[339], PatchrKeysData[3913], PatchrKeysData[6223], PatchrKeysData[6664], PatchrKeysData[8510], PatchrKeysData[220], PatchrKeysData[10171], PatchrKeysData[705], PatchrKeysData[10777], PatchrKeysData[7100], PatchrKeysData[1850], PatchrKeysData[3917], PatchrKeysData[1515], PatchrKeysData[4231], PatchrKeysData[10801], PatchrKeysData[3755], PatchrKeysData[8636], PatchrKeysData[8503], PatchrKeysData[1065], PatchrKeysData[4314], PatchrKeysData[683], PatchrKeysData[6043], PatchrKeysData[292], PatchrKeysData[3944], PatchrKeysData[9660], PatchrKeysData[2350], PatchrKeysData[2520], PatchrKeysData[6742], PatchrKeysData[7094], PatchrKeysData[4726], PatchrKeysData[2627], PatchrKeysData[116], PatchrKeysData[3952], PatchrKeysData[3936], PatchrKeysData[4476], PatchrKeysData[296], PatchrKeysData[4907], PatchrKeysData[2128], PatchrKeysData[10434], '\0' };
    
    return [NSString stringWithCString:cString encoding:NSUTF8StringEncoding];
  
}

static NSString *_podKeysa8de356b4723a098354412f8d205af6c(PatchrKeys *self, SEL _cmd)
{
  
    
      char cString[41] = { PatchrKeysData[10551], PatchrKeysData[6476], PatchrKeysData[8118], PatchrKeysData[1225], PatchrKeysData[2420], PatchrKeysData[1835], PatchrKeysData[5322], PatchrKeysData[6186], PatchrKeysData[2965], PatchrKeysData[5112], PatchrKeysData[4329], PatchrKeysData[5232], PatchrKeysData[10126], PatchrKeysData[8646], PatchrKeysData[9852], PatchrKeysData[1838], PatchrKeysData[6626], PatchrKeysData[6798], PatchrKeysData[2684], PatchrKeysData[1601], PatchrKeysData[8582], PatchrKeysData[4052], PatchrKeysData[7392], PatchrKeysData[6501], PatchrKeysData[2699], PatchrKeysData[10319], PatchrKeysData[6764], PatchrKeysData[9684], PatchrKeysData[2499], PatchrKeysData[8420], PatchrKeysData[2012], PatchrKeysData[10184], PatchrKeysData[3499], PatchrKeysData[8518], PatchrKeysData[3897], PatchrKeysData[7968], PatchrKeysData[249], PatchrKeysData[6718], PatchrKeysData[6009], PatchrKeysData[370], '\0' };
    
    return [NSString stringWithCString:cString encoding:NSUTF8StringEncoding];
  
}

static NSString *_podKeys3033ac68db3f90561a6df555a9885a2e(PatchrKeys *self, SEL _cmd)
{
  
    
      char cString[41] = { PatchrKeysData[10841], PatchrKeysData[8989], PatchrKeysData[7489], PatchrKeysData[8654], PatchrKeysData[1504], PatchrKeysData[8162], PatchrKeysData[1671], PatchrKeysData[10865], PatchrKeysData[8880], PatchrKeysData[3193], PatchrKeysData[3823], PatchrKeysData[7557], PatchrKeysData[3339], PatchrKeysData[2345], PatchrKeysData[2247], PatchrKeysData[6196], PatchrKeysData[240], PatchrKeysData[5270], PatchrKeysData[10354], PatchrKeysData[2908], PatchrKeysData[5767], PatchrKeysData[8737], PatchrKeysData[7899], PatchrKeysData[137], PatchrKeysData[3103], PatchrKeysData[3581], PatchrKeysData[308], PatchrKeysData[3360], PatchrKeysData[10789], PatchrKeysData[45], PatchrKeysData[719], PatchrKeysData[7691], PatchrKeysData[8771], PatchrKeysData[1875], PatchrKeysData[9612], PatchrKeysData[1483], PatchrKeysData[6533], PatchrKeysData[8744], PatchrKeysData[3842], PatchrKeysData[7500], '\0' };
    
    return [NSString stringWithCString:cString encoding:NSUTF8StringEncoding];
  
}

static NSString *_podKeysad84410498465e7cde85907b4b49a875(PatchrKeys *self, SEL _cmd)
{
  
    
      char cString[41] = { PatchrKeysData[3875], PatchrKeysData[8734], PatchrKeysData[8131], PatchrKeysData[10461], PatchrKeysData[8710], PatchrKeysData[8253], PatchrKeysData[9763], PatchrKeysData[6557], PatchrKeysData[7147], PatchrKeysData[744], PatchrKeysData[3480], PatchrKeysData[8014], PatchrKeysData[7088], PatchrKeysData[7068], PatchrKeysData[9099], PatchrKeysData[868], PatchrKeysData[8620], PatchrKeysData[1734], PatchrKeysData[7064], PatchrKeysData[770], PatchrKeysData[3381], PatchrKeysData[4624], PatchrKeysData[355], PatchrKeysData[1634], PatchrKeysData[848], PatchrKeysData[5393], PatchrKeysData[2599], PatchrKeysData[6382], PatchrKeysData[4528], PatchrKeysData[3927], PatchrKeysData[9292], PatchrKeysData[9364], PatchrKeysData[4761], PatchrKeysData[1348], PatchrKeysData[7225], PatchrKeysData[674], PatchrKeysData[7163], PatchrKeysData[5799], PatchrKeysData[7481], PatchrKeysData[381], '\0' };
    
    return [NSString stringWithCString:cString encoding:NSUTF8StringEncoding];
  
}

static NSString *_podKeysa0b8dbdc39d299a103febb05c63e662e(PatchrKeys *self, SEL _cmd)
{
  
    
      char cString[42] = { PatchrKeysData[8020], PatchrKeysData[526], PatchrKeysData[8009], PatchrKeysData[5482], PatchrKeysData[9320], PatchrKeysData[9102], PatchrKeysData[9046], PatchrKeysData[3903], PatchrKeysData[4971], PatchrKeysData[3866], PatchrKeysData[1883], PatchrKeysData[7150], PatchrKeysData[6099], PatchrKeysData[1928], PatchrKeysData[3624], PatchrKeysData[1582], PatchrKeysData[10031], PatchrKeysData[3813], PatchrKeysData[2642], PatchrKeysData[1320], PatchrKeysData[1763], PatchrKeysData[1120], PatchrKeysData[6331], PatchrKeysData[1350], PatchrKeysData[4154], PatchrKeysData[342], PatchrKeysData[10717], PatchrKeysData[2137], PatchrKeysData[8891], PatchrKeysData[8684], PatchrKeysData[2006], PatchrKeysData[2999], PatchrKeysData[3994], PatchrKeysData[3102], PatchrKeysData[2322], PatchrKeysData[2738], PatchrKeysData[2430], PatchrKeysData[10988], PatchrKeysData[10536], PatchrKeysData[3327], PatchrKeysData[11], '\0' };
    
    return [NSString stringWithCString:cString encoding:NSUTF8StringEncoding];
  
}


static char PatchrKeysData[11070] = "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_jtzsQPquCYNFqscm23lO+7kvl7xZe1uJFZmU52zGW4YX2D1oXqdXzV+P1NhIZ8F1Iim+0QRUf9kSxrhgt8dOqYn6CjlfXor9iQNOde3Zh2YFsnnUObdbRVG5Gwx4wQIJ9H/zfcn1B0CPA8dC5Xoi07Zi/g0nC710oof2/ABxPooe5xfCB37n5h2AULPEysUnbTPCJ4jHy2WWPTviFz1D+KBK+WSaxHGIesd9S0ZQgvzubEhT+0fUOR7J17uxSbuW10VuiHHb6UfK0jOZj1nbiocYkapbmBRTkYQiVdncJLBvFMP1/RZ1wmVCB+5LQxVRtT3xstgba8Eh+8PNINE9mfqlwV/BGZFX6jagtRyrzRWcNufd4Kaf/Y7+WEsjyKRW21WBEz4ywTinWuR4HKRKVyMNHyi9eWv9eyb8Bda5XWXWm/m1UFp6jvUWYnfuo7WjXuJVpo6QY7UzmWCLJVTPu/w5Rsqs1LEqzpVQpo4CCAOERZmCkTGnTxymH/D/gg_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\\\"";

- (NSString *)description
{
  return [@{
            @"bingAccessKey": self.bingAccessKey,
            @"creativeSdkClientId": self.creativeSdkClientId,
            @"creativeSdkClientSecret": self.creativeSdkClientSecret,
            @"awsS3Key": self.awsS3Key,
            @"awsS3Secret": self.awsS3Secret,
            @"parseApplicationId": self.parseApplicationId,
            @"parseApplicationKey": self.parseApplicationKey,
            @"fabricApiKey": self.fabricApiKey,
            @"branchKey": self.branchKey,
  } description];
}

- (id)debugQuickLookObject
{
  return [self description];
}

@end
