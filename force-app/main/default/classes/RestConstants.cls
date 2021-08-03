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
        public String endpoint { get {return 'https://XXXX/{0}'; } }
        public String clientId { get { return 'XXXX'; } }
        public String clientSecret { get { return 'XXXX'; } }
        public String correlationId { get { return 'XXXX'; } }
    }
}
