public with sharing class SchemaWorkShopAsset {
    
    public String vin;
    public String vehicleNum;
    public String vehicleRegNum;
    public String regNumCountryKey;
    public String oemVin;
    public String manufacturer;
    public String prodCode;
    public String modelRange;
    public String vehicleType;
    public String typeVariant;
    public String deliveryExWorkDate;
    public String firstRegDate;
    public String wheelBase;
    public String overhang;
    public String suspension;
    public String truckAxle;
    public String customerRegDate;
    public String customerNo;
    public String customerName;
    public Measurement measuringPoint;
    public VehicleInfoTextData vehicleTextData;

    public class Measurement {
        public String measPoint;
        public String counterReading;
        public String mpUnit;
    }

    public class VehicleInfoTextData {
        public VehicleInformationText informationText;
        public List<VehicleNoteText> noteText;
    }

    public class VehicleInformationText {
        public String textLine;
    }

    public class VehicleNoteText {
        public String tagColumn;
        public String textLine;
    }

    public static SchemaWorkShopAsset parseResult (String json) {
        return (SchemaWorkShopAsset) System.JSON.deserialize(json, SchemaWorkShopAsset.class);
    }
}
