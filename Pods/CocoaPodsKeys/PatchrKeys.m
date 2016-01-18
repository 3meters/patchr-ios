//
// Generated by CocoaPods-Keys
// on 17/01/2016
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

  if ([key isEqualToString:@"proxibaseSecret"]) {
    implementation = _podKeys977a4e3d43d506c4c8f28dbcfc106730;
  }

  if ([key isEqualToString:@"facebookToken"]) {
    implementation = _podKeyse9c848d2566111a2e8ab97a467a8f412;
  }

  if (!implementation) {
    return [super resolveInstanceMethod:name];
  }

  return class_addMethod([self class], name, (IMP)implementation, "@@:");
}

static NSString *_podKeysab65e9bbd339baf2a101c0c45e82610a(PatchrKeys *self, SEL _cmd)
{
  
    
      char cString[44] = { PatchrKeysData[3937], PatchrKeysData[7422], PatchrKeysData[390], PatchrKeysData[4572], PatchrKeysData[11791], PatchrKeysData[9853], PatchrKeysData[9496], PatchrKeysData[10595], PatchrKeysData[4785], PatchrKeysData[11317], PatchrKeysData[3129], PatchrKeysData[8977], PatchrKeysData[10891], PatchrKeysData[6761], PatchrKeysData[5798], PatchrKeysData[172], PatchrKeysData[10403], PatchrKeysData[10535], PatchrKeysData[2963], PatchrKeysData[7834], PatchrKeysData[9849], PatchrKeysData[10104], PatchrKeysData[3778], PatchrKeysData[9263], PatchrKeysData[8597], PatchrKeysData[1439], PatchrKeysData[7833], PatchrKeysData[4287], PatchrKeysData[11055], PatchrKeysData[11276], PatchrKeysData[472], PatchrKeysData[11477], PatchrKeysData[8534], PatchrKeysData[1858], PatchrKeysData[2664], PatchrKeysData[1232], PatchrKeysData[4845], PatchrKeysData[10129], PatchrKeysData[8392], PatchrKeysData[9912], PatchrKeysData[2240], PatchrKeysData[6800], PatchrKeysData[11392], '\0' };
    
    return [NSString stringWithCString:cString encoding:NSUTF8StringEncoding];
  
}

static NSString *_podKeysb2b3a4eeef502a37c4374d2cdc4b9f4f(PatchrKeys *self, SEL _cmd)
{
  
    
      char cString[33] = { PatchrKeysData[235], PatchrKeysData[4249], PatchrKeysData[9213], PatchrKeysData[7016], PatchrKeysData[6469], PatchrKeysData[3558], PatchrKeysData[11548], PatchrKeysData[6882], PatchrKeysData[9509], PatchrKeysData[2526], PatchrKeysData[7380], PatchrKeysData[1192], PatchrKeysData[10562], PatchrKeysData[8000], PatchrKeysData[9186], PatchrKeysData[9938], PatchrKeysData[3720], PatchrKeysData[9506], PatchrKeysData[1860], PatchrKeysData[7669], PatchrKeysData[7227], PatchrKeysData[9649], PatchrKeysData[1583], PatchrKeysData[2698], PatchrKeysData[245], PatchrKeysData[2377], PatchrKeysData[2934], PatchrKeysData[6806], PatchrKeysData[8607], PatchrKeysData[9971], PatchrKeysData[11315], PatchrKeysData[4832], '\0' };
    
    return [NSString stringWithCString:cString encoding:NSUTF8StringEncoding];
  
}

static NSString *_podKeysad40c1de013e6d4091f36a72b8bd6d59(PatchrKeys *self, SEL _cmd)
{
  
    
      char cString[37] = { PatchrKeysData[1925], PatchrKeysData[3398], PatchrKeysData[7657], PatchrKeysData[6928], PatchrKeysData[11221], PatchrKeysData[6809], PatchrKeysData[3710], PatchrKeysData[7531], PatchrKeysData[4913], PatchrKeysData[4774], PatchrKeysData[518], PatchrKeysData[11867], PatchrKeysData[10983], PatchrKeysData[1143], PatchrKeysData[10979], PatchrKeysData[9792], PatchrKeysData[10173], PatchrKeysData[1929], PatchrKeysData[7858], PatchrKeysData[11071], PatchrKeysData[7078], PatchrKeysData[4933], PatchrKeysData[11104], PatchrKeysData[11766], PatchrKeysData[1721], PatchrKeysData[2591], PatchrKeysData[6328], PatchrKeysData[2079], PatchrKeysData[8635], PatchrKeysData[11718], PatchrKeysData[5228], PatchrKeysData[853], PatchrKeysData[9928], PatchrKeysData[9869], PatchrKeysData[6855], PatchrKeysData[332], '\0' };
    
    return [NSString stringWithCString:cString encoding:NSUTF8StringEncoding];
  
}

static NSString *_podKeyse34fa92f188be998ae3b930eacc919f8(PatchrKeys *self, SEL _cmd)
{
  
    
      char cString[21] = { PatchrKeysData[10515], PatchrKeysData[8379], PatchrKeysData[1656], PatchrKeysData[2848], PatchrKeysData[8142], PatchrKeysData[6881], PatchrKeysData[4160], PatchrKeysData[2758], PatchrKeysData[7294], PatchrKeysData[1224], PatchrKeysData[559], PatchrKeysData[864], PatchrKeysData[3321], PatchrKeysData[1319], PatchrKeysData[9576], PatchrKeysData[2806], PatchrKeysData[7919], PatchrKeysData[11059], PatchrKeysData[5802], PatchrKeysData[11837], '\0' };
    
    return [NSString stringWithCString:cString encoding:NSUTF8StringEncoding];
  
}

static NSString *_podKeys28e3120dfd5d3940bfdd3918b00dc7c8(PatchrKeys *self, SEL _cmd)
{
  
    
      char cString[41] = { PatchrKeysData[10382], PatchrKeysData[6682], PatchrKeysData[7321], PatchrKeysData[8987], PatchrKeysData[4660], PatchrKeysData[6377], PatchrKeysData[1204], PatchrKeysData[8119], PatchrKeysData[1373], PatchrKeysData[6867], PatchrKeysData[77], PatchrKeysData[11829], PatchrKeysData[1095], PatchrKeysData[6584], PatchrKeysData[6989], PatchrKeysData[3076], PatchrKeysData[2872], PatchrKeysData[10731], PatchrKeysData[4164], PatchrKeysData[5010], PatchrKeysData[11497], PatchrKeysData[11163], PatchrKeysData[736], PatchrKeysData[3695], PatchrKeysData[3767], PatchrKeysData[5952], PatchrKeysData[4808], PatchrKeysData[8206], PatchrKeysData[706], PatchrKeysData[11011], PatchrKeysData[3985], PatchrKeysData[287], PatchrKeysData[6788], PatchrKeysData[751], PatchrKeysData[7166], PatchrKeysData[4048], PatchrKeysData[5330], PatchrKeysData[8217], PatchrKeysData[4979], PatchrKeysData[9683], '\0' };
    
    return [NSString stringWithCString:cString encoding:NSUTF8StringEncoding];
  
}

static NSString *_podKeysa8de356b4723a098354412f8d205af6c(PatchrKeys *self, SEL _cmd)
{
  
    
      char cString[41] = { PatchrKeysData[4817], PatchrKeysData[11755], PatchrKeysData[6623], PatchrKeysData[8505], PatchrKeysData[3573], PatchrKeysData[11062], PatchrKeysData[11010], PatchrKeysData[5254], PatchrKeysData[320], PatchrKeysData[2993], PatchrKeysData[3069], PatchrKeysData[955], PatchrKeysData[7730], PatchrKeysData[4101], PatchrKeysData[4074], PatchrKeysData[3144], PatchrKeysData[8586], PatchrKeysData[5429], PatchrKeysData[11737], PatchrKeysData[9361], PatchrKeysData[1357], PatchrKeysData[10095], PatchrKeysData[8163], PatchrKeysData[1209], PatchrKeysData[5954], PatchrKeysData[1651], PatchrKeysData[3271], PatchrKeysData[6985], PatchrKeysData[11261], PatchrKeysData[10633], PatchrKeysData[1738], PatchrKeysData[1578], PatchrKeysData[590], PatchrKeysData[2839], PatchrKeysData[1733], PatchrKeysData[3217], PatchrKeysData[10439], PatchrKeysData[2225], PatchrKeysData[9691], PatchrKeysData[6627], '\0' };
    
    return [NSString stringWithCString:cString encoding:NSUTF8StringEncoding];
  
}

static NSString *_podKeys3033ac68db3f90561a6df555a9885a2e(PatchrKeys *self, SEL _cmd)
{
  
    
      char cString[41] = { PatchrKeysData[7403], PatchrKeysData[2358], PatchrKeysData[1165], PatchrKeysData[8312], PatchrKeysData[690], PatchrKeysData[11400], PatchrKeysData[7344], PatchrKeysData[5828], PatchrKeysData[3861], PatchrKeysData[11657], PatchrKeysData[2049], PatchrKeysData[4739], PatchrKeysData[7161], PatchrKeysData[1536], PatchrKeysData[5219], PatchrKeysData[6951], PatchrKeysData[6440], PatchrKeysData[4493], PatchrKeysData[9847], PatchrKeysData[1128], PatchrKeysData[1907], PatchrKeysData[11697], PatchrKeysData[5065], PatchrKeysData[9405], PatchrKeysData[3059], PatchrKeysData[11482], PatchrKeysData[7000], PatchrKeysData[4260], PatchrKeysData[8270], PatchrKeysData[3849], PatchrKeysData[8302], PatchrKeysData[11147], PatchrKeysData[2127], PatchrKeysData[5401], PatchrKeysData[7151], PatchrKeysData[9254], PatchrKeysData[2884], PatchrKeysData[4954], PatchrKeysData[4771], PatchrKeysData[1109], '\0' };
    
    return [NSString stringWithCString:cString encoding:NSUTF8StringEncoding];
  
}

static NSString *_podKeysad84410498465e7cde85907b4b49a875(PatchrKeys *self, SEL _cmd)
{
  
    
      char cString[41] = { PatchrKeysData[11822], PatchrKeysData[504], PatchrKeysData[2270], PatchrKeysData[1215], PatchrKeysData[9958], PatchrKeysData[2063], PatchrKeysData[8811], PatchrKeysData[9996], PatchrKeysData[10497], PatchrKeysData[10920], PatchrKeysData[4400], PatchrKeysData[10942], PatchrKeysData[7538], PatchrKeysData[7108], PatchrKeysData[9467], PatchrKeysData[3543], PatchrKeysData[6595], PatchrKeysData[4871], PatchrKeysData[9277], PatchrKeysData[7217], PatchrKeysData[1421], PatchrKeysData[4633], PatchrKeysData[9433], PatchrKeysData[11091], PatchrKeysData[7521], PatchrKeysData[10342], PatchrKeysData[6934], PatchrKeysData[542], PatchrKeysData[10869], PatchrKeysData[389], PatchrKeysData[5675], PatchrKeysData[2730], PatchrKeysData[6668], PatchrKeysData[4435], PatchrKeysData[8589], PatchrKeysData[1533], PatchrKeysData[7772], PatchrKeysData[224], PatchrKeysData[8239], PatchrKeysData[10350], '\0' };
    
    return [NSString stringWithCString:cString encoding:NSUTF8StringEncoding];
  
}

static NSString *_podKeysa0b8dbdc39d299a103febb05c63e662e(PatchrKeys *self, SEL _cmd)
{
  
    
      char cString[42] = { PatchrKeysData[7091], PatchrKeysData[166], PatchrKeysData[7736], PatchrKeysData[8953], PatchrKeysData[25], PatchrKeysData[3696], PatchrKeysData[8044], PatchrKeysData[748], PatchrKeysData[9891], PatchrKeysData[3502], PatchrKeysData[7346], PatchrKeysData[6782], PatchrKeysData[7823], PatchrKeysData[9569], PatchrKeysData[8020], PatchrKeysData[6950], PatchrKeysData[4150], PatchrKeysData[10573], PatchrKeysData[2061], PatchrKeysData[5434], PatchrKeysData[6895], PatchrKeysData[6177], PatchrKeysData[2236], PatchrKeysData[11760], PatchrKeysData[8719], PatchrKeysData[10338], PatchrKeysData[2635], PatchrKeysData[11224], PatchrKeysData[4007], PatchrKeysData[1268], PatchrKeysData[6949], PatchrKeysData[5930], PatchrKeysData[2511], PatchrKeysData[727], PatchrKeysData[2009], PatchrKeysData[2346], PatchrKeysData[3313], PatchrKeysData[8446], PatchrKeysData[8008], PatchrKeysData[5053], PatchrKeysData[10333], '\0' };
    
    return [NSString stringWithCString:cString encoding:NSUTF8StringEncoding];
  
}

static NSString *_podKeys977a4e3d43d506c4c8f28dbcfc106730(PatchrKeys *self, SEL _cmd)
{
  
    
      char cString[8] = { PatchrKeysData[9553], PatchrKeysData[10276], PatchrKeysData[3682], PatchrKeysData[7790], PatchrKeysData[3820], PatchrKeysData[1732], PatchrKeysData[5873], '\0' };
    
    return [NSString stringWithCString:cString encoding:NSUTF8StringEncoding];
  
}

static NSString *_podKeyse9c848d2566111a2e8ab97a467a8f412(PatchrKeys *self, SEL _cmd)
{
  
    
      char cString[49] = { PatchrKeysData[10287], PatchrKeysData[4655], PatchrKeysData[104], PatchrKeysData[7607], PatchrKeysData[2062], PatchrKeysData[8138], PatchrKeysData[4971], PatchrKeysData[3508], PatchrKeysData[9962], PatchrKeysData[2016], PatchrKeysData[5799], PatchrKeysData[10807], PatchrKeysData[9848], PatchrKeysData[11015], PatchrKeysData[2582], PatchrKeysData[9086], PatchrKeysData[6545], PatchrKeysData[7319], PatchrKeysData[11061], PatchrKeysData[1304], PatchrKeysData[11325], PatchrKeysData[10642], PatchrKeysData[1468], PatchrKeysData[9365], PatchrKeysData[11863], PatchrKeysData[9532], PatchrKeysData[2337], PatchrKeysData[3406], PatchrKeysData[7795], PatchrKeysData[8325], PatchrKeysData[8801], PatchrKeysData[5096], PatchrKeysData[11449], PatchrKeysData[6828], PatchrKeysData[342], PatchrKeysData[1380], PatchrKeysData[6849], PatchrKeysData[7307], PatchrKeysData[1828], PatchrKeysData[9945], PatchrKeysData[4553], PatchrKeysData[3633], PatchrKeysData[1540], PatchrKeysData[2915], PatchrKeysData[8954], PatchrKeysData[11450], PatchrKeysData[5238], PatchrKeysData[5723], '\0' };
    
    return [NSString stringWithCString:cString encoding:NSUTF8StringEncoding];
  
}


static char PatchrKeysData[11870] = "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_3f91QRI6am5wO5+g5UImM4e/QF//TKAam87uu+OnBf5mpdRvRnqfhE3hAt3eewtcGkryh6enUmgkpcYAb6VpYdBmtZVR/dis7wSFRJpGycynveJu6m201S8N+Bdit6a1P2Sa|pi214p+VVXzHuUhWZl5B0x3xjGijkH3Yrt56M27EPkJ42pmWL3fxU2ItcUihPlGS3++TDwuWtZysoxZTfO9IRlfYo9aKqSc6KiW4o8998aABMKABgxCtyHRAFXGkpi4EiMi4/D3ILsLIoZFIk5jOPCt6s8e+kfbmudbgw5CplmCNUwbPGisErQT2dv8rtgbWKGlAsNqiq54R7hzIl4Yu8ekhaPyqm847XGQ2L5J27sUQcmazBUgiLqmAOG+YNLHvM+mQlRh8GI3rf9WMXCkuXG5eaVwf4DpKnmd2JMf2McXw3b05DqwFbhRGGg2uyN9VE4fjvebFg8Oa1hiW70zyXFcNto31HNwROx3n9ASKJoOOnD9wd47Sv5QxswEV5U0s0jdx7QFr0f7dkml/MBNAonI/7Zsy4JZ6+sN7PC4Rh+j9W/wAxWT/zhXB3TTJEbJdX0Wsur/Rrg+B9OMypXlX+yYCZmNP63M4ZgfHqVrcxOP1ALU8UXFo9xUGQSFQZRTZySJC1M16L76bsQZZXNERRUTpyOSLIr8aKgU9O4xhvtNLtUVt2ccqpYVywSUlKL3F07KsGgF90hzrwwB0GKAhSkY7JR2jtwxE4iSP2g7n1orwQ09Fw4KKeERGd8DujbG0RsqmXaYrKR2xJFkqQLRO3BPpzvOAeYV8unjwR6hhY9/cTtIpOnfhUWdy1CFpH+VTnc6kUoWtUsQtApsn1QcgdZ6o3NG/SzQHaCzrQn3NSYTB20ChB4vEZdC7Y6q17ppfBXgZBrsVdxHD9e0ofcD3/rgRuSF8M72x9Avm_R6B3LUIdk5imiveyYsPGhH6Wb6UXx8ojGItX2m2axLxeK91xRlil38PrviNtOKV6hSeTxy7eQh54TUP9nZ2CG86bU89HtWwEKZftsVRT92MGdwzZCWJuQ/vBWDB9USXVj9FkZuHIHUc1Bq6hh5qKAzEilT9yidKkkQzgT+Q95UV2g+vwUgmCA48843M024wg3ubrdCT0ilz3iNap/HQU+qnZxRetQ3bwXP58Gfh3g8YPrdMt0/Ya9gNVqZFi0lH4+YYoEiEFHWzYEgWtUJFH8M6NA65DSaeFQQMEvJtNM3UjVfRV2/rSjXi6nFlpgU3LQ9HNlHd944UbRtZDVHaTORO65Y8o7DPi8WdOB4Mz2dnmH16efBQ04Jy1Y8y7DS0ta1furgM72KA8FWbZ9oqSP8E6TxjfixBw47wDvLfUV2d1syfW+oJYXtHyc3bbUH2ld1ddOI3cne72r9sm8djfbXTWULoe0Pp3PA+PL1U2e8+TJlaG4PNsy0M4I864OOBD5RDin5yKrJ0RPQZNzY4kNHr6BvbNgkVYvGZo7AH79YuwLRsuINj0VdWEN3oX9ZAebIPvFYUZlrt5iJbXjpCqE5PEVC9zW15ERTGGYD2O5WLrz5fA0YxW8BNINRcWLo4+RI2iyv3DGiMSewGcjc1ZR4mY6Q+EEs4zyyF04RGBru/MEZ5pDcwErCGk9RRIzepdlACozNrdeRBLvY1woaU2gKLS9RHLzl6mvDA45AVQ3CfBazesgH2EsgbAGMIG9bg1eX1jPujBHczRjJNRuRSZvD8uqtGA3w9bNziyjHJ2dWYQjD5RWaDoP31VNTqKTaBL48IpuO2e1uW79ulcRndwWvRhGuQy9m59pAwKXUieK8/RJo54CFV8PRKcGLrTBWd8efW0hVQKU6DhmcQ/RVS9sXn36rJdyAs/91kt/l2ijfS5X67KUxxVHL/8Rn9P3VbXda2lIyPpXB2j9CanBenu1XjqMV/9bRk5pRd+3y5cDAVrR3AJBehIEQJSPGxrlHqkuOKwfPUYN9ap+krp9Cc7Kw1q9QdOAOgSr4l7eAyZzXGjofEbR4ufkDPYwI/EL2P4/QGdXk0QLPbg1u++C331zUg3nW8hUYFQm+l7jdZjKKSkHB4eszniDNaAGzJcHzdmOmRL62vTaOI7IDr3Z549emZYiZ9aLFZXKwRCPHNOsqVSck79oVUlvBTHOx+f4b3ekYI+YAnsaDT8EpHLGceUrBOOiBtzGBStpB0/U5qCa9TFIleRlVAjOSutqUdWSpHQovmodQwpq9Hfwoy4DcZH8xWiLrIBolxUhI71+F6nyXz43jVLa5f9z/G3f9kRyNrraRj0XhCyWs1GhCIe8CkyZARoh7piIAiukyhQdj/mny/PloRrEBk9WM9zFh8ULy41ZeIO9YgvndSO0gUd1mMqDkhnmdGeuTjFSZevG/wVZt2PGuPn1cT0F9Q9HVzMNxPgANuKh9xF31p7tvP2OBl1e4pTkoskgRxsDl8tRi0LLV/rHhHtFaEz2R5cAiOuhJZvN2b9kH9mgh0aruopxkEi2derr/l35E+N2IExfCh/ewfDj9MvP+inVVWxEa2Xziyra1+/piqikuU6ukiwJ9ytufIp+FT4XSVSsc1CSDoa6s3+Qgucf22xMVBFfthra9cS4zzWJLfgkqSkyqic0LvdnhWrNPnqw+y7BAfvKQ3DocwlnAgImZj3hbICKO1TKtx/S7Se0r0M+P1qQFffc5o8GzjFG/LdwsZhhOFxq7TR8IhWK/ATcnf7WSKEJXWCJ/Y1xGrhlHTr2egQeTUeQRcfD2w8r61h9bYvE4a+ovF4omvE+WZMP+efDC4Fs2NShF1gBH5GZkfofw+23DFvjX-Uonx7gQv79EQOswK9zrOarPXLYih37sVxv0OPgHkrnNo9iMq//GaZk33APArQWPHo2F1dZAcBJCydthO3OXhsbE2fNjl1u0YbKtH1\\\"";

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
            @"proxibaseSecret": self.proxibaseSecret,
            @"facebookToken": self.facebookToken,
  } description];
}

- (id)debugQuickLookObject
{
  return [self description];
}

@end
