global class Concur extends Auth.AuthProviderPluginClass {
               
    public String redirectUrl = Label.Portal_PingOne; // use this URL for the endpoint that the authentication provider calls back to for configuration
    private String key;
    private String secret;
    private String authUrl;    // application redirection to the Concur website for authentication and authorization
    private String accessTokenUrl; // uri to get the new access token from concur  using the GET verb
    private String customMetadataTypeApiName = 'Ping_One_OIDC__mdt'; // api name for the custom metadata type created for this auth provider
    private String userAPIUrl; // api url to access the user in concur
    private String userAPIVersionUrl; // version of the user api url to access data from concur
    private static String userEmail;
    private static String id_Token;
    private static String access_Token;

    global String getCustomMetadataType() {
        return customMetadataTypeApiName;
    }

    global PageReference initiate(Map<string,string> authProviderConfiguration, String stateToPropagate) {
        authUrl = authProviderConfiguration.get('Auth_Url__c');
        key = authProviderConfiguration.get('Key__c');
        String url = authUrl + '?response_type=code&client_id='+ key +'&scope=openid+role+email+profile+phone&redirect_uri='+ redirectUrl + '&state=' + stateToPropagate;
        return new PageReference(url); 
    }

    global Auth.AuthProviderTokenResponse handleCallback(Map<string,string> authProviderConfiguration, Auth.AuthProviderCallbackState state ) {
        //Here, the developer will get the callback with actual protocol.  
        //Their responsibility is to return a new object called AuthProviderToken
        //This will contain an optional accessToken and refreshToken
        key = authProviderConfiguration.get('Key__c');
        secret = authProviderConfiguration.get('Secret__c');
        accessTokenUrl = authProviderConfiguration.get('Access_Token_Url__c');
        
        Map<String,String> queryParams = state.queryParameters;
        system.debug('queryParams '+queryParams);
        system.debug('error_description'+queryParams.get('error_description'));
        if(queryParams.get('error') != null){
            throw new Auth.AuthProviderPluginException(queryParams.get('error_description'));
        }
        String code = queryParams.get('code');
        String sfdcState = queryParams.get('state');
        // Set up the request
        HttpRequest req = new HttpRequest();
        req.setEndpoint(accessTokenUrl);
        req.setMethod('POST');
        
        // Set up the request body
        String requestBody = 'grant_type=' + EncodingUtil.urlEncode('authorization_code', 'UTF-8') +
                             '&code=' + EncodingUtil.urlEncode(code, 'UTF-8')+
                             '&redirect_uri=' + EncodingUtil.urlEncode(redirectUrl, 'UTF-8');
        req.setBody(requestBody);
        // Set Basic Authentication Header
        String authHeader = 'Basic ' + EncodingUtil.base64Encode(Blob.valueOf(key + ':' + secret));
        req.setHeader('Authorization', authHeader);
        //req.setHeader('Scope', 'openid%20role%20profile%20email');
        // Set content type
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');

        Http http = new Http();
        HTTPResponse res = http.send(req);
        String responseBody = res.getBody();
        system.debug('responseBody :1!321Q: '+responseBody);
        Map<String, Object> resMap = (Map<String, Object>)JSON.deserializeUntyped(responseBody);
        String accessToken = (String)resMap.get('access_token');
        String refreshToken = (String)resMap.get('refresh_token');
        String idToken = (String)resMap.get('id_token');
        access_Token = accessToken;
        id_Token = idToken;
        return new Auth.AuthProviderTokenResponse('Concur', accessToken, refreshToken, sfdcState);
        
    }


    global Auth.UserData  getUserInfo(Map<string,string> authProviderConfiguration, Auth.AuthProviderTokenResponse response) { 
        //Here the developer is responsible for constructing an Auth.UserData object
        String token = response.oauthToken;
        HttpRequest req = new HttpRequest();
        userAPIUrl = authProviderConfiguration.get('API_User_Url__c');
        req.setHeader('Authorization', 'Bearer ' + token);
        req.setEndpoint(userAPIUrl);
        req.setHeader('x-seg-clientid','Web');
        req.setHeader('x-id-token',id_Token);
        req.setMethod('GET');
        
        
        Http http = new Http();
        HTTPResponse res = http.send(req);
        String responseBody = res.getBody();
        system.debug(':getUserInfo: user info response body:: '+responseBody);
        Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(responseBody);
        
        List<Object> roles = (List<Object>)responseMap.get('roles');
        String isExcluded = (String)responseMap.get('isExcluded');
        
        Boolean email_verified = false; // Default to false
        Boolean phone_number_verified = false; // Default to false
        
        if (responseMap.containsKey('email_verified') && responseMap.get('email_verified') != null) {
            email_verified = (Boolean)responseMap.get('email_verified');
        }
        
        if (responseMap.containsKey('phone_number_verified') && responseMap.get('phone_number_verified') != null) {
            phone_number_verified = (Boolean)responseMap.get('phone_number_verified');
        }

        if (Test.isRunningTest()) {
            roles = new List<Object>();
            roles.add('Social Members');
            roles.add('Active Star Members');
        }
        for(Object role : roles){
            String roleJSON = JSON.serialize(role);
            if(roleJSON.contains('Loyalty Members')){
                throw new Auth.AuthProviderPluginException('LM');
            }
        }

        // Read amr values for login method and apply null check
        List<Object> amrList = (List<Object>) responseMap.get('amr');
        String loginMethod = '';
        
        if (amrList != null && amrList.contains('pin')) {
            loginMethod = 'pin';
        } else{
            loginMethod = 'pwd';
        }
        
        if (isExcluded == 'TRUE') {
            throw new Auth.AuthProviderPluginException('Excl');
        }
        
        if(isExcluded == 'TRUE'){
            throw new Auth.AuthProviderPluginException('Excl');
        }
        
        String id = (String)responseMap.get('customerNumber');
        String fname = (String)responseMap.get('given_name');
        String lname = (String)responseMap.get('family_name');
        String flname = fname + ' ' + lname;
        String email = (String)responseMap.get('email');
        Map<String,String> provMap = new Map<String,String>();
        provMap.put('id_Token', id_Token);
        provMap.put('access_Token', access_Token);
        provMap.put('what1', 'noidea1');
        provMap.put('email_verified', String.valueOf(email_verified));
        provMap.put('phone_number_verified', String.valueOf(phone_number_verified));
        List<User> uList = [SELECT Id, token__c, token_a__c, Portal_EmailVerified__c, Portal_PhoneNumberVerified__c, Portal_LoginMethod__c FROM User where (Patron_ID__c =: id OR email =: email)AND Profile.Name = 'Carded Guest'];
        if(uList.size() > 0){
            User u = uList[0];
            u.token__c = id_Token;
            u.token_a__c = access_Token;
            u.Portal_EmailVerified__c = email_verified;
            u.Portal_PhoneNumberVerified__c = phone_number_verified;
            u.Portal_LoginMethod__c = loginMethod;
            update u;
        }
        
        return new Auth.UserData(id, fname, lname, flname, email,
            'what', null, null, 'Concur', null, provMap);
 
    }
    
    
}