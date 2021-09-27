public class GoogleAuthService {
    //API Secret Key
    private static string key = '316443490222-em25ldmu0bgpv2eauhc8iu6dngamvr1q.apps.googleusercontent.com';
    //API Secret
    private Static string secert = 'YuEq2YTC_oIJFMNftt8A37Fi';
    //API Redirect. Use your Lightning Tab or Lightning community URL
    private Static string redirect_uri = 'https://takeaway-dev-ed--c.visualforce.com/apex/GoogleCalenderoAuth';
    private static string authUrl='https://accounts.google.com/o/oauth2/v2/auth';
    private static string scope='https://www.googleapis.com/auth/calendar';
    private static string tokenUrl='https://accounts.google.com/o/oauth2/token';
    
    @AuraEnabled
    public static String createAuthURL() {
        String key = EncodingUtil.urlEncode(key,'UTF-8');
        String uri = EncodingUtil.urlEncode(redirect_uri,'UTF-8');
        String authuri = '';
        authuri = authUrl+'?'+
            'client_id='+key+
            '&response_type=code'+
            '&scope='+scope+
            '&redirect_uri='+uri+
            '&access_type=offline'+
            '&prompt=consent';
        return authuri;
    }
    
    
    public static PageReference getAccessToken()
    {
        String code = System.currentPageReference().getParameters().get('code');
        system.debug('code:'+ code);
        //Getting access token from google
        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        req.setEndpoint(tokenUrl);
        req.setHeader('content-type', 'application/x-www-form-urlencoded');
        
        String messageBody ='code='+code+'&client_id='+key+
            '&client_secret='+secert+
            '&redirect_uri='+redirect_uri+
            '&grant_type=authorization_code';
        req.setHeader('Content-length', String.valueOf(messageBody.length()));
        req.setBody(messageBody);
        req.setTimeout(60*1000);
        system.debug('messageBody:'+messageBody);
        
        Http callout = new Http();
        String responseText;
        HttpResponse response = callout.send(req);
        responseText = response.getBody();
        system.debug('responseText:'+responseText);
        Map<String,object> responseMap =(Map<String,object>)JSON.deserializeUntyped(responseText) ;  
        String token =  String.valueOf(responseMap.get('access_token'));
        String refreshToken =  String.valueOf(responseMap.get('refresh_token'));
        String expireIn =  String.valueOf(responseMap.get('expires_in'));
        datetime dt =  datetime.now();
        integer numberOfSeconds =  integer.valueOf(expireIn) ;
        
        dt = dt.addSeconds(numberOfSeconds - 200);
        
        system.debug('token:'+token);
        
        Google_Access_Information__c obj = new Google_Access_Information__c(
            Access_Token__c = token,
            RefreshToken__c = refreshToken,
            User__c = userinfo.getUserId(),
            email__c = userinfo.getUserEmail(),
            Expires_In__c  = numberOfSeconds,
            Next_Expiry_DateTime__c = dt
        );
        
        
        database.upsert(obj, Google_Access_Information__c.email__c);
        
        PageReference retURL = new PageReference('https://takeaway-dev-ed.lightning.force.com/lightning/n/Authorize_Calendar');
        retURL.setRedirect(true);
        return retURL;
        
    }
}