// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "./IERC20.sol";

contract Voting {

   //Events
    event ProposalCreated(address indexed _target,uint _proposalId);
    event BecomeMember(string _note);
    event VoteCast ( address indexed _voter,address indexed _target,uint _proposalId);
    event ResultAnnounced( address indexed winner, uint _prposalId);

   //Enum 
    enum VoteStates {NotCasted,Casted} 

   //If want to become member have 2 PermitToken 
    uint public  memberFee = 20;
    uint constant maxTimeLimit= 3 days;
    uint proposalId =0;
    address public chairman;
    IERC20 PermitToken;

    struct Proposal {
        address target; // election member address
        string name;
        string proposalIs;
        uint votesInFavour;
        uint votesAgainst;
        uint timeStart;
        bool Status;
    }
    
 

   //address to proposalId to Vote Status
    mapping (address => mapping(uint => VoteStates)) public  voteStates;

    //address is approved or not
    mapping(address => bool) public approvedMembers;

    //Proposal against Id
    mapping(uint => Proposal) public IdToProposal;

    //proposal Winner name
    mapping(uint => string) public  winnerName;

    //ProposalId to Status
    mapping(uint => bool) public proposalWon;

    address[] pendingMembers;

    constructor(address[] memory _approvedMembers, IERC20 _PermitToken) {
        chairman= msg.sender;
        PermitToken = IERC20(_PermitToken);
        for(uint i=0; i< _approvedMembers.length; i++) {
            approvedMembers[_approvedMembers[i]] = true;
        }
    }
    
    function newProposal(address _target, string calldata _name,string calldata _proposalIs) external {
        require(approvedMembers[msg.sender] && approvedMembers[_target] && msg.sender != chairman, "You are not member");
        proposalId++; //+1
        IdToProposal[proposalId]= Proposal(_target,_name,_proposalIs,0,0,block.timestamp, false);
        emit ProposalCreated(_target,proposalId);
    }

    function becomeVotingMember() external {
        require(!approvedMembers[msg.sender] && msg.sender != chairman,"Already Member or Chairman");
        PermitToken.transferFrom(msg.sender, address(this),20);
        pendingMembers.push(msg.sender);
        emit  BecomeMember("request for membership is submitted");
    }

    function approveAllMembers() external {
        require(msg.sender == chairman,"Only Chairman can access");
        for(uint i=0; i<pendingMembers.length;i++){
            approvedMembers[pendingMembers[i]]= true;
            delete pendingMembers[i];
        }
        
    }
    
    function castVote(uint _proposalId,bool _castVote) external {
        require(msg.sender != chairman, "Chairman cant cast");
        require(approvedMembers[msg.sender], "You are not member");
        require(msg.sender != IdToProposal[_proposalId].target, "Proposal Owner can't cast vote");
        require(voteStates[msg.sender][_proposalId] == VoteStates.NotCasted, "Vote Casted");
        require(block.timestamp <= block.timestamp + maxTimeLimit,"No time to Vote Go to proposalResult");
        voteStates[msg.sender][_proposalId] = VoteStates.Casted;
        emit VoteCast(msg.sender,IdToProposal[_proposalId].target,_proposalId);
        if(_castVote){ //true
            IdToProposal[_proposalId].votesInFavour +=1;
        }
        else{
            IdToProposal[_proposalId].votesAgainst +=1;
        } 
    }

    function proposalResult(uint _proposalId) external returns(Proposal memory) {
        require(block.timestamp >= maxTimeLimit + IdToProposal[_proposalId].timeStart);
        if(IdToProposal[_proposalId].votesInFavour > IdToProposal[_proposalId].votesAgainst){
            winnerName[_proposalId] = IdToProposal[_proposalId].name;
            proposalWon[_proposalId] = true;
            IdToProposal[_proposalId].Status =true;
        }
        else{
            proposalWon[_proposalId] = false;
            IdToProposal[_proposalId].Status =false;
        }
        emit ResultAnnounced(IdToProposal[_proposalId].target,_proposalId);
        return IdToProposal[_proposalId];
        
    }
}