/**
* @File Name : ChatExtractor.cls
* @Description : Extracts sentiment rating and justification from chat sentiment analysis output
* @Author :
* @Last Modified By :
* @Last Modified On : December 30, 2024
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | December 30, 2024 |   | Initial Version - Based on TextExtractor for MessagingSession
**/

public class ChatExtractor {
    public class ExtractionResult {
        @InvocableVariable(label='Sentiment Rating' description='Extracted Chat Sentiment Rating')
        public String SentimentRating;

        @InvocableVariable(label='Sentiment Justification' description='The justification for the chat sentiment rating')
        public String SentimentJustification;
    }

    @InvocableMethod(label='Extract Chat Sentiment' description='Extracts Sentiment Rating and the remaining text as Justification from chat sentiment analysis output')
    public static List<ExtractionResult> extractSentimentAndJustification(List<String> inputs) {
        List<ExtractionResult> results = new List<ExtractionResult>();

        for (String sentimentOutput : inputs) {
            ExtractionResult result = new ExtractionResult();

            // Extract Sentiment Rating
            String sentimentRatingHeader = 'Sentiment Rating:';
            Integer startIndex = sentimentOutput.toLowerCase().indexOf(sentimentRatingHeader.toLowerCase());
            if (startIndex != -1) {
                startIndex += sentimentRatingHeader.length();
                Integer endIndex = sentimentOutput.indexOf('\n', startIndex); // Find the end of the line
                if (endIndex == -1) {
                    endIndex = sentimentOutput.length();
                }
                result.SentimentRating = sentimentOutput.substring(startIndex, endIndex).trim();

                // Extract the rest as Sentiment Justification
                Integer justificationStartIndex = sentimentOutput.toLowerCase().indexOf(sentimentRatingHeader.toLowerCase());
                if (justificationStartIndex != -1) {
                    justificationStartIndex += sentimentRatingHeader.length();
                    result.SentimentJustification = sentimentOutput.substring(justificationStartIndex).trim();
                    // Remove the Sentiment Rating line from the justification
                    Integer firstNewline = result.SentimentJustification.indexOf('\n');
                    if (firstNewline != -1) {
                        result.SentimentJustification = result.SentimentJustification.substring(firstNewline + 1).trim();
                    } else {
                        result.SentimentJustification = ''; // If no newline, the rest is empty after the rating
                    }
                } else {
                    result.SentimentJustification = sentimentOutput.trim(); // If no rating, the whole thing is justification? (Unlikely based on your example)
                }
            } else {
                result.SentimentRating = null;
                result.SentimentJustification = sentimentOutput.trim(); // If no rating header, the whole thing is justification
            }

            results.add(result);
        }
        return results;
    }
}