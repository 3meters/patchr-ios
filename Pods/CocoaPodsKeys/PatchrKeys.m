//
// Generated by CocoaPods-Keys
// on 06/12/2016
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

  if ([key isEqualToString:@"bugsnagKey"]) {
    implementation = _podKeyscb1d83799398973f8aaf13fe74946723;
  }

  if ([key isEqualToString:@"bingSubscriptionKey"]) {
    implementation = _podKeyse6604380e1147a3126316b573070ec4e;
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

static NSString *_podKeyscb1d83799398973f8aaf13fe74946723(PatchrKeys *self, SEL _cmd)
{
  
    
      char cString[33] = { PatchrKeysData[7491], PatchrKeysData[6546], PatchrKeysData[8101], PatchrKeysData[941], PatchrKeysData[1781], PatchrKeysData[5181], PatchrKeysData[7766], PatchrKeysData[7109], PatchrKeysData[8753], PatchrKeysData[5389], PatchrKeysData[3127], PatchrKeysData[7236], PatchrKeysData[6738], PatchrKeysData[2422], PatchrKeysData[6235], PatchrKeysData[5282], PatchrKeysData[7989], PatchrKeysData[4640], PatchrKeysData[8760], PatchrKeysData[6921], PatchrKeysData[1803], PatchrKeysData[1733], PatchrKeysData[6433], PatchrKeysData[5907], PatchrKeysData[9312], PatchrKeysData[6446], PatchrKeysData[852], PatchrKeysData[8184], PatchrKeysData[8669], PatchrKeysData[5376], PatchrKeysData[6670], PatchrKeysData[605], '\0' };
    
    return [NSString stringWithCString:cString encoding:NSUTF8StringEncoding];
  
}

static NSString *_podKeyse6604380e1147a3126316b573070ec4e(PatchrKeys *self, SEL _cmd)
{
  
    
      char cString[33] = { PatchrKeysData[5914], PatchrKeysData[2699], PatchrKeysData[1755], PatchrKeysData[6141], PatchrKeysData[5783], PatchrKeysData[6620], PatchrKeysData[1779], PatchrKeysData[9324], PatchrKeysData[5101], PatchrKeysData[5571], PatchrKeysData[2103], PatchrKeysData[6266], PatchrKeysData[1169], PatchrKeysData[6378], PatchrKeysData[792], PatchrKeysData[4749], PatchrKeysData[2364], PatchrKeysData[66], PatchrKeysData[3607], PatchrKeysData[1100], PatchrKeysData[9890], PatchrKeysData[1157], PatchrKeysData[8157], PatchrKeysData[6622], PatchrKeysData[3413], PatchrKeysData[921], PatchrKeysData[2664], PatchrKeysData[8147], PatchrKeysData[5329], PatchrKeysData[7773], PatchrKeysData[5714], PatchrKeysData[7475], '\0' };
    
    return [NSString stringWithCString:cString encoding:NSUTF8StringEncoding];
  
}

static NSString *_podKeysb2b3a4eeef502a37c4374d2cdc4b9f4f(PatchrKeys *self, SEL _cmd)
{
  
    
      char cString[33] = { PatchrKeysData[5810], PatchrKeysData[942], PatchrKeysData[7890], PatchrKeysData[2233], PatchrKeysData[8761], PatchrKeysData[4025], PatchrKeysData[3026], PatchrKeysData[81], PatchrKeysData[5030], PatchrKeysData[3652], PatchrKeysData[6651], PatchrKeysData[8105], PatchrKeysData[1489], PatchrKeysData[1275], PatchrKeysData[689], PatchrKeysData[6819], PatchrKeysData[7678], PatchrKeysData[8050], PatchrKeysData[3531], PatchrKeysData[7423], PatchrKeysData[7301], PatchrKeysData[4854], PatchrKeysData[3415], PatchrKeysData[211], PatchrKeysData[1366], PatchrKeysData[6700], PatchrKeysData[205], PatchrKeysData[762], PatchrKeysData[1910], PatchrKeysData[7467], PatchrKeysData[1422], PatchrKeysData[1896], '\0' };
    
    return [NSString stringWithCString:cString encoding:NSUTF8StringEncoding];
  
}

static NSString *_podKeysad40c1de013e6d4091f36a72b8bd6d59(PatchrKeys *self, SEL _cmd)
{
  
    
      char cString[37] = { PatchrKeysData[9625], PatchrKeysData[2479], PatchrKeysData[4718], PatchrKeysData[2410], PatchrKeysData[5788], PatchrKeysData[7186], PatchrKeysData[8392], PatchrKeysData[2305], PatchrKeysData[5686], PatchrKeysData[2323], PatchrKeysData[2809], PatchrKeysData[5000], PatchrKeysData[8346], PatchrKeysData[3371], PatchrKeysData[7010], PatchrKeysData[3388], PatchrKeysData[9948], PatchrKeysData[1884], PatchrKeysData[3831], PatchrKeysData[5073], PatchrKeysData[4227], PatchrKeysData[6047], PatchrKeysData[3527], PatchrKeysData[3676], PatchrKeysData[1851], PatchrKeysData[3347], PatchrKeysData[76], PatchrKeysData[4694], PatchrKeysData[1893], PatchrKeysData[8560], PatchrKeysData[6355], PatchrKeysData[3669], PatchrKeysData[3573], PatchrKeysData[2995], PatchrKeysData[8963], PatchrKeysData[7946], '\0' };
    
    return [NSString stringWithCString:cString encoding:NSUTF8StringEncoding];
  
}

static NSString *_podKeyse34fa92f188be998ae3b930eacc919f8(PatchrKeys *self, SEL _cmd)
{
  
    
      char cString[21] = { PatchrKeysData[8259], PatchrKeysData[7129], PatchrKeysData[179], PatchrKeysData[3041], PatchrKeysData[6915], PatchrKeysData[3294], PatchrKeysData[4632], PatchrKeysData[3342], PatchrKeysData[6399], PatchrKeysData[4455], PatchrKeysData[7226], PatchrKeysData[4501], PatchrKeysData[9179], PatchrKeysData[7050], PatchrKeysData[7888], PatchrKeysData[5271], PatchrKeysData[2820], PatchrKeysData[2373], PatchrKeysData[6624], PatchrKeysData[7737], '\0' };
    
    return [NSString stringWithCString:cString encoding:NSUTF8StringEncoding];
  
}

static NSString *_podKeys28e3120dfd5d3940bfdd3918b00dc7c8(PatchrKeys *self, SEL _cmd)
{
  
    
      char cString[41] = { PatchrKeysData[3901], PatchrKeysData[7964], PatchrKeysData[4168], PatchrKeysData[7290], PatchrKeysData[6096], PatchrKeysData[4422], PatchrKeysData[9487], PatchrKeysData[2114], PatchrKeysData[6984], PatchrKeysData[48], PatchrKeysData[3738], PatchrKeysData[520], PatchrKeysData[1863], PatchrKeysData[3656], PatchrKeysData[9336], PatchrKeysData[357], PatchrKeysData[5945], PatchrKeysData[4608], PatchrKeysData[8169], PatchrKeysData[7770], PatchrKeysData[7229], PatchrKeysData[4623], PatchrKeysData[6638], PatchrKeysData[8955], PatchrKeysData[8083], PatchrKeysData[2673], PatchrKeysData[2480], PatchrKeysData[3212], PatchrKeysData[3556], PatchrKeysData[7843], PatchrKeysData[1810], PatchrKeysData[5344], PatchrKeysData[2904], PatchrKeysData[2649], PatchrKeysData[1927], PatchrKeysData[4471], PatchrKeysData[6644], PatchrKeysData[5408], PatchrKeysData[2910], PatchrKeysData[8561], '\0' };
    
    return [NSString stringWithCString:cString encoding:NSUTF8StringEncoding];
  
}

static NSString *_podKeysa0b8dbdc39d299a103febb05c63e662e(PatchrKeys *self, SEL _cmd)
{
  
    
      char cString[42] = { PatchrKeysData[5059], PatchrKeysData[5772], PatchrKeysData[1782], PatchrKeysData[2213], PatchrKeysData[8843], PatchrKeysData[8199], PatchrKeysData[6], PatchrKeysData[9119], PatchrKeysData[9741], PatchrKeysData[23], PatchrKeysData[8219], PatchrKeysData[8175], PatchrKeysData[9917], PatchrKeysData[4791], PatchrKeysData[1363], PatchrKeysData[2464], PatchrKeysData[9721], PatchrKeysData[5372], PatchrKeysData[9945], PatchrKeysData[3327], PatchrKeysData[6407], PatchrKeysData[6949], PatchrKeysData[7715], PatchrKeysData[222], PatchrKeysData[581], PatchrKeysData[506], PatchrKeysData[3767], PatchrKeysData[8520], PatchrKeysData[7222], PatchrKeysData[8038], PatchrKeysData[9954], PatchrKeysData[3262], PatchrKeysData[8318], PatchrKeysData[6217], PatchrKeysData[2558], PatchrKeysData[4377], PatchrKeysData[397], PatchrKeysData[2841], PatchrKeysData[4779], PatchrKeysData[7986], PatchrKeysData[384], '\0' };
    
    return [NSString stringWithCString:cString encoding:NSUTF8StringEncoding];
  
}

static NSString *_podKeys977a4e3d43d506c4c8f28dbcfc106730(PatchrKeys *self, SEL _cmd)
{
  
    
      char cString[8] = { PatchrKeysData[8305], PatchrKeysData[1641], PatchrKeysData[4092], PatchrKeysData[1390], PatchrKeysData[5639], PatchrKeysData[9012], PatchrKeysData[8838], '\0' };
    
    return [NSString stringWithCString:cString encoding:NSUTF8StringEncoding];
  
}

static NSString *_podKeyse9c848d2566111a2e8ab97a467a8f412(PatchrKeys *self, SEL _cmd)
{
  
    
      char cString[49] = { PatchrKeysData[5052], PatchrKeysData[9078], PatchrKeysData[3462], PatchrKeysData[6475], PatchrKeysData[5614], PatchrKeysData[916], PatchrKeysData[6652], PatchrKeysData[513], PatchrKeysData[1079], PatchrKeysData[8751], PatchrKeysData[2016], PatchrKeysData[3899], PatchrKeysData[7440], PatchrKeysData[5544], PatchrKeysData[2566], PatchrKeysData[2626], PatchrKeysData[5754], PatchrKeysData[5665], PatchrKeysData[3004], PatchrKeysData[3598], PatchrKeysData[4719], PatchrKeysData[5370], PatchrKeysData[2196], PatchrKeysData[741], PatchrKeysData[92], PatchrKeysData[1242], PatchrKeysData[5829], PatchrKeysData[3894], PatchrKeysData[743], PatchrKeysData[8137], PatchrKeysData[4870], PatchrKeysData[8296], PatchrKeysData[3600], PatchrKeysData[4569], PatchrKeysData[4041], PatchrKeysData[6903], PatchrKeysData[2363], PatchrKeysData[6010], PatchrKeysData[9327], PatchrKeysData[6908], PatchrKeysData[489], PatchrKeysData[5937], PatchrKeysData[6610], PatchrKeysData[6945], PatchrKeysData[6296], PatchrKeysData[7379], PatchrKeysData[2241], PatchrKeysData[7901], '\0' };
    
    return [NSString stringWithCString:cString encoding:NSUTF8StringEncoding];
  
}


static char PatchrKeysData[9986] = "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_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_LT2Tr0PSe++QhExyZTDOJqJ/nuDLaOwwQPVfvbVJAc3nGh4Iqisnid2bnj/j8SdIfexDBjcI18YV5KdvsxOdXFM6BffN62cOX4Hu0M1Eksj5hByVpcSz6DsEOLoqtQ1Vr7K0Aa4bj5Nblnq4MEDGa6Vb+B87pk2EAndRCeFfDYx1/+QKSdCGqw6tyxbOT+kJowqxVW3a5xR63K6J8hjelDTkJH3CGyT9oHF/RuvjfVashOqus6\\\"";

- (NSString *)description
{
  return [@{
            @"bugsnagKey": self.bugsnagKey,
            @"bingSubscriptionKey": self.bingSubscriptionKey,
            @"creativeSdkClientId": self.creativeSdkClientId,
            @"creativeSdkClientSecret": self.creativeSdkClientSecret,
            @"awsS3Key": self.awsS3Key,
            @"awsS3Secret": self.awsS3Secret,
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
