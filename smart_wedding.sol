pragma solidity >0.5.10;


contract SmartWedding{
    
    string public marriageStatus;
    uint public weddingTime;
    
    struct Spouse{
        address _address;
        string _firstName;
        string _lastName;
        bool _cancelWedding;
    }
    
    // constant struct types is not implemented yet.
    // So we cannot use const spouse1 here
    Spouse private spouse1;
    Spouse private spouse2;
    bool guestObjected = false; 
    
/* The code regarding timestamp to Date and Time conversion is taken from the Library BokkyPooBahsDateTimeLibrary found on Github via
 https://github.com/bokkypoobah/BokkyPooBahsDateTimeLibrary/blob/53a99d2ca81270bcb4047c2ba342ad45e0fa17fd/contracts/BokkyPooBahsDateTimeLibrary.sol*/
    uint constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint constant SECONDS_PER_HOUR = 60 * 60;
    uint constant SECONDS_PER_MINUTE = 60;
    int constant OFFSET19700101 = 2440588;

    uint constant DOW_MON = 1;
    uint constant DOW_TUE = 2;
    uint constant DOW_WED = 3;
    uint constant DOW_THU = 4;
    uint constant DOW_FRI = 5;
    uint constant DOW_SAT = 6;
    uint constant DOW_SUN = 7;


    function _daysToDate(uint _days) internal pure returns (uint year, uint month, uint day) {
        int __days = int(_days);

        int L = __days + 68569 + OFFSET19700101;
        int N = 4 * L / 146097;
        L = L - (146097 * N + 3) / 4;
        int _year = 4000 * (L + 1) / 1461001;
        L = L - 1461 * _year / 4 + 31;
        int _month = 80 * L / 2447;
        int _day = L - 2447 * _month / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        year = uint(_year);
        month = uint(_month);
        day = uint(_day);
    }

    function timestampToDateTime(uint timestamp) internal pure returns (uint year, uint month, uint day, uint hour, uint minute, uint second) {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
        secs = secs % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
        second = secs % SECONDS_PER_MINUTE;
    }
// Here the reused code ends.

    function getWeddingDateTime() public view returns (uint year, uint month, uint day, uint hour, uint minute, uint second){
        (year, month, day, hour, minute, second)=timestampToDateTime(weddingTime);
    }
    struct Guest {
        string _firstName;
        string _lastName;
        bool _acceptance;
        bool _objection; // does the guest object to this marriage
        bool _attendance;// does the guest accept to attend to the ceremony
        address _addressG;
        bool _vote;
    }
    
    Guest[] public guestList;
    uint k;
    uint h = 0 ;
    uint count = 0;
    uint validTotalCount = 0;
    uint votingLimit;
    
    modifier validTime(uint _timeFrom, uint _timeUntil, string memory _errorMessage){
        require(now >= _timeFrom && now < _timeUntil, _errorMessage);
        _;
    }

    constructor() public{
        spouse1 = Spouse(address(0xCA35b7d915458EF540aDe6068dFe2F44E8fa733c),"Romeo","Montague",false);
        spouse2 = Spouse(address(0x111122223333444455556666777788889999aAaa),"Juliet","Capulet",false);
        marriageStatus = "Not married yet";
        weddingTime = 1590494400; //weddingTime set to 05/26/2020 at 12:00
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
    
    function addGuest(string memory _firstName, string memory _lastName, address _address) public onlySpouse
    validTime(now, weddingTime-259200, "Cannot add guests less than 3 days before the wedding") returns (bool){
        // check the ceremony date, if after the date disallow this function
        // default _acceptance and _objection values are false
        guestList.push(Guest(_firstName, _lastName, false, false, false, _address, false));
        return true;
    }
    
    modifier onlyGuest(){
        for (k=0; k<guestList.length; k++) {
            if (guestList[k]._addressG == msg.sender)
                break;
        }
        require(msg.sender == guestList[k]._addressG, "Only for valid guests!");
        _;                    
    }
    
    function acceptInvitation() public onlyGuest 
    validTime(now, weddingTime-259200, "You cannot accept the invitation now!") returns(string memory){
        // check the ceremony date, if after the date disallow this function
        guestList[k]._acceptance = true;
        return ("See you at the wedding");
    }
    
    function attendCeremony() public onlyGuest 
    validTime(weddingTime-21600, weddingTime+7200, "Not open attending wedding") returns(string memory){ //6 hours before wedding, 2 hours after

        guestList[k]._attendance = true;
        return string("See you inside");
    }

    function toString(address x) internal pure returns (string memory) {
        bytes memory b = new bytes(20);
        for (uint i = 0; i < 20; i++)
            b[i] = byte(uint8(uint(x) / (2**(8*(19 - i)))));
        return string(b);
    }
    
    modifier onlyLoggedInGuest(){
        for (k=0; k<guestList.length; k++) {
            if (guestList[k]._addressG == msg.sender)
                break;
        }
        require(guestList[k]._acceptance && guestList[k]._attendance, "Only logged in guests can vote!");
        _;
    }
    
    // A logged_in guest can vote 15 min before the ceremony and 15 min after started
    function objectMarriage() public onlyLoggedInGuest 
        validTime(weddingTime-900,weddingTime+900, "You can start to vote 15 min before the ceremony!"){
        guestList[k]._objection = true;
        guestList[k]._vote = true;
        guestObjected = true;
        uint objectiontime = now;
        votingLimit = objectiontime + 600;
    }
    
    function agreeToObjection() public onlyLoggedInGuest{
        if (guestObjected == true){
            guestList[k]._vote = true;
        }
    }
    
    function calculateVoting() public onlyLoggedInGuest returns (string memory){
        if (now > votingLimit){
            for (uint i=0; i<guestList.length; i++)   
            {
                if (guestList[i]._vote==true){
                    count = count+1;
                }
                if (guestList[i]._attendance==true)
                validTotalCount = validTotalCount +1;
            }
            if (count> validTotalCount/2){
                marriageStatus = "Objection accepted. Marriage is terminated.";
            }
        }
        else{
            return ("The voting is not yet over/There isn't any voting proccess");
        }
    }
    
    function cancelMarriage() public onlySpouse
    validTime(now, weddingTime, "You can not cancel wedding after marriage") {
        if(msg.sender == spouse1._address) {
            spouse1._cancelWedding = true;
        }
        else {
            spouse2._cancelWedding = true;
        }
        marriageStatus = "One of the spouses cancelled the wedding. Marriage is terminated.";
        
    }
    
    function startCermony() public onlySpouse
    validTime(weddingTime, weddingTime+900, "You can't start the cermony") { //cermony can start on weddingTime and until 15 minutes after
        if (spouse1._cancelWedding == false && spouse2._cancelWedding == false && guestObjected == false) {
            marriageStatus = "Married";
        }  
    
    }
}