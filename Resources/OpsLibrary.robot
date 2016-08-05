*** Settings ***
Documentation   This file contains the library for making connection to Openswitch
...             and execute the commands in the OPS vtysh shell.
Library		OperatingSystem
Library         String
Library         Collections
Library         SSHLibrary
Library         XML

*** Variables ***
${HOSTS}

*** Keywords ***
Initialize
        [Documentation]  This function is to initialize the host information from the 
	...              device param file
	${HOSTS}=  Create Dictionary
	Set Suite Variable  ${HOSTS}
	${FILE_CONTENT}=  OperatingSystem.Get File  devices.param
	@{Lines}=  Split To Lines  ${FILE_CONTENT}
	Remove From List  ${Lines}  0
	: FOR  ${Line}  IN  @{Lines}
	\  @{COLUMNS}=  Split String  ${Line}  separator=,
	\  ${Host}=     Get From List  ${COLUMNS}  0
	\  Set To Dictionary   ${HOSTS}  ${Host}=${Line}  ${Host}=${Line}

Open Connection To Device
        [Documentation]  This function is to make a connection to the Host device
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
	Set Client Configuration  prompt=#  timeout=5 
	Login  ${User}  ${Pass}
	Write  vtysh

XML Parser
	[Arguments]   ${XML}   ${PATH}   ${EXACT}
	${root} =  Parse XML   ${XML} 			
	${first} =  Get Element  ${root}   ${PATH}
	${two} =   Get Element  ${first}   ${EXACT}
	${retrunValue}=  Strip String  ${two.text} 	
	[RETURN]  ${retrunValue}


Connect To Host
        [Documentation]  This function is to check for the connection is already available
	...              for the device or need to create a new connection
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
	[Return]  ${output}

Execute In Host
        [Documentation]  This function is to execute a command in the Host with 2s delay
	[Arguments]  ${Host}  ${Command}  	
	${output}=  Execute Command In Host  ${Host}  ${Command}  ${delay}=2s
	[Return]  ${output}

Configure IP
	[Documentation]  This function is to configure the IP for the interface
	[Arguments]  ${Host}  ${Interface}  ${IP}  ${status}=up
	Execute Command In Host  ${Host}  configure terminal  
	Execute Command In Host  ${Host}  interface ${Interface}  
	Execute Command In Host  ${Host}  ip address ${IP}
	Execute Command In Host  ${Host}  no shutdown
	Execute Command In Host  ${Host}  end
	${output}=  Execute Command In Host  ${Host}  sh inter ${Interface}  2s
	Should Contain  ${output}  Interface ${Interface} is ${status}

Create Route Map
	[Arguments]  ${Host}  ${routeMapName}  ${action}  ${seqno}  ${prefixListName}
	Execute Command In Host  ${Host}  configure terminal  
	Execute Command In Host  ${Host}  route-map ${routeMapName} ${action} ${seqno}  
	Execute Command In Host  ${Host}  match ip address prefix-list ${prefixListName} 
	Execute Command In Host  ${Host}  end  
	${OUT}=  Execute Command In Host  ${Host}  show running-config  2s
	Should Contain  ${OUT}  match ip address prefix-list ${prefixListName} 

Remove Route Map
	[Arguments]  ${Host}  ${routeMapName}  ${action}  ${seqno}  ${prefixListName}
	Execute Command In Host  ${Host}  configure terminal  
	Execute Command In Host  ${Host}  no route-map ${routeMapName} ${action} ${seqno}   
	Execute Command In Host  ${Host}  end
	${OUT}=  Execute Command In Host  ${Host}  show running-config  2s 
	Should Contain  ${OUT}  route-map ${routeMapName} ${action} ${seqno}

Create Bgp Route Map
	[Arguments]  ${Host}  ${asnum}  ${routerID}  ${neighbor1}  ${routemap}  ${advertise} 
	Execute Command In Host  ${Host}  configure terminal  
	Execute Command In Host  ${Host}  router bgp ${asnum}   
	Execute Command In Host  ${Host}  ${routerID} 
	Execute Command In Host  ${Host}  ${neighbor1}
	Execute Command In Host  ${Host}  ${advertise}
	Execute Command In Host  ${Host}  ${routemap}
	Execute Command In Host  ${Host}  end 
	${OUT}=  Execute Command In Host  ${Host}  show running-config  2s
	Should Contain  ${OUT}  ${routemap}
	${OUT}=  Execute Command In Host  ${Host}  show ip bgp summary  2s
	Should Match Regexp  ${OUT}  (?im)Active|(?im)Established

Remove BGP
        [Arguments]  ${Host}  ${asnum}
     	Execute Command In Host  ${Host}  configure terminal
	Execute Command In Host  ${Host}  no router bgp ${asnum}
	Execute Command In Host  ${Host}  end
	${result}=  Execute Command In Host  ${Host}  show running-config  5s
	Should Not Contain  ${result}  ${asnum}

Create Bgp Prefix List
	[Arguments]  ${Host}  ${asnum}  ${routerID}  ${neighbor1}  ${prefixlist}  ${advertise} 
	Execute Command In Host  ${Host}  configure terminal  
	Execute Command In Host  ${Host}  router bgp ${asnum}   
	Execute Command In Host  ${Host}  ${routerID} 
	Execute Command In Host  ${Host}  ${neighbor1}
	Execute Command In Host  ${Host}  ${advertise}
	Execute Command In Host  ${Host}  ${prefixlist}
	Execute Command In Host  ${Host}  end 
	${OUT}=  Execute Command In Host  ${Host}  show running-config  2s
	Should Contain  ${OUT}  ${prefixlist}
	${OUT}=  Execute Command In Host  ${Host}  show ip bgp summary  2s
	Should Match Regexp  ${OUT}  (?im)Active|(?im)Established

Verify Filtered Network
	[Arguments]  ${Host}  ${asnum}  ${routerID}  ${filterNetwork}  ${neighbor1}  
	Execute Command In Host  ${Host}  configure terminal  
	Execute Command In Host  ${Host}  router bgp ${asnum}   
	Execute Command In Host  ${Host}  ${routerID} 
	Execute Command In Host  ${Host}  ${neighbor1}
	Execute Command In Host  ${Host}  end 
	${OUT}=  Execute Command In Host  ${Host}  show running-config  2s
	Should Contain  ${OUT}  ${prefixlist}
	${OUT}=  Execute Command In Host  ${Host}  show ip bgp summary  2s
	Should Match Regexp  ${OUT}  (?im)Active|(?im)Established
	${OUT}=  Execute Command In Host  ${Host}  show ip bgp  2s
	Should Contain  ${OUT}  *> ${filterNetwork}
	

Enable Bgp1Nb 
	[Arguments]  ${Host}  ${asnum}  ${routerID}  ${neighbor}  ${advertise}=None
	Execute Command In Host  ${Host}  configure terminal  
	Execute Command In Host  ${Host}  router bgp ${asnum}   
	Execute Command In Host  ${Host}  ${routerID} 
	Execute Command In Host  ${Host}  ${neighbor}
	Run Keyword If  ${asnum}!="None"  Execute Command In Host  ${Host}  ${advertise}
	Execute Command In Host  ${Host}  end 
	${OUT}=  Execute Command In Host  ${Host}  show running-config  2s
	Should Contain  ${OUT}  router bgp ${asnum}

Enable Bgp2Nb 
	[Arguments]  ${Host}  ${asnum}  ${routerID}  ${neighbor1}  ${neighbor2}  ${advertise}=None 
	Execute Command In Host  ${Host}  configure terminal  
	Execute Command In Host  ${Host}  router bgp ${asnum}   
	Execute Command In Host  ${Host}  ${routerID} 
	Execute Command In Host  ${Host}  ${neighbor1}
	Execute Command In Host  ${Host}  ${neighbor2}
	Run Keyword If  ${asnum}!="None"  Execute Command In Host  ${Host}  ${advertise}
	Execute Command In Host  ${Host}  end 
	${OUT}=  Execute Command In Host  ${Host}  show running-config  2s
	Should Contain  ${OUT}  router bgp ${asnum}
	Sleep  5

Enable Bgp3Nb 
	[Arguments]  ${Host}  ${asnum}  ${routerID}  ${neighbor1}  ${neighbor2}  ${neighbor3}  ${advertise}=None 
	Execute Command In Host  ${Host}  configure terminal  
	Execute Command In Host  ${Host}  router bgp ${asnum}   
	Execute Command In Host  ${Host}  ${routerID} 
	Execute Command In Host  ${Host}  ${neighbor1}
	Execute Command In Host  ${Host}  ${neighbor2}
	Execute Command In Host  ${Host}  ${neighbor2}
	Run Keyword If  ${asnum}!="None"  Execute Command In Host  ${Host}  ${advertise}
	Execute Command In Host  ${Host}  end 
	${OUT}=  Execute Command In Host  ${Host}  show running-config  2s
	Should Contain  ${OUT}  router bgp ${asnum}
	Sleep  5

Create Filter List
	[Arguments]  ${Host}  ${asnum}  ${as_path_accesslist}  ${filterlist} 
	Execute Command In Host  ${Host}  configure terminal 
	Execute Command In Host  ${Host}  ${as_path_accesslist}  
	Execute Command In Host  ${Host}  router bgp ${asnum}   
	Execute Command In Host  ${Host}  ${filterlist}
	Execute Command In Host  ${Host}  end 
	${OUT}=  Execute Command In Host  ${Host}  show running-config  2s
	Should Contain  ${OUT}  ${filterlist}

Remove Filter List
	[Arguments]  ${Host}  ${asnum}  ${as_path_accesslist}  ${filterlist} 
	Execute Command In Host  ${Host}  configure terminal 
	Execute Command In Host  ${Host}  no ${as_path_accesslist}  
	Execute Command In Host  ${Host}  router bgp ${asnum}   
	Execute Command In Host  ${Host}  no ${filterlist}
	Execute Command In Host  ${Host}  end 
	${OUT}=  Execute Command In Host  ${Host}  show running-config  2s
	Should Contain  ${OUT}  ${filterlist}

Show Bgp Routes
	[Arguments]  ${Host}  ${asnum}=None
	${OUT}=  Execute Command In Host  ${Host}  show ip bgp summary  2s
	Should Match Regexp  ${OUT}  (?im)Active|(?im)Established
	${OUT}=  Execute Command In Host  ${Host}  show ip bgp  2s
	Run Keyword If  ${asnum}!=None  Should Contain  ${OUT}  ${asnum}

Ping
	[Arguments]  ${Host}  ${IP}  ${Repetitions}=""
	${result}=  Run Keyword If  ${Repetitions} > 0  Execute Command In Host  ${Host}  ping ${IP} repetitions ${Repetitions}  15s  
	${result}=  Run Keyword If  ${Repetitions}==""  Execute Command In Host  ${Host}  ping ${IP}  3s
	log  ${result}
	Should Contain  ${result}  0% packet loss

Show Version
	[Arguments]  ${Host}
	${result}=  Execute Command In Host  ${Host}  show version  2s
	Should Contain  ${result}  OpenSwitch 0.4.0

ShowIpInterface
	[Arguments]  ${Host}  ${Interface}
	${result}=  Execute Command In Host  ${Host}  show ip interface ${Interface}  2s
	Should Match Regexp  ${result}  IPv4 address \\d*.\\d*.\\d*.\\d*\\/\\d*

ShowInterfaceBrief
	[Arguments]  ${Host}  
	${result}=  Execute Command In Host  ${Host}  show interface brief  2s
	log  ${result}
	Should Contain  ${result}  up 
	
ShowBgpSummary
	[Arguments]  ${Host}  ${value}=1
	${result}=  Execute Command In Host  ${Host}  show ip bgp summary  2s
	${Match}  ${group1}   ${group2}=
	...	   Should Match Regexp  ${result}  (Peers )(\\d*)
	${value}=  Convert To Integer  ${group2}
	${count}=  Count  ${Host}  ${value}  ${result}
	${value1}=  Convert To Integer  ${count}
	Run Keyword If  ${value1}==1  Log  TRUE
	Run Keyword If  ${value}!=1  Log  FALSE
	
Count
	[Arguments]  ${Host}  ${value}  ${result}
	${count}=  Should Contain  ${result}  Established
	Run Keyword If  ${count}=="None"  ${value}=1
	[RETURN]  ${value}
	
ShowRunningConfiguration
	[Arguments]  ${Host}  ${result}=""
	${result}=  Execute Command In Host  ${Host}  show running-config  2s
	Should Not Be Empty  ${result}

showStartupConfiguration
	[Arguments]  ${Host}
	${result}=  Execute Command In Host  ${Host}  show startup-config  8s
	Should Not Be Empty  ${result}
	

TraceRoute
	[Arguments]  ${Host}  ${IP}
	${result}=  Execute Command In Host  ${Host}   traceroute ${IP}  3s
	Should Match Regexp  ${result}  \\d*.\\d*ms

ChangeInterfaceState
	[Arguments]  ${Host}  ${Interface}  ${State}=""
	Execute Command In Host  ${Host}  configure terminal  
	Execute Command In Host  ${Host}  interface ${Interface} 
	Run Keyword If  '${State}'=='up'  Execute Command In Host  ${Host}  no shutdown
	Run Keyword If  '${State}'=='down'  Execute Command In Host  ${Host}  shut
	Execute Command In Host  ${Host}  end  5s
	${result}=  Execute Command In Host  ${Host}  show interface ${Interface}
	Should Contain  ${result}  Interface ${Interface} is ${state}

Add static route
	[Arguments]  ${Host}  ${DestNetwork}  ${NextHopIP}
	Execute Command In Host  ${Host}  configure terminal
	Execute Command In Host  ${Host}  ip route ${DestNetwork} ${NextHopIP}
	Execute Command In Host  ${Host}  end  5s
	${result}=  Execute Command In Host  ${Host}  show running-config
	Should Contain  ${result}  ip route ${DestNetwork} ${NextHopIP}

Remove StaticRoute
	[Arguments]  ${Host}  ${destNetwork}  ${nextHopIP}  
	Execute Command In Host  ${Host}  configure terminal
	Execute Command In Host  ${Host}  no ip route ${destNetwork} ${nextHopIP}
	Execute Command In Host  ${Host}  end
	${result}=  Execute Command In Host  ${Host}  show running-config  15s
	Should Contain  ${result}  ip route ${destNetwork} ${nextHopIP}


####srivalli###
Clear BGPNeighbor
    [Arguments]  ${Host}  ${NeighborIP}=""  ${ASNum}=""
    Run Keyword If  '${NeighborIP}'!=""  Execute Command In Host  ${Host}  clear bgp ${NeighborIP} soft in  
    Execute Command In Host  ${Host}  clear bgp ${NeighborIP} soft out
    Run Keyword If  '${ASNum}'!=""  Execute Command In Host  ${Host}  clear bgp ${ASNum} soft in
    Execute Command In Host  ${Host}  clear bgp ${ASNum} soft out	
    Run Keyword If  '${ASNum}'=="" and '${NeighborIP}'==""  Execute Command In Host  ${Host}  clear bgp * soft in
    Execute Command In Host  ${Host}  clear bgp * soft out	
    Execute Command In Host  ${Host}  show ip bgp summary  3s

#####hari####
Clear Accesslist Hit Counts
        [Arguments]  ${Host}  ${aclname}=""   ${interface}=""  ${traffic}=""
        [Documentation]  Clears access list hitcounts passes if Hitcounts are cleared fails if the list is not cleared
        Run Keyword If  ${aclname}!=""  Traffic Available  ${Host}  ${interface}  ${traffic}
        Run Keyword If  ${aclname}==""  Traffic NotAvailable  ${Host}
Traffic Available
        [Arguments]  ${Host}  ${interface}  ${traffic}
        Run Keyword If  ${traffic}!=""  Clear Hitcount  ${Host}  ${aclname}  ${interface}  ${traffic}
        Run Keyword If  ${interface}!=""  Clear Hitcount Interface   ${Host}  ${aclname}   ${interface}
        Run Keyword If  '${interface}'=="" and '${traffic}'==""   Clear Hitcount2  ${Host} 
Clear Hitcount
        [Arguments]  ${Host}  ${aclname}  ${interface}  ${traffic}
        Execute Command In Host  ${Host}  clear access-list hitcounts ip ${aclname} interface ${interface} ${traffic}
        ${OUT}=  Execute Command In Host  ${Host}  show access-list hitcounts ip ${aclname} interface ${interface} ${traffic}
        Should Contain  ${OUT}  permit
Clear Hitcount Interface
        [Arguments]  ${Host}  ${aclname}   ${interface} 
        Execute Command In Host  ${Host}  clear access-list hitcounts ip ${aclname} interface ${interface}    
        ${OUT}=  Execute Command In Host  ${Host}  show access-list hitcounts ip ${aclname} interface ${interface}
        Should Contain  ${OUT}  permit
Clear Hitcount2
        [Arguments]  ${Host}
        Execute Command In Host  ${Host}  clear access-list hitcounts all
        ${OUT}=  Execute Command In Host  ${Host}  show access-list hitcounts ip
        Should Contain  ${OUT}  [permit deny]
Traffic Not Available
        [Arguments]  ${Host}
        ${OUT}=  Execute Command In Host  ${Host}  clear access-list hitcounts all
        Should Contain  ${OUT}  \#




