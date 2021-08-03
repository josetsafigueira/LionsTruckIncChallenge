public with sharing class RestConstants {
   
    private static ClientSecrets objectClientSecrets;

    public static ClientSecrets clientSecrets {
        get {
            if (objectClientSecrets == null) {
                return new ClientSecrets();
            }
            return objectClientSecrets;
        }
    }

    public class ClientSecrets {
        public String endpoint { get {return 'https://eu1.anypoint.mulesoft.com/mocking/api/v1/links/267cf127-5cc9-499d-bb5c-fe2d447aa99d/JOINTHEDIGITALHUB/{0}'; } }
        public String clientId { get { return 'b903e91e6c6542a3a4a6e800f37f95ea'; } }
        public String clientSecret { get { return '4d73e495F84E4c47B8a8E37C8F8B96b3'; } }
        public String correlationId { get { return 'a9111cc7-7a75-420b-996d-c403e449fb82'; } }
    }
}
