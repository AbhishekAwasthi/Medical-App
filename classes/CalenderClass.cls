public class CalenderClass {
    @AuraEnabled
    public static list<Event> getAllEvents(string userId){

        
       string result =  GoogleCalendarActionsController.getAllEventsForUser(userId);
        
        if(result=='success'){
            list<Event> eventlist =[Select id, EndDateTime,StartDateTime,Subject,Sync_Status__c from Event where ownerid=:userId] ;
             return eventlist;
        }
        else
        {
            throw new AuraHandledException(result);
        }
       
    }
    
     @AuraEnabled
    public static list<Event> CreateEvents(string ownerid,string specialization ,string subject,string patientName,string patientEmail,datetime  startDate,datetime endDate ){

        event eventObject = new event();
        eventObject.OwnerId = ownerid;
        eventObject.Specialization__c = specialization;
        eventObject.Subject = subject;
        eventObject.Patient_Full_Name__c = patientName;
        eventObject.Patient_Email__c = patientEmail;
        eventObject.StartDateTime = startDate;
        eventObject.EndDateTime = endDate;
        
        user objUser = [select id, Gmail__c from user where id =: ownerid limit 1];
        if(string.isBlank(objUser.Gmail__c)){
            throw new AuraHandledException('Gmail Id is not updated on user record');
          
        }

        
        string result =  GoogleCalendarActionsController.createEventInGoogle(eventObject,objUser.Gmail__c);
        
        if(result=='success'){
            list<Event> eventlist =[Select id, EndDateTime,StartDateTime,Subject,Sync_Status__c from Event where ownerid=:ownerid] ;
             return eventlist;
        }
        else
        {
            throw new AuraHandledException(result);
        }
       
    }
    
     @AuraEnabled
    public static list<Specialization__c> getAllSpecialization(){
        list<Specialization__c> spectlist =[Select id, Name, Appointment_Price__c  from Specialization__c] ;
        return spectlist;
    }
    
     @AuraEnabled
    public static list<user> getUserBySpecialization(string specialization){
        list<user> userlist =[Select id, Name  from user where Specialization__c =: specialization] ;
        return userlist;
    }
    
    @AuraEnabled
    public static void updateEvent(string eventid,string eventdate){
        system.debug(eventid);
        system.debug(eventdate);
        string eventdatelist = eventdate.replace('T',' ');
        
        system.debug(eventdatelist);
        Event e= new event(id = eventid);
        e.StartDateTime = DateTime.valueof(eventdatelist);
        update e;
        
    }
    

}