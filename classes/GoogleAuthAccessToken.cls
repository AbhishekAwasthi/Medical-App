public class GoogleAuthAccessToken {
    
        //API Secret Key
    private static string key = System.Label.Google_Key; // '316443490222-em25ldmu0bgpv2eauhc8iu6dngamvr1q.apps.googleusercontent.com';
    //API Secret
    private Static string secert =  System.Label.Google_Secret; // 'YuEq2YTC_oIJFMNftt8A37Fi';
    
    
    
 public static Google_Access_Information__c getNewAccessToken(string userId){
        
        list<Google_Access_Information__c> Info = [select id,RefreshToken__c,Access_Token__c,Next_Expiry_DateTime__c,Expires_In__c,email__c from Google_Access_Information__c where User__c =: userinfo.getUserId() limit 1];
        
        String errorMessage ='';
        Http http = new Http();
        HttpRequest httpReq = new HttpRequest();
        HttpResponse httpRes = new HttpResponse();
        httpReq.setEndpoint('https://www.googleapis.com/oauth2/v4/token');
        httpReq.setMethod('POST');
        httpReq.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        
        
        String refreshToken;
        if(Info.size() > 0 )
            refreshToken = Info[0].RefreshToken__c;
        
        System.debug('#### refreshToken '+refreshToken);
        String refreshTokenBody = 'client_id='+key+'&client_secret='+secert+'&refresh_token='+refreshToken
            +'&grant_type=refresh_token';
        System.debug('#### refreshTokenBody '+refreshTokenBody);
        String responseText;
        httpReq.setBody(refreshTokenBody);
        httpRes = http.send(httpReq);
        responseText = httpRes.getBody();
        system.debug('responseText:'+responseText);
        Map<String,object> responseMap =(Map<String,object>)JSON.deserializeUntyped(responseText) ;  
        String token =  String.valueOf(responseMap.get('access_token'));
        String expireIn =  String.valueOf(responseMap.get('expires_in'));
        datetime dt =  datetime.now();
        integer numberOfSeconds =  integer.valueOf(expireIn) ;
        
        dt = dt.addSeconds(numberOfSeconds - 200);
        system.debug('token:'+token);
        
        
        if(token.length()>0){
            info[0].Access_Token__c = token;
            info[0].Expires_In__c  = numberOfSeconds;
            info[0].Next_Expiry_DateTime__c = dt;
            // info[0].RefreshToken__c = refreshToken;
            
           // update info; 
            
        }
        
        return Info[0];
        
        
    }
    
}