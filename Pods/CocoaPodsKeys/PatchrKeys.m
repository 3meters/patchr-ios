//
// Generated by CocoaPods-Keys
// on 05/10/2015
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
  
    
      char cString[44] = { PatchrKeysData[5729], PatchrKeysData[9300], PatchrKeysData[8560], PatchrKeysData[2596], PatchrKeysData[9607], PatchrKeysData[297], PatchrKeysData[20], PatchrKeysData[3172], PatchrKeysData[7370], PatchrKeysData[21], PatchrKeysData[1176], PatchrKeysData[2947], PatchrKeysData[2930], PatchrKeysData[2189], PatchrKeysData[8735], PatchrKeysData[2626], PatchrKeysData[2406], PatchrKeysData[9567], PatchrKeysData[6847], PatchrKeysData[1010], PatchrKeysData[5941], PatchrKeysData[4840], PatchrKeysData[2897], PatchrKeysData[9126], PatchrKeysData[1000], PatchrKeysData[7289], PatchrKeysData[2610], PatchrKeysData[6141], PatchrKeysData[5158], PatchrKeysData[1036], PatchrKeysData[5731], PatchrKeysData[2181], PatchrKeysData[5434], PatchrKeysData[9155], PatchrKeysData[8375], PatchrKeysData[2600], PatchrKeysData[6538], PatchrKeysData[4038], PatchrKeysData[5092], PatchrKeysData[4731], PatchrKeysData[6767], PatchrKeysData[9585], PatchrKeysData[3051], '\0' };
    
    return [NSString stringWithCString:cString encoding:NSUTF8StringEncoding];
  
}

static NSString *_podKeysb2b3a4eeef502a37c4374d2cdc4b9f4f(PatchrKeys *self, SEL _cmd)
{
  
    
      char cString[33] = { PatchrKeysData[3042], PatchrKeysData[8983], PatchrKeysData[1021], PatchrKeysData[1073], PatchrKeysData[7312], PatchrKeysData[6207], PatchrKeysData[5581], PatchrKeysData[480], PatchrKeysData[369], PatchrKeysData[3097], PatchrKeysData[1088], PatchrKeysData[5525], PatchrKeysData[6973], PatchrKeysData[607], PatchrKeysData[8408], PatchrKeysData[1886], PatchrKeysData[2992], PatchrKeysData[2310], PatchrKeysData[6555], PatchrKeysData[2268], PatchrKeysData[6889], PatchrKeysData[5073], PatchrKeysData[3746], PatchrKeysData[8313], PatchrKeysData[9661], PatchrKeysData[7987], PatchrKeysData[6030], PatchrKeysData[2302], PatchrKeysData[6582], PatchrKeysData[2895], PatchrKeysData[525], PatchrKeysData[399], '\0' };
    
    return [NSString stringWithCString:cString encoding:NSUTF8StringEncoding];
  
}

static NSString *_podKeysad40c1de013e6d4091f36a72b8bd6d59(PatchrKeys *self, SEL _cmd)
{
  
    
      char cString[37] = { PatchrKeysData[1970], PatchrKeysData[7947], PatchrKeysData[9463], PatchrKeysData[3870], PatchrKeysData[5645], PatchrKeysData[2053], PatchrKeysData[6003], PatchrKeysData[5526], PatchrKeysData[3314], PatchrKeysData[5159], PatchrKeysData[9212], PatchrKeysData[172], PatchrKeysData[3531], PatchrKeysData[2880], PatchrKeysData[3349], PatchrKeysData[2856], PatchrKeysData[4790], PatchrKeysData[2717], PatchrKeysData[4853], PatchrKeysData[9285], PatchrKeysData[2463], PatchrKeysData[2686], PatchrKeysData[895], PatchrKeysData[568], PatchrKeysData[3630], PatchrKeysData[6629], PatchrKeysData[6352], PatchrKeysData[4282], PatchrKeysData[9361], PatchrKeysData[6301], PatchrKeysData[3306], PatchrKeysData[1382], PatchrKeysData[9691], PatchrKeysData[8981], PatchrKeysData[1306], PatchrKeysData[1977], '\0' };
    
    return [NSString stringWithCString:cString encoding:NSUTF8StringEncoding];
  
}

static NSString *_podKeyse34fa92f188be998ae3b930eacc919f8(PatchrKeys *self, SEL _cmd)
{
  
    
      char cString[21] = { PatchrKeysData[5383], PatchrKeysData[1182], PatchrKeysData[275], PatchrKeysData[6356], PatchrKeysData[2584], PatchrKeysData[6212], PatchrKeysData[4968], PatchrKeysData[2762], PatchrKeysData[3248], PatchrKeysData[8828], PatchrKeysData[9125], PatchrKeysData[3657], PatchrKeysData[415], PatchrKeysData[5976], PatchrKeysData[3088], PatchrKeysData[8172], PatchrKeysData[8486], PatchrKeysData[9369], PatchrKeysData[5506], PatchrKeysData[1638], '\0' };
    
    return [NSString stringWithCString:cString encoding:NSUTF8StringEncoding];
  
}

static NSString *_podKeys28e3120dfd5d3940bfdd3918b00dc7c8(PatchrKeys *self, SEL _cmd)
{
  
    
      char cString[41] = { PatchrKeysData[4415], PatchrKeysData[8741], PatchrKeysData[3874], PatchrKeysData[4892], PatchrKeysData[4705], PatchrKeysData[8595], PatchrKeysData[7165], PatchrKeysData[76], PatchrKeysData[9522], PatchrKeysData[9106], PatchrKeysData[5636], PatchrKeysData[5907], PatchrKeysData[7978], PatchrKeysData[4728], PatchrKeysData[2601], PatchrKeysData[6130], PatchrKeysData[7292], PatchrKeysData[2407], PatchrKeysData[5123], PatchrKeysData[8710], PatchrKeysData[3147], PatchrKeysData[6610], PatchrKeysData[6818], PatchrKeysData[4263], PatchrKeysData[5231], PatchrKeysData[2690], PatchrKeysData[7474], PatchrKeysData[2747], PatchrKeysData[3093], PatchrKeysData[3443], PatchrKeysData[2035], PatchrKeysData[6503], PatchrKeysData[1172], PatchrKeysData[3436], PatchrKeysData[946], PatchrKeysData[3762], PatchrKeysData[4573], PatchrKeysData[1594], PatchrKeysData[8450], PatchrKeysData[89], '\0' };
    
    return [NSString stringWithCString:cString encoding:NSUTF8StringEncoding];
  
}

static NSString *_podKeysa8de356b4723a098354412f8d205af6c(PatchrKeys *self, SEL _cmd)
{
  
    
      char cString[41] = { PatchrKeysData[7344], PatchrKeysData[872], PatchrKeysData[3394], PatchrKeysData[1883], PatchrKeysData[1715], PatchrKeysData[7745], PatchrKeysData[4354], PatchrKeysData[8630], PatchrKeysData[3840], PatchrKeysData[2823], PatchrKeysData[5662], PatchrKeysData[4079], PatchrKeysData[8448], PatchrKeysData[9100], PatchrKeysData[6170], PatchrKeysData[4786], PatchrKeysData[7080], PatchrKeysData[4160], PatchrKeysData[2528], PatchrKeysData[9312], PatchrKeysData[4168], PatchrKeysData[4456], PatchrKeysData[4798], PatchrKeysData[3019], PatchrKeysData[3757], PatchrKeysData[8247], PatchrKeysData[9503], PatchrKeysData[1486], PatchrKeysData[7316], PatchrKeysData[839], PatchrKeysData[9037], PatchrKeysData[3119], PatchrKeysData[3363], PatchrKeysData[1090], PatchrKeysData[9461], PatchrKeysData[9496], PatchrKeysData[5291], PatchrKeysData[7206], PatchrKeysData[4005], PatchrKeysData[5418], '\0' };
    
    return [NSString stringWithCString:cString encoding:NSUTF8StringEncoding];
  
}

static NSString *_podKeys3033ac68db3f90561a6df555a9885a2e(PatchrKeys *self, SEL _cmd)
{
  
    
      char cString[41] = { PatchrKeysData[1248], PatchrKeysData[4227], PatchrKeysData[7262], PatchrKeysData[2069], PatchrKeysData[4495], PatchrKeysData[9552], PatchrKeysData[6315], PatchrKeysData[8477], PatchrKeysData[6700], PatchrKeysData[302], PatchrKeysData[239], PatchrKeysData[19], PatchrKeysData[332], PatchrKeysData[9270], PatchrKeysData[3468], PatchrKeysData[5193], PatchrKeysData[1124], PatchrKeysData[7475], PatchrKeysData[469], PatchrKeysData[2393], PatchrKeysData[7008], PatchrKeysData[329], PatchrKeysData[6456], PatchrKeysData[9057], PatchrKeysData[4011], PatchrKeysData[9268], PatchrKeysData[8721], PatchrKeysData[3267], PatchrKeysData[7478], PatchrKeysData[7039], PatchrKeysData[2225], PatchrKeysData[4368], PatchrKeysData[4276], PatchrKeysData[8598], PatchrKeysData[9645], PatchrKeysData[546], PatchrKeysData[4645], PatchrKeysData[8603], PatchrKeysData[2742], PatchrKeysData[8848], '\0' };
    
    return [NSString stringWithCString:cString encoding:NSUTF8StringEncoding];
  
}

static NSString *_podKeysad84410498465e7cde85907b4b49a875(PatchrKeys *self, SEL _cmd)
{
  
    
      char cString[41] = { PatchrKeysData[7507], PatchrKeysData[5474], PatchrKeysData[9093], PatchrKeysData[959], PatchrKeysData[5242], PatchrKeysData[5025], PatchrKeysData[931], PatchrKeysData[2759], PatchrKeysData[7840], PatchrKeysData[4601], PatchrKeysData[7286], PatchrKeysData[4496], PatchrKeysData[7803], PatchrKeysData[1934], PatchrKeysData[4663], PatchrKeysData[6078], PatchrKeysData[2865], PatchrKeysData[3542], PatchrKeysData[3407], PatchrKeysData[1377], PatchrKeysData[8357], PatchrKeysData[3362], PatchrKeysData[7726], PatchrKeysData[1022], PatchrKeysData[7848], PatchrKeysData[3854], PatchrKeysData[5207], PatchrKeysData[8929], PatchrKeysData[7159], PatchrKeysData[9656], PatchrKeysData[6243], PatchrKeysData[9064], PatchrKeysData[5980], PatchrKeysData[886], PatchrKeysData[647], PatchrKeysData[2126], PatchrKeysData[3144], PatchrKeysData[8785], PatchrKeysData[4857], PatchrKeysData[4830], '\0' };
    
    return [NSString stringWithCString:cString encoding:NSUTF8StringEncoding];
  
}

static NSString *_podKeysa0b8dbdc39d299a103febb05c63e662e(PatchrKeys *self, SEL _cmd)
{
  
    
      char cString[42] = { PatchrKeysData[7685], PatchrKeysData[2094], PatchrKeysData[553], PatchrKeysData[241], PatchrKeysData[8041], PatchrKeysData[3910], PatchrKeysData[2087], PatchrKeysData[4985], PatchrKeysData[8695], PatchrKeysData[4342], PatchrKeysData[9439], PatchrKeysData[3382], PatchrKeysData[3401], PatchrKeysData[4230], PatchrKeysData[6734], PatchrKeysData[5640], PatchrKeysData[8728], PatchrKeysData[1136], PatchrKeysData[5209], PatchrKeysData[6159], PatchrKeysData[2261], PatchrKeysData[208], PatchrKeysData[9082], PatchrKeysData[9531], PatchrKeysData[7499], PatchrKeysData[7471], PatchrKeysData[1064], PatchrKeysData[6994], PatchrKeysData[2888], PatchrKeysData[2136], PatchrKeysData[5780], PatchrKeysData[1921], PatchrKeysData[5807], PatchrKeysData[7932], PatchrKeysData[1814], PatchrKeysData[2184], PatchrKeysData[5860], PatchrKeysData[7361], PatchrKeysData[1750], PatchrKeysData[3301], PatchrKeysData[7940], '\0' };
    
    return [NSString stringWithCString:cString encoding:NSUTF8StringEncoding];
  
}


static char PatchrKeysData[9742] = "OKMKOx2N7+snGIAtDJwkZm7iUXLII6F1pg43ERz5WbUCinncQzl+rpOjLbAnv8Voq2ozuBD4COKAznUsEMaVn3aq1SRVXAUYIMwiEOBiS7wq6k8hzwBStvDPdk8UsW/VkcsrG9F5NTU+PMCh1s80MDbdta6wysdLvhrEj1bYzM231ZQuCY/OcNTFnTzsJigOC8Ab429f1knXgly6QME/duZIcRLEEbUX9p3ncELHudI3voAgm_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_949xUdKA8jp9jbWUWhsxtJFpLRC7tmx+9bjVi+KJh7gZme8lJZwy/Loqae8f00Jo4yoM05njktdruH8oSwMxItE4t0cdZ9rtfsC0U/61zmuh/uyZjkgaBgfFoKuNcpdyTAlBPBVm3LFhsn/nY4Q+6meNDSWgmZjE6d0B2aNE+plq+HICNp6mm44ZVAPYPa/SjQAFN2XaM33laqiEnQ4w2RhOfzLnyedM4uZZXdD735ccdt40PfiDBbe3yV2PoKnHfs9lHhPm3Wx5rbWfDzwcTKovswTxL0y2W0Ru3aOacKfLehSeZBvNe3Z1qA9ksKHPtL9l03nzBpriMfwwDlXA3BxulvqDDRWO5jziueo8t9X5bl3u2DQQddN+XJBUZtYdMo9TOOK80jbFd0zhzFrgsYJPUx6Ijt2SzeRNJ86rq5PXOHGEajYXBEW2gV8Ypw8kViroSIUWOdRFxgXYwphq/m9A6/ikXYbv/DoafhOwpI5qvYJmQFq+OxNwDBEnTiWrp3B21EYQTXtCO+X63VrLj02NYcEn56VWJiq6ZZhrIBC6uCZIzvKv9h6CsdniWxycJrXOxoiG0zzfoaVhYaW9EQrBbnhFN7XRItvUTOarkWz7ERqDgAFVquMiO65JKXvAlcKQDMRk6fUkrE1i3vFA4uQKbbTW+FYjk3C9f9SQ2xt8TkwRjb60tSDqaXzjqgRhXU4o+1BDRImv5PANrPOBHTaz0MUvGZDU0c/geoSaWqIRg8zAGGqlAlIK3X8edYzcYAPnT3bqObv7V5Y7T1eT+3SJAtCKu8ilx/489n+pxmxojpruDSfsx3Fws84sFmy7iHl37/3ZLyg+6mvl2h58TH4fRNRfK2BDgvEKRgTiJdQC8bUH9sVBpwvK1RrXzEkbv55QtJ+h+VmFFk0LtE2XaYS0antvCCn+WjvoeGARWtWI5rwdjSSqUdsB1EodEueHfzt+S13CuVX5y6txntIxznaMIXOKwkACaEI266QtExNFW+0Q8/UiPT2OlsrdFiNFmEi3KnLH2ag0hPgBcO8=\\\"";

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
