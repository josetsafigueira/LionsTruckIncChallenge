public with sharing class QuoteDomain {
    
    public static void afterUpdate(List<Quote> oldQuotes, List<Quote> newQuotes) {
        Map<Id, Quote> oldQuotesMap = new Map<Id, Quote>(oldQuotes);
        Map<Id, Opportunity> relatedOpportunities = [SELECT, Id, StageName FROM Opportunity WHERE];
        List<Opportunity> opportunitiesToSync = new List<Opportunity>();

        for(Quote q : newQuotes) {
            if (String.isNotBlank(q.OpportunityId) && q.Status == 'Accepted' && oldQuotesMap.get(q.Id).Status != 'Accepted') {
                Opportunity opp = new Opportunity(Id = q.OpportunityId);
                opp.SyncedQuoteId = q.Id;
                opportunitiesToSync.add(opp);
            }
        }

        if (!opportunitiesToSync.isEmpty()) {
            update opportunitiesToSync;
        }
    }
}
