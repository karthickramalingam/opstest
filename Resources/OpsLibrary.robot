*** Settings ***
Library		OperatingSystem
Library         String
Library         Collections
Library         SSHLibrary
Library 	XML

*** Variables ***
${HOSTS}
${XMLData}

*** Keywords ***
Initialize 
   	[Documentation]  Initializes the variables
	[Arguments]  ${DevicePath}  ${XmlFile}

	${HOSTS}=  Create Dictionary
	${XMLData}=  Parse XML  ${XmlFile}
	Set Suite Variable  ${HOSTS}
	Set Suite Variable  ${XMLData}
	${FILE_CONTENT}=  OperatingSystem.Get File  ${DevicePath}
	@{Lines}=  Split To Lines  ${FILE_CONTENT}
	Remove From List  ${Lines}  0
	: FOR  ${Line}  IN  @{Lines}
	\  @{COLUMNS}=  Split String  ${Line}  separator=,
	\  ${Host}=     Get From List  ${COLUMNS}  0
	\  Set To Dictionary   ${HOSTS}  ${Host}=${Line}  ${Host}=${Line}

XML Parser
	[Documentation]  Parse the XML document

	[Arguments]  ${PATH}   ${EXACT}
	${first} =  Get Element  ${XMLData}   ${PATH}
	${two} =   Get Element  ${first}   ${EXACT}
	${returnData}=  Strip String  ${two.text}
	[RETURN]  ${returnData}

Open Connection To Device
	[Documentation]  Opens the Connection to the Device
 
	[Arguments]  ${Host}
	Log Dictionary  ${HOSTS}
	${Line}=  Get From Dictionary  ${HOSTS}  ${Host}
	@{COLUMNS}=  Split String  ${Line}  separator=,
	${Host}=     Get From List  ${COLUMNS}  0
	${Host}=     Strip String  ${Host}
	${IpAddr}=   Get From List  ${COLUMNS}  1
	${IpAddr}=   Strip String  ${IpAddr}
	${Port}=     Get From List  ${COLUMNS}  2
	${Port}=     Strip String  ${Port}
	${User}=     Get From List  ${COLUMNS}  3
	${User}=     Strip String  ${User}
	${Pass}=     Get From List  ${COLUMNS}  4
	${Pass}=     Strip String   ${Pass}	

 	Open Connection  ${IpAddr}  port=${Port}  alias=${Host}
	Set Client Configuration  prompt=#  timeout=5  encoding=ISO-8859-1 		
	Login  ${User}  ${Pass}
	Write  vtysh

Connect To Host
	[Documentation]  Connects to the Host

	[Arguments]  ${Host} 
	${HostInfo}=  Get Connection  ${Host}
	Run Keyword If  ${HostInfo.index} < 0  Open Connection To Device  ${Host}
	Run Keyword If  ${HostInfo.index} > 0  Switch Connection  ${Host}

Execute Command In Host
        [Documentation]  This function is to execute a command in the Host with 0s delay
	[Arguments]  ${Host}  ${Command}  ${delay}=0s
	Log  ${Command}
	Connect To Host  ${Host}
        Write  ${Command}
	${output}=  Read   delay=${delay}
	Log  ${output}
	[Return]  ${output}

Execute In Host
        [Documentation]  This function is to execute a command in the Host with 2s delay
	[Arguments]  ${Host}  ${Command}  ${delay}=2s  	
	${output}=  Execute Command In Host  ${Host}  ${Command}  ${delay}
	[Return]  ${output}

Execute In Host Without Return Value
        [Documentation]  This function is to execute a command in the Host with 0s 
	...  delay and not return anything
	[Arguments]  ${Host}  ${Command}
	Execute Command In Host  ${Host}  ${Command}

Configure Ip
	[Documentation]  Ip Conifiguration

	[Arguments]  ${Host}  ${Interface}  ${IP}
	Execute In Host Without Return Value  ${Host}  configure terminal  
	Execute In Host Without Return Value  ${Host}  interface ${Interface}  
	Execute In Host Without Return Value  ${Host}  ip address ${IP}
	Execute In Host Without Return Value  ${Host}  no shutdown
	Execute In Host Without Return Value  ${Host}  end
	${result}=  Execute In Host  ${Host}  sh inter ${Interface}
	log  ${result}
	Should Contain  ${result}  Interface ${Interface} is up

Ping
	[Documentation]  Ping

	[Arguments]  ${Host}  ${IP}  ${Repetitions}=""
	${result}=  Run Keyword If  ${Repetitions} > 0  Execute In Host   ${Host}  ping ${IP} repetitions ${Repetitions}  15s  
	${result}=  Run Keyword If  ${Repetitions}==""  Execute In Host   ${Host}  ping ${IP}  5s
	log  ${result}
	Should Contain  ${result}  0% packet loss

Show Version
	[Documentation]  Shows the version of the device

	[Arguments]  ${Host}
	${result}=  Execute In Host  ${Host}  show version
	Should Contain  ${result}  OpenSwitch 0.4.0

Show Ip Interface
	[Documentation]  Shows interface Name

	[Arguments]  ${Host}  ${Interface}
	${result}=  Execute In Host  ${Host}  show ip interface ${Interface} 
	Should Match Regexp  ${result}  IPv4 address \\d*.\\d*.\\d*.\\d*\\/\\d*

Show Interface Brief
	[Documentation]  Shows interface brief

	[Arguments]  ${Host}  
	${result}=  Execute In Host  ${Host}  show interface brief
	log  ${result}
	Should Contain  ${result}  up
	
Show Bgp Summary
	[Documentation]  Shows ip bgp summay 

	[Arguments]  ${Host}  ${value}=1
	${result}=  Execute In Host  ${Host}  show ip bgp summary
	${Match}  ${group1}   ${group2}=
	...	   Should Match Regexp  ${result}  (Peers )(\\d*)
	${value}=  Convert To Integer  ${group2}
	${count}=  Count  ${Host}  ${value}  ${result}
	${value1}=  Convert To Integer  ${count}
	Run Keyword If  ${value1}==1  Log  TRUE
	Run Keyword If  ${value}!=1  Log  FALSE
#Called by ShowBgpSummary keyword	
Count
	[Arguments]  ${Host}  ${value}  ${result}
	${count}=  Should Contain  ${result}  Established
	Run Keyword If  ${count}==None  ${value}=1
	[RETURN]  ${value}
	
Show Running Configuration
	[Documentation]  Shows the running configuration of the device

	[Arguments]  ${Host}  ${result}=""
	${result}=  Execute In Host  ${Host}  show running-config
	Should Not Be Empty  ${result}

Show Startup Configuration
	[Documentation]  Shows the startup configuration of the device

	[Arguments]  ${Host}
	${result}=  Execute In Host  ${Host}  show startup-config  5s
	Should Not Be Empty  ${result}
	

TraceRoute
	[Documentation]  TraceRoute

	[Arguments]  ${Host}  ${IP}
	${result}=  Execute In Host  ${Host}   traceroute ${IP}  10s
	Should Match Regexp  ${result}  \\d*.\\d*ms

Change Interface State
	[Documentation]   Changes the Interface State to up/down 

	[Arguments]  ${Host}  ${Interface}  ${State}=""
	Execute In Host Without Return Value  ${Host}  configure terminal  
	Execute In Host Without Return Value  ${Host}  interface ${Interface} 
	Run Keyword If  '${State}'=='up'  Execute In Host Without Return Value  ${Host}  no shutdown
	Run Keyword If  '${State}'=='down'  Execute In Host Without Return Value  ${Host}  shut
	Execute In Host Without Return Value  ${Host}  end
	${result}=  Execute In Host  ${Host}  show interface ${Interface}
	Should Contain  ${result}  Interface ${Interface} is ${state}

Add Static Route
  	[Documentation]   Adds static route

	[Arguments]  ${Host}  ${DestNetwork}  ${NextHopIP}
	Execute In Host Without Return Value  ${Host}  configure terminal
	Execute In Host Without Return Value  ${Host}  ip route ${DestNetwork} ${NextHopIP}
	Execute In Host Without Return Value  ${Host}  end  5s
	${result}=  Execute In Host  ${Host}  show running-config
	Should Contain  ${result}  ip route ${DestNetwork} ${NextHopIP}

Remove Static Route
	[Documentation]   Removes static route

	[Arguments]  ${Host}  ${destNetwork}  ${nextHopIP}  
	Execute In Host Without Return Value  ${Host}  configure terminal
	Execute In Host Without Return Value  ${Host}  no ip route ${destNetwork} ${nextHopIP}
	Execute In Host Without Return Value  ${Host}  end
	${result}=  Execute In Host  ${Host}  show running-config 
	Should Not Contain  ${result}  ip route ${destNetwork} ${nextHopIP}


####srivalli###
Show Ip Bgp
	[Documentation]   List's the BGP routing tables

	[Arguments]  ${Host}  ${NetworkIP}
    	${bestpath}=  Create Dictionary 
    	${result}=  Execute In Host  ${Host}  show ip bgp  5s
    	Should Contain  ${result}  *> ${networkIP}/24

Clear BGP Neighbor
	[Documentation]  Clears the BGP Neighbors
 
	[Arguments]  ${Host}  ${NeighborIP}=""  ${ASNum}=""
    	Run Keyword If  '${NeighborIP}'!=""  Execute In Host Without Return Value  ${Host}  clear bgp ${NeighborIP} soft in  
    	Execute In Host Without Return Value  ${Host}  clear bgp ${NeighborIP} soft out
    	Run Keyword If  '${ASNum}'!=""  Execute In Host Without Return Value  ${Host}  clear bgp ${ASNum} soft in
    	Execute In Host Without Return Value  ${Host}  clear bgp ${ASNum} soft out	
    	Run Keyword If  '${ASNum}'=="" and '${NeighborIP}'==""  Execute In Host Without Return Value  ${Host}  clear bgp * soft in
    	Execute In Host Without Return Value  ${Host}  clear bgp * soft out	
    	${result}=  Execute In Host  ${Host}  show ip bgp summary
    	Should Match Regexp  ${result}   (?im)Idle|(?im)null

Remove BGP
	[Documentation]  Removes the BGP Configuration 

    	[Arguments]  ${Host}  ${asnum}
    	Execute In Host Without Return Value  ${Host}  configure terminal
    	Execute In Host Without Return Value  ${Host}  no router bgp ${asnum}
    	Execute In Host Without Return Value  ${Host}  end 
    	${result}=  Execute In Host  ${Host}  show running-config
    	Should Not Contain  ${result}  ${asnum}

Create ACL
	[Documentation]  Creates the Access Control List
  
    	[Arguments]  ${Host}  ${aclname}  ${rule}
    	Execute In Host Without Return Value  ${Host}  configure terminal
    	Execute In Host Without Return Value  ${Host}  access-list ip ${aclname}
    	Execute In Host Without Return Value  ${Host}  ${rule}
    	Execute In Host Without Return Value  ${Host}  end
    	${result}=  Execute In Host  ${Host}  show running-config
    	Should Contain  ${result}  ${rule}

Remove ACL
	[Documentation]  Removes the Access Control List completely

   	[Arguments]  ${Host}  ${aclname}
    	Execute In Host Without Return Value  ${Host}  configure terminal
    	Execute In Host Without Return Value  ${Host}  access-list ip ${aclname}
    	Execute In Host Without Return Value  ${Host}  ${rule}
    	Execute In Host Without Return Value  ${Host}  end
    	${result}=  Execute In Host  ${Host}  show running-config
    	Should Contain  ${result}  ${aclname}


Add Acl Rules
	[Documentation]  Adds the Access Control List rules or Entries

    	[Arguments]  ${Host}  ${aclname}  ${rule}
    	Execute In Host Without Return Value  ${Host}  configure terminal
    	Execute In Host Without Return Value  ${Host}  access-list ip ${aclname}
    	Execute In Host Without Return Value  ${Host}  ${rule}
    	Execute In Host Without Return Value  ${Host}  end
    	${result}=  Execute In Host  ${Host}  show running-config
    	Should Contain  ${result}  ${aclname}
    	Should Contain  ${result}  ${rule}

Remove Acl Rules
	[Documentation]  Removes the Access Control List rules or Entries

    	[Arguments]  ${Host}  ${aclname}  ${rule}
    	Execute In Host Without Return Value  ${Host}  configure terminal
    	Execute In Host Without Return Value  ${Host}  access-list ip ${aclname}
    	Execute In Host Without Return Value  ${Host}  no ${rule}
    	Execute In Host Without Return Value  ${Host}  end
    	${result}=  Execute In Host   ${Host}  show running-config
    	Should Contain  ${result}  ${aclname}
    	Should Contain  ${result}  ${rule}

Change Neighbor State
	[Documentation]  Changes BGP Neighbor state

	[Arguments]  ${Host}  ${ASNum}  ${neighbourIP}  ${state}
	Execute In Host Without Return Value  ${Host}  configure terminal
	Execute In Host Without Return Value  ${Host}  router bgp ${ASNum}
	${result}=  Run Keyword If  '${state}'=="down"  StateDown  ${Host}  ${neighbourIP}
	...  ELSE IF  '${state}'=="up"  StateUp  ${Host}  ${neighbourIP}
	Should Match Regexp  ${result}  (?im)Idle|(?im)null|(?im)Established


#Used by Change Neighbor State keyword	
StateDown
	[Arguments]  ${Host}  ${neighbourIP}
	Execute In Host Without Return Value  ${Host}  neighbor ${neighbourIP} shutdown
	Execute In Host Without Return Value  ${Host}  end
	Sleep  30
	${result}=  Execute In Host  ${Host}  show ip bgp summary
	Should Match Regexp  ${result}  (?im)Idle|(?im)null
	[RETURN]  ${result}

#Used Change Neighbor State keyword
StateUp
	[Arguments]  ${Host}  ${neighbourIP}
	Execute In Host Without Return Value  ${Host}  no neighbor ${neighbourIP} shutdown
	Execute In Host Without Return Value  ${Host}  end
	Sleep  30
	${result}=  Execute In Host  ${Host}  show ip bgp summary
	Should Contain  ${result}  Established
	[RETURN]  ${result}

Remove Interface
	[Documentation]  Removes loopback interface

        [Arguments]  ${Host}  ${Interface}
        Execute In Host Without Return Value  ${Host}  configure terminal
        Execute In Host Without Return Value  ${Host}  no interface ${Interface}
        Execute In Host Without Return Value  ${Host}  end
        ${OUT}=  Execute In Host  ${Host}  show running-config
        Should Not Contain  ${OUT}  interface ${interface}

Clear Accesslist Hit Counts
	[Documentation]  Clears access list hitcounts passes if Hitcounts are cleared fails if the list is not cleared

        [Arguments]  ${Host}  ${aclname}=""   ${interface}=""  ${traffic}=""
        Run Keyword If  ${aclname}!=""  Traffic Available  ${Host}  ${interface}  ${traffic}
        Run Keyword If  ${aclname}==""  Traffic Not Available  ${Host}

#Used by Clear Accesslist Hit Counts keyword
Traffic Available 
	[Arguments]  ${Host}  ${interface}  ${traffic}
        Run Keyword If  ${traffic}!=""  Clear Hitcount  ${Host}  ${aclname}  ${interface}  ${traffic}
        Run Keyword If  ${interface}!=""  Clear Hitcount Interface   ${Host}  ${aclname}   ${interface}
        Run Keyword If  '${interface}'=="" and '${traffic}'==""   Clear Hitcount2  ${Host} 

#Used by Traffic Available keyword
Clear Hitcount
	[Arguments]  ${Host}  ${aclname}  ${interface}  ${traffic}
        Execute In Host Without Return Value  ${Host}  clear access-list hitcounts ip ${aclname} interface ${interface} ${traffic}
        ${OUT}=  Execute In Host  ${Host}  show access-list hitcounts ip ${aclname} interface ${interface} ${traffic}
        Should Contain  ${OUT}  permit

#Used by Traffic Available keyword 
Clear Hitcount Interface
	[Arguments]  ${Host}  ${aclname}   ${interface}  
        Execute In Host Without Return Value  ${Host}  clear access-list hitcounts ip ${aclname} interface ${interface}     
        ${OUT}=  Execute In Host   ${Host}  show access-list hitcounts ip ${aclname} interface ${interface}
        Should Contain  ${OUT}  permit

#Used by Traffic Available keyword
Clear Hitcount2
	[Arguments]  ${Host}
        Execute In Host Without Return Value  ${Host}  clear access-list hitcounts all
        ${OUT}=  Execute In Host   ${Host}  show access-list hitcounts ip
        Should Contain  ${OUT}  [permit deny]

#Used by Clear Accesslist Hit Counts keyword
Traffic Not Available
	[Arguments]  ${Host}
        ${OUT}=  Execute In Host   ${Host}  clear access-list hitcounts all
        Should Contain  ${OUT}  \#

Show Access List Hit Counts
	[Documentation]  shows access-list hitcounts with Options

        [Arguments]  ${Host}  ${aclname}=""   ${interface}=""  ${traffic}=""
        Run Keyword If  ${traffic}!=""  Show1  ${Host}  ${aclname}   ${interface}  ${traffic}
        Run Keyword If  ${interface}!=""  Show2  ${Host}  ${aclname}   ${interface}
        Run Keyword If  ${interface}=="" and ${traffic}==""  Show3  ${Host}  ${aclname} 

#Used by Show Access List Hit Counts Hit Counts keyword
Show1
        [Arguments]  ${Host}  ${aclname}   ${interface}  ${traffic}   
        ${OUT}=  Execute In Host  ${Host}  show access-list hitcounts ip ${aclname} interface ${interface} ${traffic} 
        Should Contain  [permit deny]  ${OUT} 

#Used by Show Access List Hit Counts Hit Counts keyword
Show2 
        [Arguments]  ${Host}  ${aclname}   ${interface}
        ${OUT}=  Execute In Host   ${Host}  show access-list hitcounts ip ${aclname} interface ${interface}     
        Should Contain  [permit deny]  ${OUT}

#Used by Show Access List Hit Counts Hit Counts keyword
Show3
        [Arguments]  ${Host}  ${aclname}
        ${OUT}=  Execute In Host  ${Host}  show access-list hitcounts ip ${aclname}
        Should Contain  [permit deny]  ${OUT}


Apply ACL
	[Documentation]  Applies an Access Control List on an Interface

        [Arguments]  ${Host}  ${aclname}   ${interface}  ${traffic}
        Execute In Host Without Return Value  ${Host}  configure terminal
        Execute In Host Without Return Value  ${Host}  interface ${interface}
        Execute In Host Without Return Value  ${Host}  apply access-list ip ${aclname} ${traffic}
        Execute In Host Without Return Value  ${Host}  end
        ${OUT}=  Execute In Host  ${Host}  show running-config
        Should Contain  ${aclname}  ${OUT}
        Should Contain  ${OUT}  apply

Remove ACL Interface
	[Documentation]  Removes an Access Control List on an Interface

       	[Arguments]  ${Host}  ${aclname}   ${interface}  ${traffic}
       	Execute In Host Without Return Value  ${Host}  configure terminal
       	Execute In Host Without Return Value  ${Host}  interface ${interface} 
       	Execute In Host Without Return Value  ${Host}  no apply access-list ip ${aclname} ${traffic}
        Execute In Host Without Return Value  ${Host}  end
        ${OUT}=  Execute In Host  ${Host}  show running-config
        Should Not Contain  ${OUT}  apply

Copy Running Configuration
	[Documentation]  Copies the running-config and startup-config

       	[Arguments]  ${c1}  ${c2}  ${match}
       	Execute In Host Without Return Value  ${Host}  copy ${c1} ${c2}
       	${OUT}=  Execute In Host  ${Host}  show ${c2}
       	Should Contain  ${OUT}  ${match}

Configure Bgp Peer Loopback
	[Documentation]  Configure the EBGP peers using loopback and verify the peers
	
       	[Arguments]  ${Host}  ${asnum}  ${routerID}  ${remoteAsNum}  ${loopbackInterface}  ${loIP}  ${peerloIP}  ${dstNetwork}  ${nextHopIP}
       	Execute In Host Without Return Value  ${Host}  configure terminal
       	Execute In Host Without Return Value  ${Host}  interface ${loopbackInterface}
       	Execute In Host Without Return Value  ${Host}  ip address ${loIP}
       	Execute In Host Without Return Value  ${Host}  exit
       	Execute In Host Without Return Value  ${Host}  ip route ${dstNetwork} ${nextHopIP}
      	Execute In Host Without Return Value  ${Host}  router bgp ${asnum}
      	Execute In Host Without Return Value  ${Host}  ${routerID}
       	Execute In Host Without Return Value  ${Host}  neighbor ${peerloIP} remote-as ${remoteAsNum}
       	Execute In Host Without Return Value  ${Host}  neighbor ${peerloIP} update-source lo
       	Execute In Host Without Return Value  ${Host}  end
	Sleep  30
       	${OUT}=  Execute In Host   ${Host}  show ip bgp summary
	Log  ${OUT}
       	Should Match Regexp  ${OUT}  (?im)Active|(?im)idle|(?im)Connect
       	Run Keyword  Configure Multihop  ${Host}  ${asnum}  ${peerloIP}
       	${OUT}=  Execute In Host   ${Host}  show running-config
	Should Contain  ${OUT}  neighbor ${peerloIP} ebgp-multihop
	Sleep  30
       	${OUT}=  Execute In Host   ${Host}  show ip bgp summary
       	Should Match Regexp  ${OUT}  (?im)Active|(?im)Established

#Used by Configure Bgp Peer Loopback keyword
Configure Multihop
	[Arguments]  ${Host}  ${asnum}  ${peerloIP}
	Execute In Host Without Return Value  ${Host}  configure terminal
        Execute In Host Without Return Value  ${Host}  router bgp ${asnum}
       	Execute In Host Without Return Value  ${Host}  neighbor ${peerloIP} ebgp-multihop
       	Execute In Host Without Return Value  ${Host}  end

Create Bgp MD5
	[Documentation]  Creates the BGP-Peer group and checks for peers  

       	[Arguments]  ${Host}  ${asnum}  ${routerID}  ${password}  ${remoteAsNum}   ${nextHopIP}  ${AdvNetwork}
       	Execute In Host Without Return Value  ${Host}  configure terminal
       	Execute In Host Without Return Value  ${Host}  router bgp ${asnum}
	Execute In Host Without Return Value  ${Host}  ${routerID}
       	Execute In Host Without Return Value  ${Host}  network ${AdvNetwork}
       	Execute In Host Without Return Value  ${Host}  neighbor ${nextHopIP} password ${password}
       	Execute In Host Without Return Value  ${Host}  neighbor ${nextHopIP} remote-as ${remoteAsNum}
       	Execute In Host Without Return Value  ${Host}  end
       	${OUT}=   Execute In Host   ${Host}  show running-config
	Should Contain  ${OUT}  neighbor ${nextHopIP} remote-as ${remoteAsNum}
	Sleep  30
	${OUT}=  Execute In Host   ${Host}  show ip bgp summary 
	Should Match Regexp  ${OUT}  (?im)Active|(?im)Established
       	

Create Bgp Peer Group
	[Documentation]  Creates the BGP-Peer group and checks for peers 

	[Arguments]  ${Host}  ${asnum}  ${routerID}  ${groupName}  ${remoteAsNum}  ${nextHopIP}  ${AdvNetwork}
	Execute In Host Without Return Value  ${Host}  configure terminal
	Execute In Host Without Return Value  ${Host}  router bgp ${asnum}
	Execute In Host Without Return Value  ${Host}  network ${AdvNetwork}
	Execute In Host Without Return Value  ${Host}  neighbor ${groupName} peer-group
	Execute In Host Without Return Value  ${Host}  neighbor ${groupName} remote-as ${remoteAsNum}
	Execute In Host Without Return Value  ${Host}  neighbor ${nextHopIP} peer-group ${groupName}
	Execute In Host Without Return Value  ${Host}  end
	${OUT}=  Execute In Host   ${Host}  show running-config
	Should Contain  ${OUT}  neighbor ${nextHopIP} remote-as ${remoteAsNum}
	Sleep  30
	${OUT}=  Execute In Host   ${Host}  show ip bgp summary
	Should Match Regexp  ${OUT}  (?im)Active|(?im)Established  
       
Create Prefix List
	[Documentation]  Configures EBGP peer and filter routes using route-map outbound

	[Arguments]  ${Host}  ${prefixListName}  ${seqno}  ${action}  ${network}
	Execute In Host Without Return Value  ${Host}  configure terminal
	Execute In Host Without Return Value  ${Host}  ip prefix-list ${prefixListName} seq ${seqno} ${action} ${network}
	Execute In Host Without Return Value  ${Host}  end
	${OUT}=  Execute In Host  ${Host}  show running-config
	Should Contain  ip prefix-list ${prefixListName} seq ${seqno} ${action} ${network}  ${OUT}

Remove Prefix List
	[Documentation]  Removes Prefix list

       	[Arguments]  ${Host}  ${prefixListName}  ${seqno}  ${action}  ${network}
       	Execute In Host Without Return Value  ${Host}  configure terminal
       	Execute In Host Without Return Value  ${Host}  no ip prefix-list ${prefixListName} seq ${seqno} ${action} ${network}
       	Execute In Host Without Return Value  ${Host}  end
       	${OUT}=  Execute In Host   ${Host}  show running-config
       	Should Contain  ip prefix-list ${prefixListName} seq ${seqno} ${action} ${network}  ${OUT}

Create Route Map
	[Documentation]  Creates Route map

	[Arguments]  ${Host}  ${routeMapName}  ${action}  ${seqno}  ${prefixListName}
	Execute In Host Without Return Value  ${Host}  configure terminal  
	Execute In Host Without Return Value  ${Host}  route-map ${routeMapName} ${action} ${seqno}  
	Execute In Host Without Return Value  ${Host}  match ip address prefix-list ${prefixListName} 
	Execute In Host Without Return Value  ${Host}  end  
	${OUT}=  Execute In Host   ${Host}  show running-config 
	Should Contain  ${OUT}  match ip address prefix-list ${prefixListName} 

Remove Route Map
	[Documentation]  Removes Route map

	[Arguments]  ${Host}  ${routeMapName}  ${action}  ${seqno}  ${prefixListName}
	Execute In Host Without Return Value  ${Host}  configure terminal  
	Execute In Host Without Return Value  ${Host}  no route-map ${routeMapName} ${action} ${seqno}   
	Execute In Host Without Return Value  ${Host}  end
	${OUT}=  Execute In Host   ${Host}  show running-config 
	Should Contain  ${OUT}  route-map ${routeMapName} ${action} ${seqno}

Create Bgp Route Map
	[Documentation]  Enables BGP protocol on Router with Route-map

	[Arguments]  ${Host}  ${asnum}  ${routerID}  ${neighbor1}  ${routemap}  ${advertise} 
	Execute In Host Without Return Value  ${Host}  configure terminal  
	Execute In Host Without Return Value  ${Host}  router bgp ${asnum}   
	Execute In Host Without Return Value  ${Host}  ${routerID} 
	Execute In Host Without Return Value  ${Host}  ${neighbor1}
	Execute In Host Without Return Value  ${Host}  ${advertise}
	Execute In Host Without Return Value  ${Host}  ${routemap}
	Execute In Host Without Return Value  ${Host}  end 
	${OUT}=  Execute In Host   ${Host}  show running-config
	Should Contain  ${OUT}  ${routemap}
	Sleep  30
	${OUT}=  Execute In Host   ${Host}  show ip bgp summary
	Should Match Regexp  ${OUT}  (?im)Active|(?im)Established

Create Bgp Prefix List
	[Documentation]  Enables BGP protocol on Router with Prefix List

	[Arguments]  ${Host}  ${asnum}  ${routerID}  ${neighbor1}  ${prefixlist}  ${advertise} 
	Execute In Host Without Return Value  ${Host}  configure terminal  
	Execute In Host Without Return Value  ${Host}  router bgp ${asnum}   
	Execute In Host Without Return Value  ${Host}  ${routerID} 
	Execute In Host Without Return Value  ${Host}  ${neighbor1}
	Execute In Host Without Return Value  ${Host}  ${advertise}
	Execute In Host Without Return Value  ${Host}  ${prefixlist}
	Execute In Host Without Return Value  ${Host}  end 
	${OUT}=  Execute In Host   ${Host}  show running-config
	Should Contain  ${OUT}  ${prefixlist}
	Sleep  30
	${OUT}=  Execute In Host   ${Host}  show ip bgp summary 
	Should Match Regexp  ${OUT}  (?im)Active|(?im)Established

Verify Filtered Network
	[Documentation]  Verifies Filtered Network

	[Arguments]  ${Host}  ${asnum}  ${routerID}  ${filterNetwork}  ${neighbor1}  
	Execute In Host Without Return Value  ${Host}  configure terminal  
	Execute In Host Without Return Value  ${Host}  router bgp ${asnum}   
	Execute In Host Without Return Value  ${Host}  ${routerID} 
	Execute In Host Without Return Value  ${Host}  ${neighbor1}
	Execute In Host Without Return Value  ${Host}  end 
	${OUT}=  Execute In Host   ${Host}  show running-config
	Should Contain  ${OUT}  ${prefixlist}
	Sleep  30
	${OUT}=  Execute In Host   ${Host}  show ip bgp summary 
	Should Match Regexp  ${OUT}  (?im)Active|(?im)Established
	${OUT}=  Execute In Host   ${Host}  show ip bgp 
	Should Contain  ${OUT}  *> ${filterNetwork}
	

Enable Bgp1Nb 
	[Documentation]  Enables Bgp1Nb

	[Arguments]  ${Host}  ${asnum}  ${routerID}  ${neighbor}  ${advertise}=None
	Execute In Host Without Return Value  ${Host}  configure terminal  
	Execute In Host Without Return Value  ${Host}  router bgp ${asnum}   
	Execute In Host Without Return Value  ${Host}  ${routerID} 
	Execute In Host Without Return Value  ${Host}  ${neighbor}
	Run Keyword If  ${asnum}!=None  Execute In Host Without Return Value  ${Host}  ${advertise}
	Execute In Host Without Return Value  ${Host}  end 
	${OUT}=  Execute In Host   ${Host}  show running-config 
	Should Contain  ${OUT}  router bgp ${asnum}

Enable Bgp2Nb 
	[Documentation]  Enables BGP2Nb
	
	[Arguments]  ${Host}  ${asnum}  ${routerID}  ${neighbor1}  ${neighbor2}  ${advertise}=None 
	Execute In Host Without Return Value  ${Host}  configure terminal  
	Execute In Host Without Return Value  ${Host}  router bgp ${asnum}   
	Execute In Host Without Return Value  ${Host}  ${routerID} 
	Execute In Host Without Return Value  ${Host}  ${neighbor1}
	Execute In Host Without Return Value  ${Host}  ${neighbor2}
	Run Keyword If  ${asnum}!=None  Execute In Host Without Return Value  ${Host}  ${advertise}
	Execute In Host Without Return Value  ${Host}  end 
	${OUT}=  Execute In Host   ${Host}  show running-config 
	Should Contain  ${OUT}  router bgp ${asnum}


Enable Bgp3Nb 
	[Documentation]  Enables BGP3Nb

	[Arguments]  ${Host}  ${asnum}  ${routerID}  ${neighbor1}  ${neighbor2}  ${neighbor3}  ${advertise}=None 
	Execute In Host Without Return Value  ${Host}  configure terminal  
	Execute In Host Without Return Value  ${Host}  router bgp ${asnum}   
	Execute In Host Without Return Value  ${Host}  ${routerID} 
	Execute In Host Without Return Value  ${Host}  ${neighbor1}
	Execute In Host Without Return Value  ${Host}  ${neighbor2}
	Execute In Host Without Return Value  ${Host}  ${neighbor2}
	Run Keyword If  ${asnum}!=None  Execute In Host Without Return Value  ${Host}  ${advertise}
	Execute In Host Without Return Value  ${Host}  end 
	${OUT}=  Execute In Host   ${Host}  show running-config 
	Should Contain  ${OUT}  router bgp ${asnum}

Create Filter List
	[Documentation]  Creates the Prefix-list on the Switch 

	[Arguments]  ${Host}  ${asnum}  ${as_path_accesslist}  ${filterlist} 
	Execute In Host Without Return Value  ${Host}  configure terminal 
	Execute In Host Without Return Value  ${Host}  ${as_path_accesslist}  
	Execute In Host Without Return Value  ${Host}  router bgp ${asnum}   
	Execute In Host Without Return Value  ${Host}  ${filterlist}
	Execute In Host Without Return Value  ${Host}  end 
	${OUT}=  Execute In Host   ${Host}  show running-config 
	Should Contain  ${OUT}  ${filterlist}

Remove Filter List
	[Documentation]  Removes the Filter List

	[Arguments]  ${Host}  ${asnum}  ${as_path_accesslist}  ${filterlist} 
	Execute In Host Without Return Value  ${Host}  configure terminal 
	Execute In Host Without Return Value  ${Host}  no ${as_path_accesslist}  
	Execute In Host Without Return Value  ${Host}  router bgp ${asnum}   
	Execute In Host Without Return Value  ${Host}  no ${filterlist}
	Execute In Host Without Return Value  ${Host}  end 
	${OUT}=  Execute In Host   ${Host}  show running-config
	Should Contain  ${OUT}  ${filterlist}

Show Bgp Routes
	[Documentation]  Shows BGP Routes

	[Arguments]  ${Host}  ${asnum}=None
	${OUT}=  Execute In Host   ${Host}  show ip bgp summary
	Should Match Regexp  ${OUT}  (?im)Active|(?im)Established
	${OUT}=  Execute In Host   ${Host}  show ip bgp
	Run Keyword If  ${asnum}!=None  Should Contain  ${OUT}  ${asnum}


Create Loopback
	[Documentation]  Creates Loopback 

       	[Arguments]  ${Host}  ${loopbackInterface}  ${loIP}
       	Execute In Host Without Return Value  ${Host}  configure terminal
       	Execute In Host Without Return Value  ${Host}  interface ${loopbackInterface}
       	Execute In Host Without Return Value  ${Host}  ip address ${loIP}
       	Execute In Host Without Return Value  ${Host}  end
       	${OUT}=  Execute In Host   ${Host}  show running-config
       	Should Contain  ${OUT}  ip address ${loIP}
