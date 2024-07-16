@isTest
private class FSLRouteSTMOperationTest {
    
    @isTest
    static void myUnitTest() {
        
        List<User> mechanicUsers = UTIL_TestDataFactory.createUsers('Field Service Mechanic',2);
        insert mechanicUsers;
        Group grp = new Group(Name = 'GrpTest01',DeveloperName='GrpTest01');
        insert grp;
        GroupMember grpMembr=new GroupMember(GroupId = grp.Id , UserOrGroupId = mechanicUsers[0].Id);
        insert grpMembr;
        
        FSLRouteSTMOperation.FlowInputs flwInput1 =new FSLRouteSTMOperation.FlowInputs();
        flwInput1.userId = mechanicUsers[0].Id;
        flwInput1.operationType='Create';
        flwInput1.serviceTerritoryName='GrpTest01';
        Test.startTest();
        FSLRouteSTMOperation.handleNewSTMOperation(new List<FSLRouteSTMOperation.FlowInputs> {flwInput1});
        flwInput1.operationType='Delete';
        FSLRouteSTMOperation.handleNewSTMOperation(new List<FSLRouteSTMOperation.FlowInputs> {flwInput1});
        FSLRouteSTMOperation.FlowInputs flwInput2 = flwInput1;
        flwInput2.userId = mechanicUsers[1].Id;
        FSLRouteSTMOperation.handleNewSTMOperation(new List<FSLRouteSTMOperation.FlowInputs> {flwInput1,flwInput2});
        Test.stopTest();
    }
}