# Messaging Session Custom Fields – Manual Setup (Winter 25)

The deploy API can report "Unchanged" for these fields even when they don’t exist in the org. If the **Messaging Session Analytics** LWC shows "No such column" or "Analytics custom fields are not available", create them manually in **Winter 25** as below.

**Path:** Setup → Object Manager → **Messaging Session** → **Fields & Relationships** → **New**.

---

## 1. Agent Performance Evaluation

- **Data Type:** Long Text Area  
- **Field Label:** Agent Performance Evaluation  
- **Length:** 131,072  
- **Visible Lines:** 5  
- **Track History:** unchecked  

---

## 2. Agent Performance Rating

- **Data Type:** Number  
- **Field Label:** Agent Performance Rating  
- **Length:** 18  
- **Decimal Places:** 0  
- **Required:** unchecked  

---

## 3. Chat Sentiment

- **Data Type:** Long Text Area  
- **Field Label:** Chat Sentiment  
- **Length:** 131,072  
- **Visible Lines:** 3  
- **Track History:** unchecked  

---

## 4. Sentiment Rating

- **Data Type:** Picklist  
- **Field Label:** Sentiment Rating  
- **Required:** unchecked  
- **Values (one per line):** Positive, Neutral, Negative  
- **Restrict picklist to these values:** checked  

---

## 5. Request Historical Analysis

- **Data Type:** Checkbox  
- **Field Label:** Request Historical Analysis  
- **Default:** unchecked  

---

## After Creating the Fields

- Save each field (API names will be: `AgentPerformanceEvaluation__c`, `AgentPerformanceRating__c`, `ChatSentiment__c`, `SentimentRating__c`, `Request_Historical_Analysis__c`).
- Add them to the **Messaging Session** page layout(s) if you want them visible on the record.
- The **Messaging Session Analytics** LWC and historical flows will then work in Winter 25.
