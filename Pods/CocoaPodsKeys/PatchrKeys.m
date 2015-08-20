//
// Generated by CocoaPods-Keys
// on 20/08/2015
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
  
    
      char cString[44] = { PatchrKeysData[5280], PatchrKeysData[5680], PatchrKeysData[5682], PatchrKeysData[4267], PatchrKeysData[8491], PatchrKeysData[2493], PatchrKeysData[3998], PatchrKeysData[6391], PatchrKeysData[3626], PatchrKeysData[436], PatchrKeysData[955], PatchrKeysData[7078], PatchrKeysData[1065], PatchrKeysData[4060], PatchrKeysData[8834], PatchrKeysData[6059], PatchrKeysData[7646], PatchrKeysData[6017], PatchrKeysData[5428], PatchrKeysData[6750], PatchrKeysData[1933], PatchrKeysData[6417], PatchrKeysData[2406], PatchrKeysData[7235], PatchrKeysData[1437], PatchrKeysData[3795], PatchrKeysData[2420], PatchrKeysData[1471], PatchrKeysData[7667], PatchrKeysData[1042], PatchrKeysData[9181], PatchrKeysData[752], PatchrKeysData[1759], PatchrKeysData[1330], PatchrKeysData[8969], PatchrKeysData[6317], PatchrKeysData[3835], PatchrKeysData[4043], PatchrKeysData[3055], PatchrKeysData[958], PatchrKeysData[5093], PatchrKeysData[8528], PatchrKeysData[5230], '\0' };
    
    return [NSString stringWithCString:cString encoding:NSUTF8StringEncoding];
  
}

static NSString *_podKeysb2b3a4eeef502a37c4374d2cdc4b9f4f(PatchrKeys *self, SEL _cmd)
{
  
    
      char cString[33] = { PatchrKeysData[8007], PatchrKeysData[7228], PatchrKeysData[7914], PatchrKeysData[3324], PatchrKeysData[5183], PatchrKeysData[938], PatchrKeysData[448], PatchrKeysData[9275], PatchrKeysData[3038], PatchrKeysData[3182], PatchrKeysData[6402], PatchrKeysData[7431], PatchrKeysData[3341], PatchrKeysData[342], PatchrKeysData[5647], PatchrKeysData[4357], PatchrKeysData[2351], PatchrKeysData[8349], PatchrKeysData[6344], PatchrKeysData[6412], PatchrKeysData[3091], PatchrKeysData[5332], PatchrKeysData[4064], PatchrKeysData[1628], PatchrKeysData[2640], PatchrKeysData[7566], PatchrKeysData[6432], PatchrKeysData[831], PatchrKeysData[4967], PatchrKeysData[4172], PatchrKeysData[8228], PatchrKeysData[7455], '\0' };
    
    return [NSString stringWithCString:cString encoding:NSUTF8StringEncoding];
  
}

static NSString *_podKeysad40c1de013e6d4091f36a72b8bd6d59(PatchrKeys *self, SEL _cmd)
{
  
    
      char cString[37] = { PatchrKeysData[1135], PatchrKeysData[5492], PatchrKeysData[2019], PatchrKeysData[3066], PatchrKeysData[7868], PatchrKeysData[4203], PatchrKeysData[2338], PatchrKeysData[2319], PatchrKeysData[5182], PatchrKeysData[6785], PatchrKeysData[4261], PatchrKeysData[6358], PatchrKeysData[7958], PatchrKeysData[5460], PatchrKeysData[606], PatchrKeysData[8401], PatchrKeysData[6175], PatchrKeysData[5573], PatchrKeysData[9221], PatchrKeysData[1660], PatchrKeysData[3022], PatchrKeysData[7052], PatchrKeysData[3488], PatchrKeysData[1163], PatchrKeysData[2793], PatchrKeysData[3700], PatchrKeysData[3376], PatchrKeysData[4504], PatchrKeysData[7126], PatchrKeysData[4324], PatchrKeysData[942], PatchrKeysData[1825], PatchrKeysData[1620], PatchrKeysData[2613], PatchrKeysData[4223], PatchrKeysData[2370], '\0' };
    
    return [NSString stringWithCString:cString encoding:NSUTF8StringEncoding];
  
}

static NSString *_podKeyse34fa92f188be998ae3b930eacc919f8(PatchrKeys *self, SEL _cmd)
{
  
    
      char cString[21] = { PatchrKeysData[8454], PatchrKeysData[6683], PatchrKeysData[3392], PatchrKeysData[2474], PatchrKeysData[5818], PatchrKeysData[7514], PatchrKeysData[5127], PatchrKeysData[1885], PatchrKeysData[3753], PatchrKeysData[4598], PatchrKeysData[5873], PatchrKeysData[3593], PatchrKeysData[5829], PatchrKeysData[6847], PatchrKeysData[8089], PatchrKeysData[8097], PatchrKeysData[1642], PatchrKeysData[1686], PatchrKeysData[1118], PatchrKeysData[2096], '\0' };
    
    return [NSString stringWithCString:cString encoding:NSUTF8StringEncoding];
  
}

static NSString *_podKeys28e3120dfd5d3940bfdd3918b00dc7c8(PatchrKeys *self, SEL _cmd)
{
  
    
      char cString[41] = { PatchrKeysData[78], PatchrKeysData[366], PatchrKeysData[8944], PatchrKeysData[598], PatchrKeysData[2702], PatchrKeysData[3124], PatchrKeysData[2196], PatchrKeysData[2672], PatchrKeysData[2989], PatchrKeysData[1023], PatchrKeysData[1804], PatchrKeysData[5283], PatchrKeysData[4146], PatchrKeysData[364], PatchrKeysData[4901], PatchrKeysData[2172], PatchrKeysData[7498], PatchrKeysData[6965], PatchrKeysData[8951], PatchrKeysData[1715], PatchrKeysData[806], PatchrKeysData[6490], PatchrKeysData[6077], PatchrKeysData[6406], PatchrKeysData[4207], PatchrKeysData[8763], PatchrKeysData[4617], PatchrKeysData[6256], PatchrKeysData[1974], PatchrKeysData[6872], PatchrKeysData[8105], PatchrKeysData[4703], PatchrKeysData[941], PatchrKeysData[8219], PatchrKeysData[4254], PatchrKeysData[3240], PatchrKeysData[7614], PatchrKeysData[5434], PatchrKeysData[8241], PatchrKeysData[1303], '\0' };
    
    return [NSString stringWithCString:cString encoding:NSUTF8StringEncoding];
  
}

static NSString *_podKeysa8de356b4723a098354412f8d205af6c(PatchrKeys *self, SEL _cmd)
{
  
    
      char cString[41] = { PatchrKeysData[3219], PatchrKeysData[9092], PatchrKeysData[8502], PatchrKeysData[1128], PatchrKeysData[5367], PatchrKeysData[6697], PatchrKeysData[1453], PatchrKeysData[8820], PatchrKeysData[6610], PatchrKeysData[6043], PatchrKeysData[4965], PatchrKeysData[8976], PatchrKeysData[1882], PatchrKeysData[4288], PatchrKeysData[7907], PatchrKeysData[2946], PatchrKeysData[4189], PatchrKeysData[4338], PatchrKeysData[4110], PatchrKeysData[2147], PatchrKeysData[700], PatchrKeysData[5907], PatchrKeysData[5396], PatchrKeysData[7369], PatchrKeysData[1498], PatchrKeysData[3082], PatchrKeysData[5048], PatchrKeysData[3278], PatchrKeysData[5240], PatchrKeysData[9], PatchrKeysData[2551], PatchrKeysData[3682], PatchrKeysData[7887], PatchrKeysData[5927], PatchrKeysData[5577], PatchrKeysData[4804], PatchrKeysData[5241], PatchrKeysData[7440], PatchrKeysData[1556], PatchrKeysData[8806], '\0' };
    
    return [NSString stringWithCString:cString encoding:NSUTF8StringEncoding];
  
}

static NSString *_podKeys3033ac68db3f90561a6df555a9885a2e(PatchrKeys *self, SEL _cmd)
{
  
    
      char cString[41] = { PatchrKeysData[4159], PatchrKeysData[2415], PatchrKeysData[4385], PatchrKeysData[5040], PatchrKeysData[6791], PatchrKeysData[477], PatchrKeysData[777], PatchrKeysData[5755], PatchrKeysData[5911], PatchrKeysData[8074], PatchrKeysData[2760], PatchrKeysData[1966], PatchrKeysData[8627], PatchrKeysData[8355], PatchrKeysData[5253], PatchrKeysData[4118], PatchrKeysData[1551], PatchrKeysData[6212], PatchrKeysData[2752], PatchrKeysData[7809], PatchrKeysData[7949], PatchrKeysData[8650], PatchrKeysData[2568], PatchrKeysData[8690], PatchrKeysData[7077], PatchrKeysData[6267], PatchrKeysData[4724], PatchrKeysData[3665], PatchrKeysData[3422], PatchrKeysData[3832], PatchrKeysData[3826], PatchrKeysData[1126], PatchrKeysData[4127], PatchrKeysData[8543], PatchrKeysData[3155], PatchrKeysData[7733], PatchrKeysData[5251], PatchrKeysData[650], PatchrKeysData[1572], PatchrKeysData[4612], '\0' };
    
    return [NSString stringWithCString:cString encoding:NSUTF8StringEncoding];
  
}

static NSString *_podKeysad84410498465e7cde85907b4b49a875(PatchrKeys *self, SEL _cmd)
{
  
    
      char cString[41] = { PatchrKeysData[7675], PatchrKeysData[1344], PatchrKeysData[3263], PatchrKeysData[5103], PatchrKeysData[766], PatchrKeysData[7503], PatchrKeysData[7895], PatchrKeysData[55], PatchrKeysData[2017], PatchrKeysData[3937], PatchrKeysData[1765], PatchrKeysData[8073], PatchrKeysData[6986], PatchrKeysData[1248], PatchrKeysData[3441], PatchrKeysData[229], PatchrKeysData[7294], PatchrKeysData[3885], PatchrKeysData[4418], PatchrKeysData[696], PatchrKeysData[9226], PatchrKeysData[3086], PatchrKeysData[7806], PatchrKeysData[7605], PatchrKeysData[6431], PatchrKeysData[4563], PatchrKeysData[3260], PatchrKeysData[2284], PatchrKeysData[6764], PatchrKeysData[6569], PatchrKeysData[2880], PatchrKeysData[7013], PatchrKeysData[9284], PatchrKeysData[2180], PatchrKeysData[1849], PatchrKeysData[8685], PatchrKeysData[2020], PatchrKeysData[3356], PatchrKeysData[5452], PatchrKeysData[4858], '\0' };
    
    return [NSString stringWithCString:cString encoding:NSUTF8StringEncoding];
  
}

static NSString *_podKeysa0b8dbdc39d299a103febb05c63e662e(PatchrKeys *self, SEL _cmd)
{
  
    
      char cString[42] = { PatchrKeysData[8110], PatchrKeysData[7691], PatchrKeysData[7456], PatchrKeysData[8965], PatchrKeysData[8321], PatchrKeysData[2782], PatchrKeysData[7797], PatchrKeysData[5719], PatchrKeysData[2931], PatchrKeysData[4651], PatchrKeysData[2729], PatchrKeysData[4240], PatchrKeysData[4789], PatchrKeysData[6143], PatchrKeysData[2376], PatchrKeysData[245], PatchrKeysData[337], PatchrKeysData[6148], PatchrKeysData[3241], PatchrKeysData[8394], PatchrKeysData[1147], PatchrKeysData[6313], PatchrKeysData[9042], PatchrKeysData[6], PatchrKeysData[7041], PatchrKeysData[5017], PatchrKeysData[5364], PatchrKeysData[2015], PatchrKeysData[4177], PatchrKeysData[4779], PatchrKeysData[5952], PatchrKeysData[240], PatchrKeysData[8552], PatchrKeysData[550], PatchrKeysData[7313], PatchrKeysData[9124], PatchrKeysData[6551], PatchrKeysData[7845], PatchrKeysData[9012], PatchrKeysData[1865], PatchrKeysData[6629], '\0' };
    
    return [NSString stringWithCString:cString encoding:NSUTF8StringEncoding];
  
}


static char PatchrKeysData[9298] = "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_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_Dgw93EEoUTiibRNsRcecj4FCZAaNjCZiGuYuKPQYOzlju8SMbiwTWOlG2mjHCh/gFyV0vyBXYren9eEBmk4VC4X7XeMqsoHtsq+N5LCKKyNTFnjgRhA6jYFWeyFJF2o0ZEivMnY3dIiW02BN2Pe/ojCwmUA8anaMod2wPdmQZN7fu872iLUjtOedFzOLPlGAXu7Ig6MXy9Zpz3vhQkrLbf+Wp7PexUkRRb79o92DyQhrTOxAew98e0oknbtj252-CxvO1/X7jXrxp8v90WFYVevvWQfhhGKhFfbcc7Afu5nPBCmHZVAz48rqPRyTHgaDQy7qYSuLQy\\\"";

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
