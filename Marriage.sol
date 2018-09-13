pragma solidity ^0.4.24;

contract Marriage  {
    
    uint RegID;
    bytes32 marid;
    
    enum Status {
        Married,
        Single,Divorced
    }
    enum Type {
        Bride,
        Groom,
        Lawyer
    }
    
    struct Data {
        
        uint Id;
        string name;
        bool registered;
        Status status;
        Type types;
    }
    
//-----------------------------------------------Mappings---------------------------------------------------    
    
    mapping (address => Data) public data;     
    mapping (address => address) public femaleXmale;
    mapping (address => address) public maleXfemae;
    mapping (bytes32 => address ) marriageidXlawyer;


//-----------------------------------------------Events---------------------------------------------------    


    event marriage( bytes32 indexed mid,
                address indexed mpartner1,
                address indexed mpartner2,
                address  mlawyer
                );    
    
    event Divorce(  bytes32 indexed did,
                address indexed dpartner1,
                address indexed dpartner2,
                address dlawyer
                );    
                
    event Register( uint RegID,
                address user,
                string name,
                string types
                );    
                

//-----------------------------------------------Modifiers---------------------------------------------------    


    modifier NotRegistered() {
    require(!data[msg.sender].registered,"Already registered");
    _;
    }
    
    modifier Allregistered(address _groom,address _bride,address _lawyer) {
    require(data[_groom].registered && data[_bride].registered && data[_lawyer].registered,"User is Not Registered");
    require(msg.sender == _groom || msg.sender == _bride,"Only bride or groom can call");
    _;
    }
    
    modifier BothSingle(address _groom,address _bride) {
    require( (data[_groom].status == Status.Single || data[_groom].status == Status.Divorced )  &&  
             (data[_bride].status == Status.Single || data[_bride].status == Status.Divorced),"Already Married");
    _;
    }
    
    modifier BothMarried(address _groom,address _bride) {
    require(data[_groom].status == Status.Married && data[_bride].status == Status.Married,"Both are Not Married");
    _;
    }

//-----------------------------------------------Methods---------------------------------------------------    

    // to avoid any accidental ether Transfer
    function() external {  }                


    // Each Entity needs to Register First
   function register(string _name,string _type) 
   public
   NotRegistered
   returns (bool) {
       bytes32 _Type = keccak256(abi.encodePacked(_type));
       bytes32 bride =  keccak256(abi.encodePacked("Bride"));
       bytes32 groom =  keccak256(abi.encodePacked("Groom"));
       bytes32 lawyer = keccak256(abi.encodePacked("Lawyer"));
       require(_Type == bride || _Type == groom || _Type == lawyer,"Enter Groom,Bride or Lawyer ");
       
       Type t;
       
       if (_Type == bride){
            t = Type.Bride;
       }
       else if(_Type == groom){
           t = Type.Groom;
       }
       else{
           t = Type.Lawyer;
       }
       
       data[msg.sender] = Data(RegID,_name,true,Status.Single,t);
       emit Register(RegID,msg.sender,_name,_type);
       RegID++;
       return true;
   }
   
   //Only Registered users can call function to marry(male and female can marry and marriage fees is 2 ETH 
   function marry(address _groom,address _bride,address _lawyer)
   public
   Allregistered(_groom,_bride ,_lawyer)
   BothSingle(_groom,_bride)
   payable
   returns(bytes32) {
       
       require(msg.value == 2 ether,"Invalid amount of ether");
       require(data[_groom].types == Type.Groom && data[_bride].types == Type.Bride,"male and female only");
       require(data[_lawyer].types == Type.Lawyer);
       marid = keccak256(abi.encodePacked(_groom,_bride));
       marriageidXlawyer[marid] = _lawyer;
       data[_groom].status = Status.Married;
       data[_bride].status = Status.Married;
       femaleXmale[_bride] = _groom;
       maleXfemae[_groom] = _bride;
       emit marriage(marid,_groom,_bride,_lawyer);
       require(_lawyer.send(2 ether));
       return marid;
   }
   
   
   function divorce(bytes32 _marid,address _groom,address _bride,address _lawyer)
   public
   Allregistered(_groom,_bride ,_lawyer)
   BothMarried(_groom,_bride)
   payable
   returns(bool) {
       
       require(msg.value == 4 ether,"Invalid amount of ether");
       require(marriageidXlawyer[_marid] != _lawyer,"Marriage Lawyer cannot involve in Divorce");
       require(_marid == keccak256(abi.encodePacked(_groom,_bride)),"Both are not Married to each other");
       data[_groom].status = Status.Divorced;
       data[_bride].status = Status.Divorced;
       delete femaleXmale[_bride];
       delete maleXfemae[_groom];
       emit Divorce(_marid,_groom,_bride,_lawyer);
       require(_lawyer.send(4 ether));
       return true;
   }
   
    function getBal() view public returns (uint){
    return address(this).balance;
    }
    
    //users can get details by calling this function without any gas
    function getDetails() view public returns (uint Id,string name,bool registered,string RelationshipStatus,string Category){
        string memory _t;
        string memory s;
        
        if(data[msg.sender].status == Status.Married){
            s = "Married";
        }
        else if(data[msg.sender].status == Status.Divorced) {
            s = "Divorced";    
        }
        else s = "Single";
            
        if(data[msg.sender].types == Type.Groom){
            _t = "Groom";
        }
        else if(data[msg.sender].types == Type.Bride){
            _t = "Bride";
        }
        else _t = "Lawyer";
        
    return (data[msg.sender].Id,data[msg.sender].name,data[msg.sender].registered,s,_t);
    }
}
