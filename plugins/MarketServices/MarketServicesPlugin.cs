using System;
using System.Collections.Generic;
using System.Linq;
using Microsoft.Xrm.Sdk;
using Microsoft.Xrm.Sdk.Query;

namespace EasySpaces.Plugins
{
    /// <summary>
    /// Plugin to manage market services - replaces Salesforce MarketServices.cls
    /// Handles market-related operations and space relationships
    /// </summary>
    public class MarketServicesPlugin : IPlugin
    {
        public void Execute(IServiceProvider serviceProvider)
        {
            // Obtain the execution context from the service provider
            IPluginExecutionContext context = (IPluginExecutionContext)serviceProvider.GetService(typeof(IPluginExecutionContext));
            IOrganizationServiceFactory serviceFactory = (IOrganizationServiceFactory)serviceProvider.GetService(typeof(IOrganizationServiceFactory));
            IOrganizationService service = serviceFactory.CreateOrganizationService(context.UserId);
            ITracingService tracingService = (ITracingService)serviceProvider.GetService(typeof(ITracingService));

            try
            {
                tracingService.Trace("MarketServicesPlugin: Starting execution");

                // Handle different message types
                switch (context.MessageName.ToLower())
                {
                    case "create":
                    case "update":
                        HandleMarketOperations(context, service, tracingService);
                        break;
                    case "delete":
                        HandleMarketDeletion(context, service, tracingService);
                        break;
                }
            }
            catch (Exception ex)
            {
                tracingService.Trace("MarketServicesPlugin Error: " + ex.Message);
                throw new InvalidPluginExecutionException("MarketServices Plugin failed: " + ex.Message, ex);
            }
        }

        private void HandleMarketOperations(IPluginExecutionContext context, IOrganizationService service, ITracingService tracingService)
        {
            if (context.InputParameters.Contains("Target") && context.InputParameters["Target"] is Entity)
            {
                Entity target = (Entity)context.InputParameters["Target"];

                // Process market records
                if (target.LogicalName == "es_market")
                {
                    ValidateMarketData(target, service, tracingService);
                    EnrichMarketData(target, service, tracingService);
                }
                // Process space records when market relationship changes
                else if (target.LogicalName == "es_space")
                {
                    ValidateSpaceMarketRelationship(target, service, tracingService);
                }
            }
        }

        private void HandleMarketDeletion(IPluginExecutionContext context, IOrganizationService service, ITracingService tracingService)
        {
            if (context.InputParameters.Contains("Target") && context.InputParameters["Target"] is EntityReference)
            {
                EntityReference target = (EntityReference)context.InputParameters["Target"];

                if (target.LogicalName == "es_market")
                {
                    // Check if market has related spaces before deletion
                    CheckMarketDeletionConstraints(target.Id, service, tracingService);
                }
            }
        }

        /// <summary>
        /// Validates market data before save
        /// </summary>
        private void ValidateMarketData(Entity market, IOrganizationService service, ITracingService tracingService)
        {
            tracingService.Trace("MarketServices: Validating market data");

            // Ensure market name is unique
            if (market.Contains("es_name"))
            {
                var marketName = market.GetAttributeValue<string>("es_name");
                if (!string.IsNullOrEmpty(marketName))
                {
                    var query = new QueryExpression("es_market")
                    {
                        ColumnSet = new ColumnSet("es_marketid"),
                        Criteria = new FilterExpression()
                    };
                    query.Criteria.AddCondition("es_name", ConditionOperator.Equal, marketName);
                    
                    // Exclude current record if updating
                    if (market.Id != Guid.Empty)
                    {
                        query.Criteria.AddCondition("es_marketid", ConditionOperator.NotEqual, market.Id);
                    }

                    var duplicates = service.RetrieveMultiple(query);
                    if (duplicates.Entities.Count > 0)
                    {
                        throw new InvalidPluginExecutionException($"A market with the name '{marketName}' already exists.");
                    }
                }
            }

            // Validate city and state combination
            if (market.Contains("es_city") && market.Contains("es_state"))
            {
                var city = market.GetAttributeValue<string>("es_city");
                var state = market.GetAttributeValue<string>("es_state");

                if (string.IsNullOrEmpty(city))
                {
                    throw new InvalidPluginExecutionException("City is required for market records.");
                }

                // Standardize state format (could add more validation here)
                if (!string.IsNullOrEmpty(state))
                {
                    market["es_state"] = state.ToUpperInvariant().Trim();
                }
            }
        }

        /// <summary>
        /// Enriches market data with additional information
        /// </summary>
        private void EnrichMarketData(Entity market, IOrganizationService service, ITracingService tracingService)
        {
            try
            {
                tracingService.Trace("MarketServices: Enriching market data");

                // Set default country if not provided
                if (!market.Contains("es_country") || string.IsNullOrEmpty(market.GetAttributeValue<string>("es_country")))
                {
                    market["es_country"] = "United States";
                }

                // Calculate related space count (for display purposes)
                if (market.Id != Guid.Empty)
                {
                    var relatedSpaces = GetRelatedSpacesCount(market.Id, service, tracingService);
                    market["es_spacecount"] = relatedSpaces;
                }
            }
            catch (Exception ex)
            {
                tracingService.Trace("MarketServices EnrichMarketData Error: " + ex.Message);
                // Don't throw - this is enhancement, not critical
            }
        }

        /// <summary>
        /// Validates space-market relationship
        /// </summary>
        private void ValidateSpaceMarketRelationship(Entity space, IOrganizationService service, ITracingService tracingService)
        {
            if (space.Contains("es_marketid"))
            {
                var marketRef = space.GetAttributeValue<EntityReference>("es_marketid");
                if (marketRef != null)
                {
                    // Verify the market exists and is active
                    try
                    {
                        var market = service.Retrieve("es_market", marketRef.Id, new ColumnSet("es_name", "statecode"));
                        if (market.GetAttributeValue<OptionSetValue>("statecode").Value != 0) // Not active
                        {
                            throw new InvalidPluginExecutionException("Cannot assign space to an inactive market.");
                        }
                    }
                    catch (Exception ex)
                    {
                        if (ex is InvalidPluginExecutionException)
                            throw;
                        
                        throw new InvalidPluginExecutionException("The selected market does not exist or is not accessible.");
                    }
                }
            }
        }

        /// <summary>
        /// Checks constraints before allowing market deletion
        /// </summary>
        private void CheckMarketDeletionConstraints(Guid marketId, IOrganizationService service, ITracingService tracingService)
        {
            tracingService.Trace("MarketServices: Checking deletion constraints");

            // Check for related spaces
            var relatedSpacesCount = GetRelatedSpacesCount(marketId, service, tracingService);
            if (relatedSpacesCount > 0)
            {
                throw new InvalidPluginExecutionException($"Cannot delete market. There are {relatedSpacesCount} spaces assigned to this market. Please reassign or delete the spaces first.");
            }

            // Check for related reservations (through spaces)
            var relatedReservationsCount = GetRelatedReservationsCount(marketId, service, tracingService);
            if (relatedReservationsCount > 0)
            {
                throw new InvalidPluginExecutionException($"Cannot delete market. There are {relatedReservationsCount} reservations associated with spaces in this market.");
            }
        }

        /// <summary>
        /// Gets count of spaces related to a market
        /// Replaces the getRelatedSpaces method from Salesforce (returns count instead of full list)
        /// </summary>
        private int GetRelatedSpacesCount(Guid marketId, IOrganizationService service, ITracingService tracingService)
        {
            try
            {
                var query = new QueryExpression("es_space")
                {
                    ColumnSet = new ColumnSet("es_spaceid"),
                    Criteria = new FilterExpression()
                };
                query.Criteria.AddCondition("es_marketid", ConditionOperator.Equal, marketId);

                var results = service.RetrieveMultiple(query);
                return results.Entities.Count;
            }
            catch (Exception ex)
            {
                tracingService.Trace("MarketServices GetRelatedSpacesCount Error: " + ex.Message);
                return 0;
            }
        }

        /// <summary>
        /// Gets count of reservations related to spaces in a market
        /// </summary>
        private int GetRelatedReservationsCount(Guid marketId, IOrganizationService service, ITracingService tracingService)
        {
            try
            {
                // First get spaces in this market
                var spaceQuery = new QueryExpression("es_space")
                {
                    ColumnSet = new ColumnSet("es_spaceid"),
                    Criteria = new FilterExpression()
                };
                spaceQuery.Criteria.AddCondition("es_marketid", ConditionOperator.Equal, marketId);

                var spaces = service.RetrieveMultiple(spaceQuery);
                if (spaces.Entities.Count == 0)
                    return 0;

                var spaceIds = spaces.Entities.Select(s => s.Id).ToArray();

                // Now count reservations for these spaces
                var reservationQuery = new QueryExpression("es_reservation")
                {
                    ColumnSet = new ColumnSet("es_reservationid"),
                    Criteria = new FilterExpression()
                };
                reservationQuery.Criteria.AddCondition("es_spaceid", ConditionOperator.In, spaceIds);

                var reservations = service.RetrieveMultiple(reservationQuery);
                return reservations.Entities.Count;
            }
            catch (Exception ex)
            {
                tracingService.Trace("MarketServices GetRelatedReservationsCount Error: " + ex.Message);
                return 0;
            }
        }

        /// <summary>
        /// Gets related spaces for a market - full implementation of Salesforce getRelatedSpaces
        /// This would be called via a custom action or web API
        /// </summary>
        public static List<SpaceData> GetRelatedSpaces(Guid marketId, IOrganizationService service)
        {
            var spaces = new List<SpaceData>();

            try
            {
                var query = new QueryExpression("es_space")
                {
                    ColumnSet = new ColumnSet("es_spaceid", "es_name", "es_dailyrate", "es_maximumcapacity", 
                                            "es_minimumcapacity", "es_pictureurl", "es_category", "es_type"),
                    Criteria = new FilterExpression()
                };
                query.Criteria.AddCondition("es_marketid", ConditionOperator.Equal, marketId);

                var results = service.RetrieveMultiple(query);

                foreach (var space in results.Entities)
                {
                    spaces.Add(new SpaceData
                    {
                        Id = space.Id,
                        Name = space.GetAttributeValue<string>("es_name"),
                        DailyRate = space.GetAttributeValue<Money>("es_dailyrate")?.Value ?? 0,
                        MaximumCapacity = space.GetAttributeValue<int>("es_maximumcapacity"),
                        MinimumCapacity = space.GetAttributeValue<int>("es_minimumcapacity"),
                        PictureUrl = space.GetAttributeValue<string>("es_pictureurl"),
                        Category = space.GetAttributeValue<OptionSetValue>("es_category")?.Value,
                        Type = space.GetAttributeValue<OptionSetValue>("es_type")?.Value
                    });
                }
            }
            catch (Exception ex)
            {
                throw new InvalidPluginExecutionException("Error retrieving related spaces: " + ex.Message, ex);
            }

            return spaces;
        }
    }

    /// <summary>
    /// Data class for space information - replaces Space__c fields from Salesforce
    /// </summary>
    public class SpaceData
    {
        public Guid Id { get; set; }
        public string Name { get; set; }
        public decimal DailyRate { get; set; }
        public int MaximumCapacity { get; set; }
        public int MinimumCapacity { get; set; }
        public string PictureUrl { get; set; }
        public int? Category { get; set; }
        public int? Type { get; set; }
    }
}