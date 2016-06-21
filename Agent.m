classdef Agent < handle
    
   properties 
       %agent properties
       id
       location
       matrixLocation
       visX
       visY
       wealth
       
       %agent accumulated data
       network
       myIndexInNetwork
       accessCodesPaid
       bestPortfolios
       bestPortfolioValues
       knowsIncomeLocation
       incomeLayersHistory
       %incomeLayersTest
       currentPortfolio
       personalIncomeHistory
       currentSharedIn
       lastIntendedShareIn

       %agent preferences
       incomeShareFraction
       shareCostThreshold
       knowledgeShareFrac
       pInteract
       pChoose
       numBestLocation
       numBestPortfolio
       numRandomLocation
       numRandomPortfolio
       numPeriodsEvaluate
       numPeriodsMemory
       discountRate
       rValue
   end
   
   events
      %none at the moment
   end
   
   methods 
       %basic constructor
      function A = Agent(id, location, accessCodesPaid, knowsIncomeLocation, incomeLayersHistory)
         A.id = id;
         A.location = location;
         A.network = [];
         A.accessCodesPaid = accessCodesPaid;
         A.knowsIncomeLocation = knowsIncomeLocation;
         A.incomeLayersHistory = incomeLayersHistory;
         A.personalIncomeHistory = zeros(size(incomeLayersHistory,3),1);
         A.currentSharedIn = 0;
      end %  
      
      %as written presently, most agent actions are coded as model
      %subroutines with input agents, as opposed to agent member functions
      
      %since there are no child classes that inherit Agent, there isn't
      %really much of a need, and this structure makes it easier to plug
      %and play different routines
     
   end % methods
   
end % classdef