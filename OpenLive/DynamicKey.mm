//
//  DynamicKey.m
//  OpenLive
//
//  Created by shanhui on 2017/1/12.
//  Copyright © 2017年 Agora. All rights reserved.
//

#import "DynamicKey.h"
#include <string>
#include <sstream>
#include <openssl/hmac.h>
#include <stdexcept>
#include <iomanip>
#include <cstddef>
#include <cctype>
#include <cstring>
#include <cstdlib>

const uint32_t HMAC_LENGTH = 20;
const uint32_t SIGNATURE_LENGTH = 40;
const uint32_t APP_ID_LENGTH = 32;
const uint32_t UNIX_TS_LENGTH = 10;
const uint32_t RANDOM_INT_LENGTH = 8;
//const uint32_t UID_LENGTH = 10;
const uint32_t VERSION_LENGTH = 3;
const std::string  MEDIA_CHANNEL_SERVICE = "ACS";

template <class T>
class singleton
{
public:
    static T* instance()
    {
        static T inst;
        return &inst;
    }
protected:
    singleton(){}
    virtual ~singleton(){}
private:
    singleton(const singleton&);
    singleton& operator = (const singleton& rhs);
};

class crypto : public singleton<crypto>
{
public:
    // HMAC
    std::string hmac_sign(const std::string& message)
    {
        return hmac_sign2(hmac_key_, message, 20);
    }
    
    std::string hmac_sign2(const std::string& appCertificate, const std::string& message, uint32_t signSize)
    {
        if (appCertificate.empty()) {
            /*throw std::runtime_error("empty hmac key");*/
            return "";
        }
        return std::string((char *)HMAC(EVP_sha1()
                                        , (const unsigned char*)appCertificate.data()
                                        , appCertificate.length()
                                        , (const unsigned char*)message.data()
                                        , message.length(), NULL, NULL)
                           , signSize);
    }
    
    bool hmac_verify(const std::string & message, const std::string & signature)
    {
        return signature == hmac_sign(message);
    }
private:
    std::string hmac_key_;
};


inline std::string stringToHEX(const std::string& in)
{
    static const char hexTable[]= "0123456789ABCDEF";
    
    if (in.empty()) {
        return std::string();
    }
    std::string out(in.size()*2, '\0');
    for (uint32_t i = 0; i < in.size(); ++i){
        out[i*2 + 0] = hexTable[(in[i] >> 4) & 0x0F];
        out[i*2 + 1] = hexTable[(in[i]     ) & 0x0F];
    }
    return out;
}

inline std::string stringToHex(const std::string& in)
{
    static const char hexTable[]= "0123456789abcdef";
    
    if (in.empty()) {
        return std::string();
    }
    std::string out(in.size()*2, '\0');
    for (uint32_t i = 0; i < in.size(); ++i){
        out[i*2 + 0] = hexTable[(in[i] >> 4) & 0x0F];
        out[i*2 + 1] = hexTable[(in[i]     ) & 0x0F];
    }
    return out;
}


struct DynamicKey4{
    static const uint32_t DYNAMIC_KEY_LENGTH = VERSION_LENGTH + SIGNATURE_LENGTH + APP_ID_LENGTH + UNIX_TS_LENGTH + RANDOM_INT_LENGTH + UNIX_TS_LENGTH ;
    static const uint32_t SIGNATURE_OFFSET = VERSION_LENGTH;
    static const uint32_t APP_ID_OFFSET = VERSION_LENGTH+SIGNATURE_LENGTH;
    static const uint32_t UNIX_TS_OFFSET = VERSION_LENGTH+SIGNATURE_LENGTH+APP_ID_LENGTH;
    static const uint32_t RANDOM_INT_OFFSET = VERSION_LENGTH+SIGNATURE_LENGTH+APP_ID_LENGTH+UNIX_TS_LENGTH;
    static const uint32_t EXPIREDTS_INT_OFFSET = VERSION_LENGTH+SIGNATURE_LENGTH+APP_ID_LENGTH+UNIX_TS_LENGTH+RANDOM_INT_LENGTH;
    static std::string version() { return "004"; }
    std::string signature;
    std::string appID;
    uint32_t unixTs ;
    uint32_t randomInt;
    uint32_t expiredTs;
    
    static std::string toString(const std::string& appID, const std::string& signature,  uint32_t unixTs, uint32_t randomInt, uint32_t expiredTs)
    {
        std::stringstream ss;
        ss  << DynamicKey4::version()
        << signature
        << appID
        << std::setfill ('0') << std::setw(10) << unixTs
        << std::setfill ('0') << std::setw(8) << std::hex << randomInt
        << std::setfill ('0') << std::setw(10) << std::dec<< expiredTs;
        return ss.str();
    }
    
    bool fromString(const std::string& channelKeyString)
    {
        if (channelKeyString.length() != (DYNAMIC_KEY_LENGTH)) {
            return false;
        }
        this->signature = channelKeyString.substr(SIGNATURE_OFFSET, SIGNATURE_LENGTH);
        this->appID = channelKeyString.substr(APP_ID_OFFSET, APP_ID_LENGTH);
        try {
            this->unixTs = std::stoul(channelKeyString.substr(UNIX_TS_OFFSET, UNIX_TS_LENGTH), nullptr, 10);
            this->randomInt = std::stoul(channelKeyString.substr(RANDOM_INT_OFFSET, RANDOM_INT_LENGTH), nullptr, 16);
            this->expiredTs = std::stoul(channelKeyString.substr(EXPIREDTS_INT_OFFSET, UNIX_TS_LENGTH), nullptr, 10);
        } catch(std::exception& e) {
            return false;
        }
        return true;
    }
    
    static std::string generateSignature(const std::string& appID, const std::string& appCertificate, const std::string& channelName, uint32_t unixTs, uint32_t randomInt, uint32_t uid, uint32_t expiredTs, std::string service)   {
        std::stringstream ss;
        ss<< service
        << std::setfill ('\0') << std::setw(32) << appID
        << std::setfill ('0') << std::setw(10) << unixTs
        << std::setfill ('0') << std::setw(8) << std::hex << randomInt
        << channelName
        << std::setfill ('0') << std::setw(10) << std::dec<<uid
        << std::setfill ('0') << std::setw(10) << expiredTs;
        return stringToHex(singleton<crypto>::instance()->hmac_sign2(appCertificate, ss.str(), HMAC_LENGTH));
    }
    
    static std::string generateMediaChannelKey(const std::string& appID, const std::string& appCertificate, const std::string& channelName, uint32_t unixTs, uint32_t randomInt, uint32_t uid, uint32_t expiredTs)
    {
        std::string  signature = generateSignature(appID, appCertificate, channelName, unixTs, randomInt, uid, expiredTs, MEDIA_CHANNEL_SERVICE);
        
        return toString(appID,signature,  unixTs, randomInt,  expiredTs);
    }
};


@implementation DynamicKey
+(NSString*) generateMediaChannelKey:(NSString *)appID appCertificate:(NSString *)appCertificate channelName:(NSString *)channelName unixTs:(UInt32)unixTs randomInt:(UInt32)randomInt uid:(UInt32)uid expiredTs:(UInt32)expiredTs
{
    NSString *s = [[NSString alloc] initWithUTF8String: DynamicKey4::generateMediaChannelKey([appID UTF8String], [appCertificate UTF8String], [channelName UTF8String], unixTs, randomInt, uid, expiredTs).c_str()];
    return s;
}
@end
