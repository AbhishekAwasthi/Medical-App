public class GoogleCalendarActionsController {
    
    
        //API Secret Key
    private static string key = System.Label.Google_Key; // '316443490222-em25ldmu0bgpv2eauhc8iu6dngamvr1q.apps.googleusercontent.com';
    //API Secret
    private Static string secert =  System.Label.Google_Secret; // 'YuEq2YTC_oIJFMNftt8A37Fi';
    
    
    
    public static string getAllEventsForUser(string UserId){
        
        Datetime now = datetime.now();
        String myDtString = now.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
        
        list<Google_Access_Information__c> Info = [select id,Access_Token__c,Next_Expiry_DateTime__c,email__c from Google_Access_Information__c where User__c =: UserId limit 1];
        
        if(Info.size()>0){
            String accessToken = Info[0].Access_Token__c;
            datetime dt = Info[0].Next_Expiry_DateTime__c; 
            if(dt< datetime.now()){
                Info[0] =  GoogleAuthAccessToken.getNewAccessToken(UserId);
                accessToken = Info[0].Access_Token__c;
                
            }
            String endPoint = 'https://www.googleapis.com/calendar/v3/calendars/'+Info[0].email__c+'/events?timeZone=GMT&timeMin='+myDtString;
            
            
            
            Http http = new Http();
            HttpRequest httpReq = new HttpRequest();
            HttpResponse HttpRes = new HttpResponse();
            
            httpReq.setEndpoint(endpoint);
            httpReq.setMethod('GET');
            httpReq.setHeader('Content-Type', 'application/json');
            httpReq.setHeader('Authorization','Bearer '+accessToken);
            HttpRes = http.send(httpReq);
            if(HttpRes.getStatusCode() == 200) {
                System.debug('#### HtteRes '+HttpRes.getBody());
                string resp = HttpRes.getBody();
                resp = resp.replace('date', 'date_Z');
                resp = resp.replace('end', 'end_Z');
                resp = resp.replace('date_ZTime', 'dateTime_Z');
                
                googleEvent respObj =(googleEvent)JSON.deserialize(resp,googleEvent.class) ;
                
                database.upsert(Info[0], Google_Access_Information__c.email__c);
                updateEventsInSalesforce(respObj,UserId);
                 return 'success';
            }
            else if(HttpRes.getStatusCode() == 401){ 
                return 'User not authorized Please ask user to authorize his calender via authorization screen';
            }
            else{
                return 'Something Went Wrong Please reach out to your administrator';
            }
           
        }
        else{
            return 'User not authorized Please ask user to authorize his calender via authorization screen';
        }
        
        
        
        
        
    }
    
    public static list<Event> updateEventsInSalesforce(googleEvent respObj,Id userId){
        
        list<event> currenteventIds = [select id,GoogleEventId__c from event where OwnerId =: userId and GoogleEventId__c!= null]; 
        set<string> alleventIds = new set<string>();
        list<Event> eventList = new list<Event>();
        list<Event> DeleteEventList = new list<Event>();
        list<googleEvent.Items> events = new list<googleEvent.Items>();
        
        if(respObj.items != null){
            events= respObj.items; 
        }
        
        system.debug('item'+respObj.items);
        
        Event e;
        for(googleEvent.Items item : events){
            e = new Event();
            e.OwnerId = userId;
            e.Subject = item.summary;
            if(item.start.dateTime_Z != null){
                string str = item.start.dateTime_Z;
                str = str.replace('T',' ');
                str  = str.replace('Z','');
                e.StartDateTime = Datetime.valueOf(str);
            }
            if(item.end_Z.dateTime_Z != null){
                string str = item.end_Z.dateTime_Z;
                str = str.replace('T',' ');
                str  = str.replace('Z','');
                e.EndDateTime = Datetime.valueOf(str);
            }
            if(item.start.date_Z != null){
                date dt = date.valueOf(item.start.date_Z);
                Integer d = dt.day();
                Integer mo = dt.month();
                Integer yr = dt.year();
                
                DateTime startdate = DateTime.newInstanceGMT(yr, mo, d,1,1,1);
                e.StartDateTime = startdate;
            }
            if(item.end_Z.date_Z != null){
                date dt = date.valueOf(item.end_Z.date_Z);
                Integer d = dt.day();
                Integer mo = dt.month();
                Integer yr = dt.year();
                
                DateTime enddate = DateTime.newInstanceGMT(yr, mo, d,23, 00, 00);
                e.EndDateTime = enddate;
            }
            
            e.GoogleEventId__c = item.id;
            eventList.add(e);
            alleventIds.add(item.id);
        }
        
        for(event item : currenteventIds){
            if(!alleventIds.contains(item.GoogleEventId__c)){
                DeleteEventList.add(item);
            }
        }
        delete DeleteEventList;
        
        database.upsert(eventList, Event.GoogleEventId__c, false) ;
        system.debug('eventList'+eventList);
        return eventList;
        
    }
    
    
    
    public static string createEventInGoogle(event eventObj,string OwnerGmailAddress){
        
        list<Google_Access_Information__c> Info = [select id,Access_Token__c,Next_Expiry_DateTime__c,email__c from Google_Access_Information__c where User__c =: eventObj.OwnerId limit 1];
        
        String startdate = eventObj.StartDateTime.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
        String endDate = eventObj.EndDateTime.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
        
        if(Info.size()>0){
            String accessToken = Info[0].Access_Token__c;
            datetime dt = Info[0].Next_Expiry_DateTime__c; 
            if(dt< datetime.now()){
                Info[0] =  GoogleAuthAccessToken.getNewAccessToken(eventObj.OwnerId);
                accessToken = Info[0].Access_Token__c;
                
            }
            
            String requestBody = '{"description": "",   "start": {     "dateTime": '+'"'+ startdate+'"'+',     "timeZone": "GMT"   },   "end": {     "dateTime": '+'"'+ endDate+'"'+',     "timeZone": "GMT"   },  "summary": '+'"'+ eventObj.Subject+'"'+' }';
            
            System.debug('#### requestBody '+requestBody);
            Http http = new Http();
            HttpRequest httpReq = new HttpRequest();
            HttpResponse HttpRes = new HttpResponse();
            datetime reqstartTime = datetime.now();
            //httpReq.setEndpoint('https://www.googleapis.com/calendar/v3/calendars/'+eventObj.Owner.Email+'/events');
            httpReq.setEndpoint('https://www.googleapis.com/calendar/v3/calendars/'+OwnerGmailAddress+'/events');
            httpReq.setMethod('POST');
            httpReq.setBody(requestBody);
            httpReq.setHeader('Content-Type', 'application/json');
            httpReq.setHeader('Authorization','Bearer '+accessToken);
            HttpRes = http.send(httpReq);
            datetime  requestEndTime = datetime.now();
            
            System.debug('#### HtteRes '+HttpRes.getBody());
            /*Integration_Information__c obj = logInfo(requestBody,HttpRes.getBody(),reqstartTime,requestEndTime,eventObj.id,eventObj.OwnerId);
            insert obj; */
             if(HttpRes.getStatusCode() == 200) {
                 Map<String,object> IdInfo = (Map<String,object>)JSON.deserializeUntyped(HttpRes.getBody());
            
                if(IdInfo != null){
                    eventObj.GoogleEventId__c=  String.valueOf(IdInfo.get('id')); 
                    insert eventObj;
                }
                database.upsert(Info[0], Google_Access_Information__c.email__c);
                return 'Success';
             }
            else if(HttpRes.getStatusCode() == 401){ 
                return 'User not authorized Please ask user to authorize his calender via authorization screen';
            }
            else{
                return 'Something Went Wrong Please reach out to your administrator';
            }
            
        }
        else{
            return 'User not authorized Please ask user to authorize his calender via authorization screen';
        }
        
        
        
    }
    
    public static Integration_Information__c logInfo(string Request , string resposne , datetime startTime ,datetime EndTime,string objectId, string userId){
        
        Integration_Information__c infoobj = new Integration_Information__c(
            Request__c = Request,
            Resposne__c = resposne,
            StartTime__c = startTime,
            End_Time__c    = EndTime,
            EventId__c =    objectId,
            User__c =     userId
            
        );
        
        return infoobj;
        
    }
    
}