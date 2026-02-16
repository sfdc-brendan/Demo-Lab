/**
 * @description Controller for the Modern Account Card LWC
 *              Fetches aggregated metrics from related records (Quotes, Assets, Orders, Invoices)
 *              for Revenue Cloud demos
 * @author Cursor Agent
 * @date 2026
 */
public with sharing class ModernAccountCardController {
    
    /**
     * @description Wrapper class for account metrics
     */
    public class AccountMetrics {
        @AuraEnabled public Integer quoteCount { get; set; }
        @AuraEnabled public Decimal quoteTotalPrice { get; set; }
        @AuraEnabled public Integer activeAssetCount { get; set; }
        @AuraEnabled public Decimal orderTotalAmount { get; set; }
        @AuraEnabled public Decimal invoiceTotalAmount { get; set; }
        
        public AccountMetrics() {
            this.quoteCount = 0;
            this.quoteTotalPrice = 0;
            this.activeAssetCount = 0;
            this.orderTotalAmount = 0;
            this.invoiceTotalAmount = 0;
        }
    }
    
    /**
     * @description Fetches all metrics for an account in a single call
     * @param accountId The Account record Id
     * @return AccountMetrics wrapper with all aggregated values
     */
    @AuraEnabled(cacheable=true)
    public static AccountMetrics getAccountMetrics(Id accountId) {
        AccountMetrics metrics = new AccountMetrics();
        
        if (accountId == null) {
            return metrics;
        }
        
        // Quote metrics
        try {
            AggregateResult[] quoteResults = [
                SELECT COUNT(Id) cnt, SUM(TotalPrice) total
                FROM Quote
                WHERE AccountId = :accountId
                WITH SECURITY_ENFORCED
            ];
            if (!quoteResults.isEmpty()) {
                metrics.quoteCount = (Integer) quoteResults[0].get('cnt');
                Decimal total = (Decimal) quoteResults[0].get('total');
                metrics.quoteTotalPrice = total != null ? total : 0;
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, 'Error fetching Quote metrics: ' + e.getMessage());
        }
        
        // Active Asset count
        try {
            AggregateResult[] assetResults = [
                SELECT COUNT(Id) cnt
                FROM Asset
                WHERE AccountId = :accountId
                WITH SECURITY_ENFORCED
            ];
            if (!assetResults.isEmpty()) {
                metrics.activeAssetCount = (Integer) assetResults[0].get('cnt');
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, 'Error fetching Asset metrics: ' + e.getMessage());
        }
        
        // Order total amount
        try {
            AggregateResult[] orderResults = [
                SELECT SUM(TotalAmount) total
                FROM Order
                WHERE AccountId = :accountId
                WITH SECURITY_ENFORCED
            ];
            if (!orderResults.isEmpty()) {
                Decimal total = (Decimal) orderResults[0].get('total');
                metrics.orderTotalAmount = total != null ? total : 0;
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, 'Error fetching Order metrics: ' + e.getMessage());
        }
        
        // Invoice total - try standard Invoice object first, then custom
        try {
            // Try Salesforce Billing Invoice object
            AggregateResult[] invoiceResults = [
                SELECT SUM(TotalAmount) total
                FROM Invoice
                WHERE BillingAccountId = :accountId OR ReferenceEntityId = :accountId
                WITH SECURITY_ENFORCED
            ];
            if (!invoiceResults.isEmpty()) {
                Decimal total = (Decimal) invoiceResults[0].get('total');
                metrics.invoiceTotalAmount = total != null ? total : 0;
            }
        } catch (Exception e) {
            // Invoice object may not exist or user may not have access
            System.debug(LoggingLevel.WARN, 'Error fetching Invoice metrics: ' + e.getMessage());
        }
        
        return metrics;
    }
    
    /**
     * @description Gets the count of quotes for an account
     * @param accountId The Account record Id
     * @return Number of quotes
     */
    @AuraEnabled(cacheable=true)
    public static Integer getQuoteCount(Id accountId) {
        if (accountId == null) return 0;
        
        try {
            return [SELECT COUNT() FROM Quote WHERE AccountId = :accountId WITH SECURITY_ENFORCED];
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, 'Error in getQuoteCount: ' + e.getMessage());
            return 0;
        }
    }
    
    /**
     * @description Gets the total price of all quotes for an account
     * @param accountId The Account record Id
     * @return Sum of quote total prices
     */
    @AuraEnabled(cacheable=true)
    public static Decimal getQuoteTotalPrice(Id accountId) {
        if (accountId == null) return 0;
        
        try {
            AggregateResult[] results = [
                SELECT SUM(TotalPrice) total
                FROM Quote
                WHERE AccountId = :accountId
                WITH SECURITY_ENFORCED
            ];
            Decimal total = (Decimal) results[0].get('total');
            return total != null ? total : 0;
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, 'Error in getQuoteTotalPrice: ' + e.getMessage());
            return 0;
        }
    }
    
    /**
     * @description Gets the count of active assets for an account
     * @param accountId The Account record Id
     * @return Number of active assets
     */
    @AuraEnabled(cacheable=true)
    public static Integer getActiveAssetCount(Id accountId) {
        if (accountId == null) return 0;
        
        try {
            return [SELECT COUNT() FROM Asset WHERE AccountId = :accountId WITH SECURITY_ENFORCED];
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, 'Error in getActiveAssetCount: ' + e.getMessage());
            return 0;
        }
    }
    
    /**
     * @description Gets the total order amount for an account
     * @param accountId The Account record Id
     * @return Sum of order amounts
     */
    @AuraEnabled(cacheable=true)
    public static Decimal getOrderTotalAmount(Id accountId) {
        if (accountId == null) return 0;
        
        try {
            AggregateResult[] results = [
                SELECT SUM(TotalAmount) total
                FROM Order
                WHERE AccountId = :accountId
                WITH SECURITY_ENFORCED
            ];
            Decimal total = (Decimal) results[0].get('total');
            return total != null ? total : 0;
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, 'Error in getOrderTotalAmount: ' + e.getMessage());
            return 0;
        }
    }
}
