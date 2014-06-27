class ISOCountryCode

  module CountryISO
    LIST = ["Holy See (Vatican City State):VA", "Cocos (Keeling) Islands:CC", "Guatemala:GT", "Japan:JP", 
            "Sweden:SE", "Tanzania, United Republic of:TZ", "Congo, The Democratic Republic of the:CD", 
            "Guam:GU", "Myanmar:MM", "Algeria:DZ", "Mongolia:MN", "Pakistan:PK", "Singapore:SG", "Saint Vincent and the Grenadines:VC", 
            "Central African Republic:CF", "Guinea-Bissau:GW", "Macao:MO", "Poland:PL", "Saint Helena:SH", "Venezuela, Bolivarian republic of:VE", 
            "Congo:CG", "Northern Mariana Islands:MP", "Saint Pierre and Miquelon:PM", "Slovenia:SI", "Zimbabwe:ZW",
            "Switzerland:CH", "Guyana:GY", "Martinique:MQ", "Pitcairn:PN", "Svalbard and Jan Mayen:SJ", "Virgin Islands, British:VG", 
            "Åland Islands:AX", "Mauritania:MR", "Slovakia:SK", "Montserrat:MS", "Sierra Leone:SL", "Yemen:YE",
            "Virgin Islands, U.S.:VI", "Cook Islands:CK", "Indonesia:ID", "Malta:MT", "San Marino:SM", "Chile:CL",
            "Ireland:IE", "Lao Peoples Democratic Republics Democratic Republic:LA", "Mauritius:MU", "Senegal:SN",
            "Cameroon:CM", "Finland:FI", "Lebanon:LB", "Maldives:MV", "Puerto Rico:PR", "Somalia:SO", "China:CN", 
            "Fiji:FJ", "Saint Lucia:LC", "Malawi:MW", "Palestinian Territory, Occupied:PS", "Colombia:CO", "Falkland Islands (Malvinas):FK", 
            "Mexico:MX", "Portugal:PT", "Viet Nam:VN", "Malaysia:MY", "Suriname:SR", "Micronesia, Federated States of:FM", "Mozambique:MZ", 
            "Costa Rica:CR", "Palau:PW", "Faroe Islands:FO", "Sao Tome and Principe:ST", "Israel:IL", "Liechtenstein:LI", "Paraguay:PY", 
            "Bosnia and Herzegovina:BA", "Cuba:CU", "Isle of Man:IM", "El Salvador:SV", "Cape Verde:CV", "France:FR", "India:IN", "Sri Lanka:LK", 
            "Vanuatu:VU", "Barbados:BB", "British Indian Ocean Territory:IO", "Ukraine:UA", "Christmas Island:CX",
            "Reunion:RE", "Syrian Arab Republic:SY", "Cyprus:CY", "Iraq:IQ", "Swaziland:SZ", "Bangladesh:BD", "Czech Republic:CZ", 
            "Iran, Islamic Republic of:IR", "Mayotte:YT", "Belgium:BE", "Iceland:IS", "Burkina Faso:BF", "Ecuador:EC", "Italy:IT", "Oman:OM", 
            "Bulgaria:BG", "Bahrain:BH", "Uganda:UG", "Liberia:LR", "Burundi:BI", "Estonia:EE", "Lesotho:LS", "Benin:BJ", "Lithuania:LT", 
            "Egypt:EG", "Western Sahara:EH", "Saint Barthélemy:BL", "Luxembourg:LU", "Romania:RO", "Bermuda:BM", "Latvia:LV", "Brunei Darussalam:BN", 
            "United States Minor Outlying Islands:UM", "Bolivia, Plurinational State of:BO", "Kenya:KE", "Namibia:NA", "Libyan Arab Jamahiriya:LY", 
            "Brazil:BR", "Kyrgyzstan:KG", "New Caledonia:NC", "Serbia:RS", "Bahamas:BS", "Hong Kong:HK", "Cambodia:KH", "Bhutan:BT", "Kiribati:KI", 
            "Niger:NE", "Qatar:QA", "Russian Federation:RU", "United States:US", "Heard Island and McDonald Islands:HM", "Norfolk Island:NF", "Bouvet Island:BV", 
            "Eritrea:ER", "Honduras:HN", "Nigeria:NG", "Rwanda:RW", "Botswana:BW", "Spain:ES", "Ethiopia:ET", "Nicaragua:NI", "Andorra:AD", "Belarus:BY", "Comoros:KM", 
            "United Arab Emirates:AE", "Turks and Caicos Islands:TC", "Belize:BZ", "Croatia:HR", "Saint Kitts and Nevis:KN", "Afghanistan:AF", "Netherlands:NL", "Chad:TD",
            "Uruguay:UY", "Antigua and Barbuda:AG", "Haiti:HT", "Korea, Democratic Peoples Republic ofs Republic of:KP", "Uzbekistan:UZ", "Gabon:GA", "Hungary:HU", "French Southern Territories:TF", 
            "United Kingdom:GB", "Anguilla:AI", "Germany:DE", "Korea, Republic of:KR", "Togo:TG", "Norway:NO", "Thailand:TH", "Grenada:GD", "Nepal:NP", "South Africa:ZA", "Wallis and Futuna:WF", 
            "Albania:AL", "Georgia:GE", "Tajikistan:TJ", "Armenia:AM", "French Guiana:GF", "Nauru:NR", "Tokelau:TK", "Netherlands Antilles:AN", "Djibouti:DJ", "Kuwait:KW", "Timor-Leste:TL", 
            "Turkmenistan:TM", "Angola:AO", "Denmark:DK", "Guernsey:GG", "Tunisia:TN", "Ghana:GH", "Jersey:JE", "Morocco:MA", "Cayman Islands:KY", "Niue:NU", "Dominica:DM", "Gibraltar:GI", 
            "Kazakhstan:KZ", "Tonga:TO", "Antarctica:AQ", "Monaco:MC", "Argentina:AR", "Moldova, Republic of:MD", "American Samoa:AS", "Dominican Republic:DO", "Turkey:TR", "Montenegro:ME", 
            "Panama:PA", "Austria:AT", "Greenland:GL", "Saint Martin (French part):MF", "New Zealand:NZ", "Australia:AU", "Gambia:GM", "Madagascar:MG", "Guinea:GN", "Zambia:ZM", "Trinidad and Tobago:TT",
            "Marshall Islands:MH", "Aruba:AW", "Peru:PE", "Saudi Arabia:SA", "Côte dIvoireIvoire:CI", "Guadeloupe:GP", "Tuvalu:TV", "French Polynesia:PF", "Solomon Islands:SB", 
            "Samoa:WS", "Canada:CA", "Equatorial Guinea:GQ", "Jamaica:JM", "Seychelles:SC", "Taiwan, Province of China:TW", "Azerbaijan:AZ", "Greece:GR", "Macedonia, Republic of:MK", 
            "Papua New Guinea:PG", "Sudan:SD", "South Georgia and the South Sandwich Islands:GS", "Jordan:JO", "Mali:ML", "Philippines:PH"]
    
    TO_CODE = {}
    LIST.each do |line|
      country, code = line.strip.split(":", 2)
      TO_CODE[country] = code
    end
    
    TO_COUNTRY = {}
    LIST.each do |line|
      country, code = line.strip.split(":", 2)
      TO_COUNTRY[code] = country
    end
  end

  def self.iso_country_code(country = "United States")
    CountryISO::TO_CODE[country].to_s
  end

  def self.iso_country(code = "US")
    CountryISO::TO_COUNTRY[code].to_s
  end

end
