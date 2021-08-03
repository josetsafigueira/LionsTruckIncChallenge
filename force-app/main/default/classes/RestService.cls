public with sharing class RestService {

    public enum HttpMethod { GET, POST, PUT, PATCH }

    public static HttpResponse restCallout(HttpMethod method, Map<String, String> headers, String endpoint) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod(method.name());
        for(String headerKey : headers.keySet()) {
            req.setHeader(headerKey, headers.get(headerKey));
        }
        Http http = new Http();
        HttpResponse res = http.send(req);

        return res;
    }
}
