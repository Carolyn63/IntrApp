module CompaniesHelper

  def company_industries
    i18n_keys = ["advertising_and_marketing", "aerospace", "agriculture", "apparel", "associations_non_profits",
                 "automotive_services", "beverages", "building_and_construction", "computer_hardware", "computer_software",
                 "consumer_electronics_and_appliances", "consumer_services", "defense", "e_commerce_and_it_outsourcing",
                 "educational_services", "electrical", "electronics", "energy_and_resources", "environmental_markets", "fabrication",
                 "financial", "food", "food_processing", "furnishings", "government", "healthcare", "housing", "information_technology",
                 "insurance", "legal", "machinery_and_equipment", "manufacturing", "materials_and_chemicals", "media",
                 "medical_equipment_and_devices", "other", "pharmaceuticals", "printing_and_publishing", "professional_services",
                 "real_estate", "restaurants_and_bars", "shopping_and_stores", "telecommunications_and_wireless", "textiles",
                 "transportation_and_shipping", "travel_and_leisure", "warehousing_and_storage"]
#    industries = [ "Advertising and Marketing", "Aerospace", "Agriculture", "Apparel",
#                  "Associations/Non-Profits", "Automotive Services", "Beverages", "Building aand Construction",
#                  "Computer Hardware", "Computer Software", "Consumer Electronics and Appliances", "Consumer Services",
#                  "Defense", "E-Commerce and IT Outsourcing", "Educational Services", "Electrical", "Electronics",
#                  "Energy and Resources", "Environmental Markets", "Fabrication", "Financial", "Food", "Food Processing",
#                  "Furnishings", "Government", "Healthcare", "Housing", "Information Technology", "Insurance", "Legal",
#                  "Machinery and Equipment", "Manufacturing", "Materials and Chemicals", "Media", "Medical Equipment and Devices",
#                  "Other", "Pharmaceuticals", "Printing and Publishing", "Professional Services", "Real Estate",
#                  "Restaurants and Bars", "Shopping and Sotres", "Telecommunications and Wireless", "Textiles",
#                  "Transportation and Shipping", "Travel and Leisure", "Warehousing and Storage"]
#    industries.map{|i| [i, i] }
    i18n_keys.map{|k| [I18n.t("helpers.companies.#{k}"), I18n.t("helpers.companies.#{k}")] }
  end

end
