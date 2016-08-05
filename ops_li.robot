*** Settings ***
Resource    ./Resources/OpsLibrary.robot
Suite Setup  Initialize
Suite Teardown  Close all connections

*** Variables ***
${XML}	      ops.params

*** Test Cases ***
Test Case 1
	${asnum1}=  XML Parser  ${XML}  CASE1  asnum1
	${routerID}=  XML Parser  ${XML}  CASE1  routerID
	${neighbor_1_asnum1}=  XML Parser  ${XML}  CASE1  neighbor_1_asnum1
	${advertise}=  XML Parser  ${XML}  CASE1  advertise 
	Enable Bgp1Nb  FAB05  ${asnum1}  ${routerID}  ${neighbor_1_asnum1}  ${advertise}
	Remove BGP  fab05  ${asnum1}    

Test Case 2
	${asnum1}=  XML Parser  ${XML}  CASE2  asnum1
	${routerID1}=  XML Parser  ${XML}  CASE2  routerID1
	${neighbor_1_asnum1}=  XML Parser  ${XML}  CASE2  neighbor_1_asnum1
	${advertise}=  XML Parser  ${XML}  CASE2  advertise1
	Enable Bgp1Nb  FAB05  ${asnum1}  ${routerID1}  ${neighbor_1_asnum1}  ${advertise}
	
	${asnum2}=  XML Parser  ${XML}  CASE2  asnum2
	${routerID2}=  XML Parser  ${XML}  CASE2  routerID2
	${neighbor_1_asnum2}=  XML Parser  ${XML}  CASE2  neighbor_1_asnum2
	${neighbor_2_asnum2}=  XML Parser  ${XML}  CASE2  neighbor_2_asnum2
	${advertise}=  XML Parser  ${XML}  CASE2  advertise2 
	Enable Bgp2Nb  CSW01  ${asnum2}  ${routerID1}  ${neighbor_1_asnum1}  ${neighbor_2_asnum2}  ${advertise}  

	${asnum3}=  XML Parser  ${XML}  CASE2  asnum3
	${routerID3}=  XML Parser  ${XML}  CASE2  routerID3
	${neighbor_1_asnum3}=  XML Parser  ${XML}  CASE2  neighbor_1_asnum3
	${advertise}=  XML Parser  ${XML}  CASE2  advertise3 
	Enable Bgp1Nb  ASW01  ${asnum3}  ${routerID3}  ${neighbor_1_asnum3}  ${advertise}

	Sleep  10
	
	Show Bgp Routes  FAB05
	Show Bgp Routes  CSW01
	Show Bgp Routes  ASW01

	Remove BGP  FAB05  ${asnum1} 
	Remove BGP  CSW01  ${asnum2} 
	Remove BGP  ASW01  ${asnum3}


