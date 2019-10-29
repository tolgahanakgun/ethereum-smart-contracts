pragma solidity >0.5.10;


contract SmartWedding{
    
    string public marriageStatus;
    
    struct Spouse{
        address _address;
        string _firstName;
        string _lastName;
    }
    
    // constant struct types is not implemented yet.
    // So we cannot use const spouse1 here
    Spouse private spouse1;
    Spouse private spouse2;
    Register private time;
    
    struct Guest {
        string _firstName;
        string _lastName;
        bool _acceptance;
        bool _objection; // does the guest object to this marriage
        bool _attendance;// does the guest accept to attend to the ceremony
        address _addressG;
    }
    
    Guest[] guestList;
    uint k = 0;
    uint h=0;
    
    modifier validTime(uint _timeFrom, uint _timeUntil){require(now >= _timeFrom && now < _timeUntil)
    }

    constructor() public{
        spouse1 = Spouse(address(0xCA35b7d915458EF540aDe6068dFe2F44E8fa733c),"sfds","sdfsd");
        spouse2 = Spouse(address(0x111122223333444455556666777788889999aAaa),"sfds","sdfsd");
        marriageStatus = "Not married yet";
    }   
    
    function setDateTime(uint _newTime) public onlySpouse returns (uint memory){
        time = newTime;
    }

    function getSpouses() public view returns (string memory) {
        return string(abi.encodePacked("Spouse 1:=>","address:",
            "a valid address"," name:",spouse1._firstName," ",spouse1._lastName,"\n",
            "Spouse 2:=>","address:",
            "a valid address"," name:",spouse2._firstName," ",spouse2._lastName));
    }
    
    modifier onlySpouse(){
        require(msg.sender == spouse1._address || msg.sender == spouse2._address, "Only spouses can add a guest!");
        _;
    }
    
    // TODO cand add guest before ceremony starts
    function addGuest(string memory _firstName, string memory _lastName, address _address) public onlySpouse returns (bool){
        // check the ceremony date, if after the date disallow this function
        // default _acceptance and _objection values are false
        guestList.push(Guest(_firstName, _lastName, false, false, false, _address));
        return true;
    }
    
    modifier onlyGuest(){
        for (k; k<guestList.length; k++) {
            if (guestList[k]._addressG == msg.sender)
                break;
        }
        require(msg.sender == guestList[k]._addressG, "Only for valid guests!");
        _;                    
    }
    
    //Check guests list
    // Need to be fixed, it doesn't read bool nor address values. It can't concatenate strings so it shows only one guest.
    function getGuests() public view returns (string memory) {
        /*for (uint h=0; h<guestList.length; h++) {*/
        return string(abi.encodePacked("Guest ", "=>", "Name:",guestList[h]._firstName, " ",guestList[h]._lastName, " Acceptance: ", guestList[h]._acceptance, " Attendance: ",
        guestList[h]._attendance, " Objection: ", guestList[h]._objection,"\n"));
        
    }
    
    function checkAcceptance() public onlyGuest returns(string memory){
        // check the ceremony date, if after the date disallow this function
        guestList[k]._acceptance == true;
        return string("See you at the wedding");
    }
    
    function checkAttendance() public onlyGuest returns(string memory){
        // check the ceremony date, if after the date disallow this function
        guestList[k]._attendance == true;
        return string("See you inside");
    }


    function checkObjection() public onlyGuest returns(string memory){
        // check the ceremony date, if after the date disallow this function
        guestList[k]._objection == true;
        return string("How dare you");
    }


    function toString(address x) internal pure returns (string memory) {
        bytes memory b = new bytes(20);
        for (uint i = 0; i < 20; i++)
            b[i] = byte(uint8(uint(x) / (2**(8*(19 - i)))));
        return string(b);
    }
    
    // generate a random number for guest tickets
    function randomNumber() public view returns (uint) {
        return uint(keccak256(abi.encode(msg.sender, now,"a very secure salt value")));
    }



    modifier onlyLoggedInGuest(){
        /*
         * There is no way to check of an existance of a key in solidity mapping
         * so we can just use _attendance and _acceptance fields to check 
         * a guest is included in the map and accepted the invitation
        **/
        // TODO after issue #9 is resolved, also _attendance of a guest will be checked
        require(guests[msg.sender]._acceptance /*&& guests[msg.sender]._attendance*/, "Only logged in guests can vote!");
        // TODO after issue #5 is resolved time will be checked whether it is a proper time for voting or not
        // require(checkTime(), "Voting starts at wedding time and ends in 30 min");
        //need to find difference in timestamp for a day/hours to estimate the _
        _;
    }
    
    function objectMarriage(bool _objectMarriage) public onlyLoggedInGuest {
        //return marriageStatus?
        guests[msg.sender]._objection = _objectMarriage;
        if(_objectMarriage){
                    marriageStatus = "Someone objected this marriage and terminated.";
        }
    }

}
