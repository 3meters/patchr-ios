//
// Generated by CocoaPods-Keys
// on 29/07/2015
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
  
    
      char cString[44] = { PatchrKeysData[6839], PatchrKeysData[455], PatchrKeysData[642], PatchrKeysData[6151], PatchrKeysData[6106], PatchrKeysData[5223], PatchrKeysData[6495], PatchrKeysData[7849], PatchrKeysData[6707], PatchrKeysData[5362], PatchrKeysData[8414], PatchrKeysData[5236], PatchrKeysData[7674], PatchrKeysData[5641], PatchrKeysData[9275], PatchrKeysData[5317], PatchrKeysData[1617], PatchrKeysData[1892], PatchrKeysData[5481], PatchrKeysData[3775], PatchrKeysData[9008], PatchrKeysData[3705], PatchrKeysData[1459], PatchrKeysData[1716], PatchrKeysData[8591], PatchrKeysData[8319], PatchrKeysData[8992], PatchrKeysData[8280], PatchrKeysData[150], PatchrKeysData[9570], PatchrKeysData[2103], PatchrKeysData[2909], PatchrKeysData[628], PatchrKeysData[8820], PatchrKeysData[2695], PatchrKeysData[5843], PatchrKeysData[4817], PatchrKeysData[8547], PatchrKeysData[5757], PatchrKeysData[6903], PatchrKeysData[9627], PatchrKeysData[5324], PatchrKeysData[6069], '\0' };
    
    return [NSString stringWithCString:cString encoding:NSUTF8StringEncoding];
  
}

static NSString *_podKeysb2b3a4eeef502a37c4374d2cdc4b9f4f(PatchrKeys *self, SEL _cmd)
{
  
    
      char cString[33] = { PatchrKeysData[7122], PatchrKeysData[477], PatchrKeysData[7683], PatchrKeysData[2434], PatchrKeysData[2], PatchrKeysData[4481], PatchrKeysData[1605], PatchrKeysData[3270], PatchrKeysData[5990], PatchrKeysData[7651], PatchrKeysData[884], PatchrKeysData[5507], PatchrKeysData[1777], PatchrKeysData[5485], PatchrKeysData[6098], PatchrKeysData[7231], PatchrKeysData[5169], PatchrKeysData[2284], PatchrKeysData[5303], PatchrKeysData[9396], PatchrKeysData[3530], PatchrKeysData[2831], PatchrKeysData[6144], PatchrKeysData[7523], PatchrKeysData[6209], PatchrKeysData[5768], PatchrKeysData[212], PatchrKeysData[519], PatchrKeysData[9551], PatchrKeysData[63], PatchrKeysData[2234], PatchrKeysData[4189], '\0' };
    
    return [NSString stringWithCString:cString encoding:NSUTF8StringEncoding];
  
}

static NSString *_podKeysad40c1de013e6d4091f36a72b8bd6d59(PatchrKeys *self, SEL _cmd)
{
  
    
      char cString[37] = { PatchrKeysData[908], PatchrKeysData[380], PatchrKeysData[8732], PatchrKeysData[4536], PatchrKeysData[8765], PatchrKeysData[3228], PatchrKeysData[8118], PatchrKeysData[4026], PatchrKeysData[9154], PatchrKeysData[6813], PatchrKeysData[895], PatchrKeysData[619], PatchrKeysData[9420], PatchrKeysData[3085], PatchrKeysData[2499], PatchrKeysData[9095], PatchrKeysData[8297], PatchrKeysData[9319], PatchrKeysData[934], PatchrKeysData[396], PatchrKeysData[7988], PatchrKeysData[5636], PatchrKeysData[7165], PatchrKeysData[3604], PatchrKeysData[8195], PatchrKeysData[1401], PatchrKeysData[6322], PatchrKeysData[6995], PatchrKeysData[3923], PatchrKeysData[1059], PatchrKeysData[6078], PatchrKeysData[4508], PatchrKeysData[4472], PatchrKeysData[7505], PatchrKeysData[7037], PatchrKeysData[9525], '\0' };
    
    return [NSString stringWithCString:cString encoding:NSUTF8StringEncoding];
  
}

static NSString *_podKeyse34fa92f188be998ae3b930eacc919f8(PatchrKeys *self, SEL _cmd)
{
  
    
      char cString[21] = { PatchrKeysData[5690], PatchrKeysData[7700], PatchrKeysData[2671], PatchrKeysData[6501], PatchrKeysData[3385], PatchrKeysData[8497], PatchrKeysData[2420], PatchrKeysData[8824], PatchrKeysData[9098], PatchrKeysData[2759], PatchrKeysData[1238], PatchrKeysData[2672], PatchrKeysData[8148], PatchrKeysData[9126], PatchrKeysData[2267], PatchrKeysData[2355], PatchrKeysData[8199], PatchrKeysData[397], PatchrKeysData[704], PatchrKeysData[1213], '\0' };
    
    return [NSString stringWithCString:cString encoding:NSUTF8StringEncoding];
  
}

static NSString *_podKeys28e3120dfd5d3940bfdd3918b00dc7c8(PatchrKeys *self, SEL _cmd)
{
  
    
      char cString[41] = { PatchrKeysData[4882], PatchrKeysData[805], PatchrKeysData[423], PatchrKeysData[6871], PatchrKeysData[7079], PatchrKeysData[1516], PatchrKeysData[1591], PatchrKeysData[6748], PatchrKeysData[6449], PatchrKeysData[6519], PatchrKeysData[821], PatchrKeysData[2775], PatchrKeysData[6765], PatchrKeysData[3830], PatchrKeysData[3903], PatchrKeysData[2431], PatchrKeysData[2298], PatchrKeysData[6083], PatchrKeysData[2133], PatchrKeysData[4630], PatchrKeysData[7057], PatchrKeysData[2107], PatchrKeysData[8985], PatchrKeysData[2846], PatchrKeysData[1898], PatchrKeysData[6264], PatchrKeysData[4043], PatchrKeysData[223], PatchrKeysData[5856], PatchrKeysData[2321], PatchrKeysData[6262], PatchrKeysData[1097], PatchrKeysData[911], PatchrKeysData[4641], PatchrKeysData[9681], PatchrKeysData[9368], PatchrKeysData[7298], PatchrKeysData[8240], PatchrKeysData[1633], PatchrKeysData[722], '\0' };
    
    return [NSString stringWithCString:cString encoding:NSUTF8StringEncoding];
  
}

static NSString *_podKeysa8de356b4723a098354412f8d205af6c(PatchrKeys *self, SEL _cmd)
{
  
    
      char cString[41] = { PatchrKeysData[6858], PatchrKeysData[255], PatchrKeysData[6337], PatchrKeysData[368], PatchrKeysData[8925], PatchrKeysData[4728], PatchrKeysData[6906], PatchrKeysData[3133], PatchrKeysData[6187], PatchrKeysData[3468], PatchrKeysData[833], PatchrKeysData[9456], PatchrKeysData[3682], PatchrKeysData[4286], PatchrKeysData[1833], PatchrKeysData[1431], PatchrKeysData[4013], PatchrKeysData[764], PatchrKeysData[4546], PatchrKeysData[1879], PatchrKeysData[7129], PatchrKeysData[8602], PatchrKeysData[4150], PatchrKeysData[5536], PatchrKeysData[465], PatchrKeysData[3164], PatchrKeysData[2610], PatchrKeysData[6557], PatchrKeysData[8412], PatchrKeysData[6660], PatchrKeysData[905], PatchrKeysData[3546], PatchrKeysData[7575], PatchrKeysData[1235], PatchrKeysData[554], PatchrKeysData[5385], PatchrKeysData[7196], PatchrKeysData[2019], PatchrKeysData[4283], PatchrKeysData[3882], '\0' };
    
    return [NSString stringWithCString:cString encoding:NSUTF8StringEncoding];
  
}

static NSString *_podKeys3033ac68db3f90561a6df555a9885a2e(PatchrKeys *self, SEL _cmd)
{
  
    
      char cString[41] = { PatchrKeysData[7086], PatchrKeysData[4227], PatchrKeysData[336], PatchrKeysData[2559], PatchrKeysData[2243], PatchrKeysData[5800], PatchrKeysData[9204], PatchrKeysData[717], PatchrKeysData[6595], PatchrKeysData[3992], PatchrKeysData[1938], PatchrKeysData[3166], PatchrKeysData[3259], PatchrKeysData[2525], PatchrKeysData[7665], PatchrKeysData[7444], PatchrKeysData[7109], PatchrKeysData[8252], PatchrKeysData[3896], PatchrKeysData[5961], PatchrKeysData[6767], PatchrKeysData[7555], PatchrKeysData[4069], PatchrKeysData[1169], PatchrKeysData[3813], PatchrKeysData[8853], PatchrKeysData[1630], PatchrKeysData[9225], PatchrKeysData[7653], PatchrKeysData[3038], PatchrKeysData[3699], PatchrKeysData[5451], PatchrKeysData[1026], PatchrKeysData[932], PatchrKeysData[7934], PatchrKeysData[9067], PatchrKeysData[4058], PatchrKeysData[7795], PatchrKeysData[2223], PatchrKeysData[1876], '\0' };
    
    return [NSString stringWithCString:cString encoding:NSUTF8StringEncoding];
  
}

static NSString *_podKeysad84410498465e7cde85907b4b49a875(PatchrKeys *self, SEL _cmd)
{
  
    
      char cString[41] = { PatchrKeysData[2324], PatchrKeysData[6175], PatchrKeysData[4514], PatchrKeysData[4140], PatchrKeysData[4659], PatchrKeysData[3873], PatchrKeysData[8129], PatchrKeysData[4148], PatchrKeysData[886], PatchrKeysData[7589], PatchrKeysData[9670], PatchrKeysData[2334], PatchrKeysData[2147], PatchrKeysData[7249], PatchrKeysData[3533], PatchrKeysData[4982], PatchrKeysData[7183], PatchrKeysData[282], PatchrKeysData[2277], PatchrKeysData[8734], PatchrKeysData[7450], PatchrKeysData[2879], PatchrKeysData[7173], PatchrKeysData[4607], PatchrKeysData[7979], PatchrKeysData[7517], PatchrKeysData[2571], PatchrKeysData[495], PatchrKeysData[1660], PatchrKeysData[6019], PatchrKeysData[3091], PatchrKeysData[3104], PatchrKeysData[4437], PatchrKeysData[5769], PatchrKeysData[3308], PatchrKeysData[4825], PatchrKeysData[1133], PatchrKeysData[3060], PatchrKeysData[7473], PatchrKeysData[69], '\0' };
    
    return [NSString stringWithCString:cString encoding:NSUTF8StringEncoding];
  
}

static NSString *_podKeysa0b8dbdc39d299a103febb05c63e662e(PatchrKeys *self, SEL _cmd)
{
  
    
      char cString[42] = { PatchrKeysData[3696], PatchrKeysData[4492], PatchrKeysData[2674], PatchrKeysData[4854], PatchrKeysData[7738], PatchrKeysData[6385], PatchrKeysData[694], PatchrKeysData[6904], PatchrKeysData[5431], PatchrKeysData[2822], PatchrKeysData[4510], PatchrKeysData[8115], PatchrKeysData[9252], PatchrKeysData[7776], PatchrKeysData[6970], PatchrKeysData[888], PatchrKeysData[5355], PatchrKeysData[6255], PatchrKeysData[1788], PatchrKeysData[4184], PatchrKeysData[5498], PatchrKeysData[5737], PatchrKeysData[4360], PatchrKeysData[2832], PatchrKeysData[6523], PatchrKeysData[5458], PatchrKeysData[5440], PatchrKeysData[7246], PatchrKeysData[1565], PatchrKeysData[9511], PatchrKeysData[8381], PatchrKeysData[6395], PatchrKeysData[3967], PatchrKeysData[1058], PatchrKeysData[4309], PatchrKeysData[9541], PatchrKeysData[7538], PatchrKeysData[3190], PatchrKeysData[1574], PatchrKeysData[7615], PatchrKeysData[8510], '\0' };
    
    return [NSString stringWithCString:cString encoding:NSUTF8StringEncoding];
  
}


static char PatchrKeysData[9742] = "e36iR1Pddb4eC4r14C29VLsh31D44eDZYl1jbSgXNUpn80ha0uCqdqvKifktBz09MUYO97hyFShWYpZiuLHWy4udUVt4jNLw861YF9BMWCNknwQzV40DdsVBjpvG1dOyd88aDObnOqaehMoMeBmysC79lXqpg8LlD8mKL8XOLjkECMqwlaMUsIuITvddkshC8AGl9BNrJtSoa/4gk/lMfaTC3ymC8rWgymOCKGTMmvpwUVL7dDwL6HQdPSzyG3boh4ISNjA6PfYrWoG5UlZUiOAEda4vxWjFxCl17tIuE/YgB/0kG9TypfUevNXQdHGRxo4gPLtbmqUBLZYARVcybvAWdWeYBD8w4B7jQZyDPD3MejuHZaCKUwxjYKGi2rHONGUpHbWsxVdna3qrhKAm2PsSLtYy+oRxTEhy87sN3mhNR6/S0tcnBcq2fiQWsoCp6KIYTdsNCIUzxA6IJOKJ4S5AMgYdQ2ojdYp/xqmJgkvLoqp5FxyhmttgeF4vVYcju7ZBaGJaPlmYl8uWvcDIT9HhKTUjJwQwhhd5lp2f+JYn30UX3+x+e2S1rqOHKBDbgp8BRjLzzF10o2R5gzZfz9v259wLQGr+ruXn1mqk/811n32U5SbfQ7LgIx4ZAJyl9vm8G26U9Le52+DwySkWsVCZzbuXO4jmFAwFPtJVGv8C8CvUHYfJcwvRs80sPGxhCrnK32mYljPn13Wt7RSqBMXEI6vwjD1BIEm8vYZ/PAGlOgZZ5L1KqCZmgJJvXv/BTQ2qbKr+gJHqsXL/gsZ6OEVGeRsHCQWV9S63ZenJHgWRsoquiNaBVyfvuDdAmfE5DD3TLMsdgdsoQkF1NtgTXLx9ZWEI5RWMnf8luyd8zFZmnYi6Sm781r1/LwxOwyx1CadHo+/HZBageICuMio5c9+E7HhLVfn+hVdmHp-LaWLbU6kjBNuMjiXU6hX3kYluCH75e0dwZAL9v3vVmdJZWDR/S11uMIV8XuSK6abFbTXByKmwN86bpKWEJfK5UWnho1nS5LjDr3xkd97CZCGFpeNbHfWIEMRjwkzaGOM1YfaMG/2AnLYtV4F4gvQfLGQVPODm3KYrhsV41abQij6OuZaFJfl8dTQTpKJGdeiO3NUEq9nVuJoEV9Q0YrmC9/jehCJqYLV5kAeu0IX6G9C6Iqi24DAk2eSHrBPytutENFGuz7jodgx+NnmCT4L/KASJ0p0EXB+aUwOainCGaKpDk5HFGcv0cyxfbORY99ufKsw/5F0uPBq0y6sfzXpP6nQZsB4Wry3H8MgUJU0SPDNcKvErBX7PYGzSRlpoA9XN76dJ5nnISsQjn/1ti02Ci9E9mFDKd4iasyDJedGr2od0ai7bye4+UJ57R91tkc1l2eBW1ievaHrsyiU8AcDLNusuEg/tlR+BonwNe46W5h5AdjggaEjjOqyd4XzIF7quMGNKXndp4yHTcgLl4xA9is4J9krWalaiYwlegz/Pmo7m7PV3JHNHgnBF82+gk1rGotc+UBMTpXNbRqBPe41YSx7RCkPzqiTa0r9wv51Skq06OFGZoLyBfV/09b8v/8SsRMYFnnMyZrlN+CWYbYA2GRg5UGxlTfaPk0wwN6tofDHyf4s+ZLncKFR7XPHXtqiKZvTX8P7ARrmutul022Zte9C6D13QLiFZScV+OXCCCRA3Md9rb5lE6YX3+MWNgO3ehrVew2qiFzIlGCvpIPcA661KMH43/hB0t/pf+tpZ8EVv8+sjjdHVDaqZ/WRxP9S2Atv89Ohum4WFCVZAW4Av6TAR7niBF3UMT2rrYcCT7BxdJEqyECgI7kTBb69q2LAv2lcsuD91FW/AUAE9qDQPULz8PLKhrTl5j70r6/yaJBYUDbXk+KxAOnG8aSebiwOLrNhmD5q5CQ309sE2Kw5sFgcCNu0t3uHiYgvFwqACo+g7JjX20Vh6SknbvNqmnjP+IzZnCFT08o1aaucAUuJNB3o1tZ44Ju0Hln5deLH9WVkiwIZeHdKLezcEP/yH6N2zI6o8r1Fy97jcJUU7GEGBNbwEiDU6mJIeYVt+atBvmRzvOaV2o10xwwLlrm8+BQTcy1Dwd9qKzrZzQpzWgprt2uFuGb19JX3Q3/NdGl+3/veU+03rysOMbCR6SPm0ivuKgx14hDLeLMbHgReSprsb+xkSurEK2rvf13vVo98L4FX7it9UcX5v2CQzMwgVw0HB27ehRWZSjujVFgvGIidda9XAwqPlpDl2AkAjBbeaSTRx2RIDIphOC39xmNHvTbvhIT/P7tCiMYOQe8CLmi9zgTb5c6xrlJIEMzU7w918iQc53BB+EBdlWRdbchj5T8c8XYGarZfjZ3/U4n5g6h4rXRWBe2nYsusJt35ubkkdpZ7TH+MkTwWUTL8rNA2pKm0wcKaGP7VyWZozUz3Aqk6Gte84rc4GD7YzfQrBw7+buPco5quzB7x52idqFssRg3/GxeB/6b6Od7kEBBMg8OE/Cxvlp1Y4lHk1AUmrCyVPPycBgfs0mjBMuy1J2dOS7TxMJmcgZWTLrNXHe3SUnecbsOEFLKMP0hsob0HbN+lMghKDb1syFy1vhVUNulXBjJcgepRF/elgrQpkpL1vKlb9jq6Ctv/qXLwUPOU6pHNMMCJxdegB0+RA+bS3tRfBwsmcCE8APlmICsy84NWQstwRyj3K+VsYP7J96Z8aBfuiDdds8/tqRgkjL2NFiBUfb6uPp+m/HXBkqCwtyDJFPp0cumlddNkfylePm6Pw/z26cuqJqIaPyie9I6YISGV/24bc1539E6CxLEuWPfPERLEvEL2gsmUoOXayGTy2tezc3rIBkG+ikYdFRDxi7QBxLDjemw/RALAl3Ep4oCJM709EOW7cjtOa9SO2svzf9BUj9Kla0GK2+c9Vb+fdtiFSLE7zeRvqr3SaqYR/A8fYJOVdLYBB7LlqC/SO8bvXPUHh5o96B4RoDkNqRt9Fzi6IthA3wdrzsMFQv62uEFHsXYAEYcQV70XYH9G1GnUfoY1XGZMilghH8RLbXlov0Er8SyvfgJ/kdk6cLUih0h9ccl9e8RbxD8H8PvIuXMO0T-QkRTze496VNkjNR/1d2pXq9dmRUCAIpY/o/bWWz83mTyEzGX4pdhyG/qAZsz3p7h1EUUdcBUyTZoV7GjkJQPEP7qZWvCbqSfuk/Ttr34nqrVGN4EyKogBSInRuGAloK6e75avDMotSBanh4WXNxBaLHc1l5USlMPppqBpVO3Ejq16xCoLIKsedIw8pl9yITigJHIRk/M0yzYAX1YLaOW3zYc0rE1T20rxhuYimK+wo6qzhTUMEnP3fUzLFSWIUlxrVq9+gxa+L1JYomphEjESjuVpcNoEK2t3k+RH96OHU/Ic0BuKiL4a6q0vJbNiJslbf8GJ3lGNVPbj2NpDFQ85ZHmrdUVy3Y4dzBP3DheMdld1uyaU9b87N8YW67mWvAj7Qp6nrEeG0bPkLVT9ZPmrW+Jcb1VvACVOqSW9kfcFwXinK3egF8bzD7gTCGDfh45BpR5jQO5hUpU91MK7tHFp4ZLKSzN7f8Fhzwchp4ycfXzeg44fxjyzsT/ZBdweuryXrKDNH-91giBPbvM1AHFjIfHboE3xX6f/JYA7/0H/9prAxOHEcCnY/fZFg72mkJ+0QhNeYtBbo1zMrdk3wovjA7NRmYziVurjUk8MHgGqQu+QokQ2qWQu3dnTKj/ExGvaiJUhRQZSDItUBe46nvXunOOGVvk1hZgGTNipzJKS1XTCoVW1HJmHyiyMO44UInk9xZDf7JVEQAlnr5sOVkl2OQ8cY5Gd2GpKmE/hFp0kSZhhB5UhnFXlMX3q59GMkf2gbLq/cN2FchhGMFl6Lq3bpMmfc7XzTOJIRVHkhR5QmYcuDk50e4SPnLdu66SCxeyubP4Kb87fa/c+s066zAM68c0GHKZjJSSqkWWn5LL5kE3Al3EUlqfLXMnwPC1TDdxrkXkTLKDoc7098v1bpjpYwlhYFZAc1Fq3392aAXMuuQx4tX6Xl/NEMToujTufzm0YywyJ7AUHE8TEkbAtX5klecKCoqXsMXIOI+B4N8OlZyBGCD+I9TbQTsUMcfkxpf1QgucC3iOVipKRzxI24fSlIeahDpJKB3I+mlwDo9678cqk6ey41hzZcquD+UE/kd9v8cbZORk0HpoPywdmSKJzuF7I0nd0nqjw5Rc6bLya6HJZxWyTjovtQBS8olPYbdHAZLNM3QBCXgGE8OyWT3jVz/IQ5ZH1iHVYTef35N6ccaPhtrBsj+y6vo7yMDeZ2whWntar89rNkq6n+MwiUTYIRxIe3v+XH4bGqrWWEQ6odbIkdfZoyDNwPjA5f9iA3NhLtqs8DKPYdAse2dJg3NVHsoaYSfpR3t8lj7NjoQXjAghWw7smXWyQ07ZKdewts6yQw+uqTDaR8ta+I3NTNEMlrFBq50/urMEfY2vnTIJqe2cTt11Gul3D4xXI73PPMeZJ0JHAuhChJvnbd4cab+K06UjgVG+bVnC/ILc7s4h5vcNfJw4uC94CKZ15fFs3NVbP85q/gbCpizLI5ykkHxHh4TVwykYpWaJtbDvf2g+4AGPTSbZJ9e0Mcy7hc3Hm609uga2UDk+WoUH5aovJi8ge92TDVc21jh+ws93/eD/9LLRgvKionPivOMJlB/thRv3XiLZMRKJ+xZRngeyjWW/e3GRuMPxgN3FU71vaTDN1V4MwSf7hehd6xWQpeHyWBUc/1XI4X5fFd+0t3tAd38E6BcD1U/UE4Bhj3z96a5jEeiIL7FtMJn1wmB8AjQ1lE1Ao+JWqS7A0vjfOjHZkQ+yPyMOqTOWrAmUKu1VTTmb_ielSnWrE1mEwr2qcWjdOL/up+JL+qZyvfNFO6VUOISDAQ7kjN4q2LvFr1Th2BdeMw3As7N0nZ9cymIEAca9LgQftEqA1QDnXB536ehYokTx6cIJ76RyvIUXWUAJ2UFP6hqPt3MJqRpoCmhnhX6ngb5D7HWYUy6hJdcLR1IOK1y1ioXpdEx4tRbfh9Uf3oBwO6P3Cpj00qvMPctf+R4FdQEwDBM0efOvOjzsT2vdC1BYtrQYKsRZ5Q5DIjGC9BvEbRNc4Ggj0MiiaKn8jxeBnUBILdqJkRp4+ktnbotD4YmQ5LFjDLM+A9io2jjamsjyWR8xrn8JnrkkvGOdOMjM8uluevyPORT7tJB/0rRr0M8FEYiyLphNHyPaMqhvZv/dj8FtwrEyZLxX+v83ZtBH1vY2jnKdLrwN24VxJ+0/fcPazY7k0QDW047/xhGaqkjXH7dsIBSw48Izx+kdUmziAgR+u7QvTJertwr0Z4fyXsplb/t6hN/AX9hBhOPcmD63+f3c8aG0lRaZZViWO4bxXqd3T0TqTX0Nbzr2LX232irOArmhyasv3uLXuCt+XxG4W_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\\\"";

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
