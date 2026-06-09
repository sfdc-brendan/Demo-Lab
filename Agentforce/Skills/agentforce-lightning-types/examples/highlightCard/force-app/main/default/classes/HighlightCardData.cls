@JsonAccess(serializable='always' deserializable='always')
global class HighlightCardData {

    @AuraEnabled
    global String title;

    @AuraEnabled
    global String description;

    @AuraEnabled
    global String imageUrl;

    @AuraEnabled
    global String linkUrl;

    @AuraEnabled
    global String linkLabel;

    global HighlightCardData() {}

    global HighlightCardData(
        String title,
        String description,
        String imageUrl,
        String linkUrl,
        String linkLabel
    ) {
        this.title = title;
        this.description = description;
        this.imageUrl = imageUrl;
        this.linkUrl = linkUrl;
        this.linkLabel = linkLabel;
    }
}
