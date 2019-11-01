pragma solidity >0.5.10;


contract SmartWedding{
    
    struct Spouse{
        address _address;
        string _firstName;
        string _lastName;
        bool _cancelWedding; //In case one of the spouses changes his/her mind before the wedding
    }
    
    Spouse private spouse1; //later we give them values, private for security reasons
    Spouse private spouse2;
    bool guestObjected = false; 
    bool objectingMajority = false; 
    string public marriageStatus;//In this string we register the state of the wedding after this, e.g. married, cancelled...
    uint public weddingTime;//Time the ceremony starts
    
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
        bool _vote;//In case of objection the guests have to vote if they agree to it or not
    }
    
    Guest[] public guestList;
    uint k;
    uint h = 0 ;
    uint public count = 0; //this variable and the next are used to count the votes in case of objection
    uint validTotalCount = 0;
    uint votingLimit; //time limit to vote
    
    //The following modifier is to set time windows for each function more easily
    modifier validTime(uint _timeFrom, uint _timeUntil, string memory _errorMessage){
            require(now >= _timeFrom && now < _timeUntil, _errorMessage);
            _;
    }

    //Here we define our spouses
    constructor() public{
        spouse1 = Spouse(address(0xCA35b7d915458EF540aDe6068dFe2F44E8fa733c),"Romeo","Montague",false);
        spouse2 = Spouse(address(0x111122223333444455556666777788889999aAaa),"Juliet","Capulet",false);
        marriageStatus = "Not married yet";
        weddingTime = 1572631200; //weddingTime set to 05/26/2020 at 12:00
    }   
    
    
    modifier onlySpouse(){
        require(msg.sender == spouse1._address || msg.sender == spouse2._address, "Only spouses can do this action!");
        _;
    }
    
    modifier onlyGuest(){
        for (k=0; k<guestList.length; k++) {
            if (guestList[k]._addressG == msg.sender)
                break;
        }
        require(msg.sender == guestList[k]._addressG, "Only for valid guests!");
        _;                    
    }
    
    modifier onlyGuestAccepted(){
        for (k=0; k<guestList.length; k++) {
            if (guestList[k]._addressG == msg.sender)
                break;
        }
        require(guestList[k]._acceptance, "Only for guests that have accepted the invitation!");
        _;
    }
    
    
    modifier onlyLoggedInGuest(){
        for (k=0; k<guestList.length; k++) {
            if (guestList[k]._addressG == msg.sender)
                break;
        }
        require(guestList[k]._attendance, "Only logged in guests can vote!");
        _;
    }
    
    //Function to invite guests to the wedding. Values of vote, acceptance, objection and attendance are initially 
    //set to false as they are the ones who decide to object, wheter or not to assist, etc 
    function addGuest(string memory _firstName, string memory _lastName, address _address) public onlySpouse
    validTime(now, weddingTime, "Cannot add guests less than 3 days before the wedding") returns (bool){
        guestList.push(Guest(_firstName, _lastName, false, false, false, _address, false));
        return true;
    }
    
    //Function to accept the wedding invitation
    function acceptInvitation() public onlyGuest 
    validTime(now, weddingTime, "You cannot accept the invitation now!") returns(string memory){
        guestList[k]._acceptance = true;
        return ("See you at the wedding");
    }
    
    //Function to attend the wedding. The invitation has to be previously accepted
    function attendCeremony() public onlyGuestAccepted 
    validTime(now, weddingTime, "Not open attending wedding") returns(string memory){
        guestList[k]._attendance = true;
        return ("See you inside");
    }
    
    //Function to object to the marriage, this will initiate a voting process. Guests need to attend the wedding to object
    function objectMarriage() public onlyLoggedInGuest 
        validTime(now,weddingTime, "You can start to vote 15 min before the ceremony!"){
        guestList[k]._objection = true;
        guestList[k]._vote = true;
        guestObjected = true;
        uint objectiontime = now;
        votingLimit = objectiontime + 60;
    }
    
    //In case of objection the other guests can agree with it through this function
    function agreeToObjection() public onlyLoggedInGuest returns (string memory){
        if (guestObjected == true){
            guestList[k]._vote = true;
        }
        else{
           return ("You cannot agree to an objection that does not exist.");    
        }
    }
    
    //After the time for voting we can count the votes with this function. If majority agrees with the objection the wedding will be cancelled
    function calculateVoting() public onlyLoggedInGuest returns (string memory){
        if (now < votingLimit){
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
                objectingMajority = true; 
            }
            return ("Voting process finished");
        }
        else{
            return ("The voting is not yet over/There isn't any voting proccess");
        }
    }
    
    //In case any of the spouses change his/her mind, he/she can cancel the wedding with this function before it happens
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
    
    //after the wedding and if no objection accepted the spuses can change their status to happily married
    function formalizeWedding() public onlySpouse
    validTime(now, weddingTime+900, "You can't start the cermony") { //cermony can start on weddingTime and until 15 minutes after
        if (spouse1._cancelWedding == false && spouse2._cancelWedding == false && objectingMajority == false) {
            marriageStatus = "Married";
        }  
    }
}