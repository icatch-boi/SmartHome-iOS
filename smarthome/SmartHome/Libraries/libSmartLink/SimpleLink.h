/*
 * SimpleLink.h
 *
 *  Created on: 2017Äê12ÔÂ17ÈÕ
 *      Author: Administrator
 */

#ifndef SIMPLELINK_H_
#define SIMPLELINK_H_
#include <memory>
#include <string>

namespace icatchtek {
namespace simplelink {

typedef enum LinkType {
	LINKTYPE_SMARTLINK = 1,
	LINKTYPE_APMODE = 2,
	LINKTYPE_SIMPLECONFIG = 3,
} E_LinkType;

typedef enum SmartLinkFlag {
	SMARTLINK_V1  		=	0x1,
	SMARTLINK_V4  		=	0x2,
	SMARTLINK_V5 		=	0x4,
	SMARTLINK_V1_V4  	=	(SMARTLINK_V1 | SMARTLINK_V4),
	SMARTLINK_V4_V5   	=	(SMARTLINK_V4 | SMARTLINK_V5),
}E_SmartLinkFlag;

class ILink;
class LinkOption;
class LinkContent;
class SimpleLink {
public:
	SimpleLink();
	virtual ~SimpleLink();
	int init(E_LinkType LinkType, int timeout, int interval, char* cryptoKey, int keyLen, int flag);
	int setContent(std::string ssid, std::string ssidPwd, std::string sysPwd, std::string localIP,
			std::string gatewayIP, std::string MAC);
	int link(std::string& result);
	int cancel();

private:
	int initLinkClient(E_LinkType LinkType);
	LinkOption* option_;
	LinkContent* content_;
	ILink* link_;
	bool linking;
};

} /* namespace simplelink */
} /* namespace icatchtek */

#endif /* SIMPLELINK_H_ */
