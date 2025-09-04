using System;
using System.Collections.Generic;
using System.Linq;
using Microsoft.Xrm.Sdk;
using Microsoft.Xrm.Sdk.Query;

namespace EasySpaces.Plugins
{
    /// <summary>
    /// Plugin to manage customer services - replaces Salesforce CustomerServices.cls
    /// Handles customer field configuration and customer data operations
    /// </summary>
    public class CustomerServicesPlugin : IPlugin
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
                tracingService.Trace("CustomerServicesPlugin: Starting execution");

                // Handle different message types
                switch (context.MessageName.ToLower())
                {
                    case "create":
                    case "update":
                        HandleCustomerDataOperations(context, service, tracingService);
                        break;
                    case "retrieve":
                        // Custom retrieve logic if needed
                        break;
                }
            }
            catch (Exception ex)
            {
                tracingService.Trace("CustomerServicesPlugin Error: " + ex.Message);
                throw new InvalidPluginExecutionException("CustomerServices Plugin failed: " + ex.Message, ex);
            }
        }

        private void HandleCustomerDataOperations(IPluginExecutionContext context, IOrganizationService service, ITracingService tracingService)
        {
            if (context.InputParameters.Contains("Target") && context.InputParameters["Target"] is Entity)
            {
                Entity target = (Entity)context.InputParameters["Target"];

                // Process contact records (customer data)
                if (target.LogicalName == "contact")
                {
                    EnrichCustomerData(target, service, tracingService);
                    ValidateCustomerData(target, service, tracingService);
                }
            }
        }

        /// <summary>
        /// Enriches customer data with additional information
        /// Replaces the getCustomerFields functionality from Salesforce
        /// </summary>
        private void EnrichCustomerData(Entity contact, IOrganizationService service, ITracingService tracingService)
        {
            try
            {
                tracingService.Trace("CustomerServices: Enriching customer data");

                // Get customer configuration from custom entity (replaces Customer_Fields__mdt)
                var customerConfig = GetCustomerFieldConfiguration(service, tracingService);

                if (customerConfig != null)
                {
                    // Apply default values based on configuration
                    if (customerConfig.Contains("es_defaultstatus") && !contact.Contains("es_customerstatus"))
                    {
                        contact["es_customerstatus"] = customerConfig["es_defaultstatus"];
                    }

                    // Format customer name if needed
                    if (contact.Contains("firstname") && contact.Contains("lastname"))
                    {
                        var firstName = contact.GetAttributeValue<string>("firstname");
                        var lastName = contact.GetAttributeValue<string>("lastname");
                        
                        if (!string.IsNullOrEmpty(firstName) && !string.IsNullOrEmpty(lastName))
                        {
                            contact["fullname"] = $"{firstName} {lastName}";
                        }
                    }

                    // Standardize state/city formatting
                    if (contact.Contains("address1_stateorprovince"))
                    {
                        var state = contact.GetAttributeValue<string>("address1_stateorprovince");
                        if (!string.IsNullOrEmpty(state))
                        {
                            contact["address1_stateorprovince"] = state.ToUpperInvariant().Trim();
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                tracingService.Trace("CustomerServices EnrichCustomerData Error: " + ex.Message);
                // Don't throw - this is enhancement, not critical
            }
        }

        /// <summary>
        /// Validates customer data
        /// </summary>
        private void ValidateCustomerData(Entity contact, IOrganizationService service, ITracingService tracingService)
        {
            tracingService.Trace("CustomerServices: Validating customer data");

            // Validate email format if provided
            if (contact.Contains("emailaddress1"))
            {
                var email = contact.GetAttributeValue<string>("emailaddress1");
                if (!string.IsNullOrEmpty(email) && !IsValidEmail(email))
                {
                    throw new InvalidPluginExecutionException("Invalid email address format");
                }
            }

            // Ensure required fields are present for reservation customers
            if (contact.Contains("es_isreservationcustomer") && 
                contact.GetAttributeValue<bool>("es_isreservationcustomer"))
            {
                if (!contact.Contains("emailaddress1") || string.IsNullOrEmpty(contact.GetAttributeValue<string>("emailaddress1")))
                {
                    throw new InvalidPluginExecutionException("Email address is required for reservation customers");
                }

                if (!contact.Contains("fullname") || string.IsNullOrEmpty(contact.GetAttributeValue<string>("fullname")))
                {
                    throw new InvalidPluginExecutionException("Full name is required for reservation customers");
                }
            }
        }

        /// <summary>
        /// Gets customer field configuration from custom configuration entity
        /// Replaces Customer_Fields__mdt from Salesforce
        /// </summary>
        private Entity GetCustomerFieldConfiguration(IOrganizationService service, ITracingService tracingService)
        {
            try
            {
                var query = new QueryExpression("es_customerconfig")
                {
                    ColumnSet = new ColumnSet("es_name", "es_defaultstatus", "es_requiredemail", "es_requiredfields"),
                    Criteria = new FilterExpression()
                };
                query.Criteria.AddCondition("es_name", ConditionOperator.Equal, "default");

                var results = service.RetrieveMultiple(query);
                return results.Entities.FirstOrDefault();
            }
            catch (Exception ex)
            {
                tracingService.Trace("CustomerServices GetCustomerFieldConfiguration Error: " + ex.Message);
                return null;
            }
        }

        /// <summary>
        /// Validates email format
        /// </summary>
        private bool IsValidEmail(string email)
        {
            try
            {
                var addr = new System.Net.Mail.MailAddress(email);
                return addr.Address == email;
            }
            catch
            {
                return false;
            }
        }

        /// <summary>
        /// Gets customer fields for a specific object type
        /// Replaces the @AuraEnabled getCustomerFields method from Salesforce
        /// This would be called via a custom action or web API
        /// </summary>
        public static CustomerFieldsResponse GetCustomerFields(string objectType, IOrganizationService service)
        {
            var response = new CustomerFieldsResponse();

            try
            {
                // Query configuration based on object type
                var query = new QueryExpression("es_customerconfig")
                {
                    ColumnSet = new ColumnSet("es_customernameapi", "es_customeremailapi", "es_customercityapi", "es_customerstateapi"),
                    Criteria = new FilterExpression()
                };
                query.Criteria.AddCondition("es_objecttype", ConditionOperator.Equal, objectType);

                var results = service.RetrieveMultiple(query);
                var config = results.Entities.FirstOrDefault();

                if (config != null)
                {
                    response.CustomerNameField = config.GetAttributeValue<string>("es_customernameapi");
                    response.CustomerEmailField = config.GetAttributeValue<string>("es_customeremailapi");
                    response.CustomerCityField = config.GetAttributeValue<string>("es_customercityapi");
                    response.CustomerStateField = config.GetAttributeValue<string>("es_customerstateapi");
                }
                else
                {
                    // Default field mappings
                    response.CustomerNameField = "fullname";
                    response.CustomerEmailField = "emailaddress1";
                    response.CustomerCityField = "address1_city";
                    response.CustomerStateField = "address1_stateorprovince";
                }
            }
            catch (Exception ex)
            {
                throw new InvalidPluginExecutionException("Error retrieving customer fields: " + ex.Message, ex);
            }

            return response;
        }
    }

    /// <summary>
    /// Response class for customer fields - replaces the Customer inner class from Salesforce
    /// </summary>
    public class CustomerFieldsResponse
    {
        public string CustomerNameField { get; set; }
        public string CustomerEmailField { get; set; }
        public string CustomerCityField { get; set; }
        public string CustomerStateField { get; set; }
        public string CustomerStatusField { get; set; }
        public string CustomerPhoneField { get; set; }
    }
}