*** Settings ***
Resource    ./Resources/OpsLibrary.robot
Suite Setup  Initialize  devices.params  ops.params
Suite Teardown  Close all connections

*** Variables ***


*** Test Cases ***
Verifies the BGP CLI commands given are getting committed to run config
	[Documentation]  Verifies the BGP CLI commands given are getting committed to run config
	${asnum1}=  XML Parser  CASE1  asnum1
	${routerID}=  XML Parser  CASE1  routerID
	${neighbor_1_asnum1}=  XML Parser  CASE1  neighbor_1_asnum1
	${advertise}=  XML Parser  General  advertise 
	Enable Bgp1Nb  FAB05  ${asnum1}  ${routerID}  ${neighbor_1_asnum1}  ${advertise}
	Remove BGP  FAB05  ${asnum1}    

Configures direct EBGP peer and verify the peer
	[Documentation]  Configures direct EBGP peer and verify the peer
	${asnum1}=  XML Parser  CASE2  asnum1
	${routerID1}=  XML Parser  CASE2  routerID1
	${neighbor_1_asnum1}=  XML Parser  CASE2  neighbor_1_asnum1
	${advertise}=  XML Parser  General  advertise 
	Enable Bgp1Nb  FAB05  ${asnum1}  ${routerID1}  ${neighbor_1_asnum1}  ${advertise}
	
	${asnum2}=  XML Parser  CASE2  asnum2
	${routerID2}=  XML Parser  CASE2  routerID2
	${neighbor_1_asnum2}=  XML Parser  CASE2  neighbor_1_asnum2
	${neighbor_2_asnum2}=  XML Parser  CASE2  neighbor_2_asnum2
	Enable Bgp2Nb  CSW01  ${asnum2}  ${routerID2}  ${neighbor_1_asnum2}  ${neighbor_2_asnum2}  ${advertise}  

	${asnum3}=  XML Parser  CASE2  asnum3
	${routerID3}=  XML Parser  CASE2  routerID3
	${neighbor_1_asnum3}=  XML Parser  CASE2  neighbor_1_asnum3
	Enable Bgp1Nb  ASW01  ${asnum3}  ${routerID3}  ${neighbor_1_asnum3}  ${advertise}
	
	Sleep  2
	Show Bgp Routes  FAB05
	Show Bgp Routes  CSW01
	Show Bgp Routes  ASW01

	Remove BGP  FAB05  ${asnum1} 
	Remove BGP  CSW01  ${asnum2} 
	Remove BGP  ASW01  ${asnum3}

Configures EBGP peer using loopback with Ebgp-multihop argument and verify the peer
	[Documentation]  Configures EBGP peer using loopback with Ebgp-multihop argument and verify the peer
	${asnum1}=  XML Parser  CASE3/step1  asnum
	${routerID1}=  XML Parser  CASE3/step1  routerID1
	${remoteAsNum}=  XML Parser  CASE3/step1  remoteAsNum
	${loopbackInterface1}=  XML Parser  CASE3/step1  loopbackInterface
	${loIP}=  XML Parser  CASE3/step1  loIP
	${peerloIP}=  XML Parser  CASE3/step1  peerloIP
	${dstNetwork1}=  XML Parser  CASE3/step1  dstNetwork
	${nextHopIP1}=  XML Parser  CASE3/step1  nextHopIP
	Configure Bgp Peer Loopback  FAB05  ${asnum1}  ${routerID1}  ${remoteAsNum}  ${loopbackInterface1}  ${loIP}  ${peerloIP}  ${dstNetwork1}  ${nextHopIP1}

        ${asnum2}=  XML Parser  CASE3/step2  asnum
	${routerID2}=  XML Parser  CASE3/step2  routerID2
	${remoteAsNum}=  XML Parser  CASE3/step2  remoteAsNum
	${loopbackInterface2}=  XML Parser  CASE3/step2  loopbackInterface
	${loIP}=  XML Parser  CASE3/step2  loIP
	${peerloIP}=  XML Parser  CASE3/step2  peerloIP
	${dstNetwork2}=  XML Parser  CASE3/step2  dstNetwork
	${nextHopIP2}=  XML Parser  CASE3/step2  nextHopIP
	Configure Bgp Peer Loopback  CSW01  ${asnum2}  ${routerID1}  ${remoteAsNum}  ${loopbackInterface2}  ${loIP}  ${peerloIP}  ${dstNetwork2}  ${nextHopIP2}
        
        Remove BGP  FAB05  ${asnum1} 
	Remove BGP  CSW01  ${asnum2}

        Remove Interface  FAB05  ${loopbackInterface1}
        Remove Interface  CSW01  ${loopbackInterface2}

        Remove Static Route  FAB05  ${dstNetwork1}  ${nextHopIP1}
        Remove Static Route  CSW01  ${dstNetwork2}  ${nextHopIP2}


Configure EBGP peer with MD5 authentication and verify the peer is up
	[Documentation]  Configure EBGP peer with MD5 authentication and verify the peer is up
        ${asnum1}=  XML Parser  CASE4/step1  asnum
	${routerID1}=  XML Parser  CASE4/step1  routerID1
        ${password}=  XML Parser  CASE4/step1  password
	${remoteAsNum}=  XML Parser  CASE4/step1  remoteAsNum
        ${nextHopIP}=  XML Parser  CASE4/step1  nextHopIP
	${AdvNetwork}=  XML Parser  CASE4/step1  AdvNetwork
	Create Bgp MD5  FAB05  ${asnum1}  ${routerID1}  ${password}  ${remoteAsNum}  ${nextHopIP}  ${AdvNetwork}

        ${asnum2}=  XML Parser  CASE4/step2  asnum
	${routerID2}=  XML Parser  CASE4/step2  routerID2
        ${password}=  XML Parser  CASE4/step2  password
	${remoteAsNum}=  XML Parser  CASE4/step2  remoteAsNum
        ${nextHopIP}=  XML Parser  CASE4/step2  nextHopIP
	${AdvNetwork}=  XML Parser  CASE4/step2  AdvNetwork
	Create Bgp MD5  CSW01  ${asnum2}  ${routerID2}  ${password}  ${remoteAsNum}  ${nextHopIP}  ${AdvNetwork}
        
        Remove BGP  FAB05  ${asnum1} 
	Remove BGP  CSW01  ${asnum2}

Configures EBGP peer using peer-group and verify the peer
	[Documentation]  Configures EBGP peer using peer-group and verify the peer
        ${asnum1}=  XML Parser  CASE5/step1  asnum
	${routerID1}=  XML Parser  CASE5/step1  routerID1
        ${groupName}=  XML Parser  CASE5/step1  groupName
	${remoteAsNum}=  XML Parser  CASE5/step1  remoteAsNum
        ${nextHopIP}=  XML Parser  CASE5/step1  nextHopIP
	${AdvNetwork}=  XML Parser  CASE5/step1  AdvNetwork
	Create Bgp Peer Group  FAB05  ${asnum1}  ${routerID1}  ${groupName}  ${remoteAsNum}  ${nextHopIP}  ${AdvNetwork}

        ${asnum2}=  XML Parser  CASE5/step2  asnum
	${routerID2}=  XML Parser  CASE5/step2  routerID2
        ${groupName}=  XML Parser  CASE5/step2  groupName
	${remoteAsNum}=  XML Parser  CASE5/step2  remoteAsNum
        ${nextHopIP}=  XML Parser  CASE5/step2  nextHopIP
	${AdvNetwork}=  XML Parser  CASE5/step2  AdvNetwork
	Create Bgp Peer Group  CSW01  ${asnum2}  ${routerID2}  ${groupName}  ${remoteAsNum}  ${nextHopIP}  ${AdvNetwork}

        Remove BGP  FAB05  ${asnum1} 
	Remove BGP  CSW01  ${asnum2}

Shuts down the neighbor and verify that neighbor goes down
	[Documentation]  Shuts down the neighbor and verify that neighbor goes down
        ${asnum1}=  XML Parser  CASE7  asnum1
	${routerID1}=  XML Parser  CASE7  routerID1
	${neighbor_1_asnum1}=  XML Parser  CASE7  neighbor_1_asnum1
	${advertise}=  XML Parser  General  advertise 
	Enable Bgp1Nb  FAB05  ${asnum1}  ${routerID1}  ${neighbor_1_asnum1}  ${advertise}

        ${asnum2}=  XML Parser  CASE7  asnum2
	${routerID2}=  XML Parser  CASE7  routerID2
	${neighbor_1_asnum2}=  XML Parser  CASE7  neighbor_1_asnum2
	${advertise}=  XML Parser  General  advertise 
	Enable Bgp1Nb  CSW01  ${asnum2}  ${routerID2}  ${neighbor_1_asnum2}  ${advertise}

	Sleep  30
        Show Bgp Routes  FAB05
	Show Bgp Routes  CSW01
        
        ${nextHopIP}=  XML Parser  CASE7  nextHopIP
	${state1}=  XML Parser  CASE7  state1
        Change Neighbor State  FAB05  ${asnum1}  ${nextHopIP}  ${state1}
        
	${state2}=  XML Parser  CASE7  state2
        Change Neighbor State  FAB05  ${asnum1}  ${nextHopIP}  ${state2}

        Remove BGP  FAB05  ${asnum1} 
	Remove BGP  CSW01  ${asnum2}

