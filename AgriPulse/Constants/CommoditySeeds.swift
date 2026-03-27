import Foundation

struct CommoditySeed {
    let name: String
    let searchQueries: String
    let isSpecial: Bool
}

enum CommoditySeeds {
    static let all: [CommoditySeed] = regular + special + market + equity

    // MARK: - Regular commodities (ported from server/routes.ts lines 21-49 + syncCommodityQueries)

    static let regular: [CommoditySeed] = [
        CommoditySeed(
            name: "Wheat",
            searchQueries: """
            ("Wheat" OR "Atta" OR "Durum") AND (India OR FCI OR Procurement OR MSP OR Mandi OR Price OR Stock OR Import OR Export OR "crop situation" OR "wheat target" OR "wheat production")
            Wheat (farmers OR "record output" OR "harvest forecast" OR "bumper crop" OR "Rabi wheat" OR "wheat output" OR procurement OR "Agriculture Minister" OR review OR minister) India
            Wheat India ("unseasonal rain" OR hailstorm OR "crop damage" OR "crop loss" OR "crop destroyed" OR flatten OR lodging OR "weather damage" OR "strong winds" OR "standing crop")
            Wheat (Punjab OR Haryana OR "Uttar Pradesh" OR UP OR "Madhya Pradesh" OR MP OR Rajasthan) India (mandi OR price OR damage OR procurement OR farmer OR yield OR arrival)
            ("grain stock" OR "grain stocks" OR "foodgrain stock" OR "food grain" OR "surplus grain" OR "grain reserve") India (FCI OR government OR officials OR "food security")
            ("PP bag" OR "polypropylene bag" OR "jute bag" OR "procurement bag" OR "gunny bag") wheat (India OR MP OR "Madhya Pradesh" OR Punjab OR Haryana OR FCI OR procurement)
            Wheat India (site:krishijagran.com OR site:agriwatch.com OR site:igrain.in OR site:ibef.org OR site:krishakjagat.net)
            Wheat India (site:economictimes.indiatimes.com OR site:thehindu.com OR site:timesofindia.indiatimes.com OR site:tribuneindia.com OR site:livemint.com)
            Wheat India (site:hindustantimes.com OR site:indianexpress.com OR site:ndtv.com OR site:businessline.com OR site:financialexpress.com)
            """,
            isSpecial: false
        ),
        CommoditySeed(
            name: "Maize",
            searchQueries: """
            ("Maize" OR "Corn" OR "Makka") AND (India OR Bihar OR Nizamabad OR Davangere OR "Poultry Feed" OR Starch OR Ethanol OR MSP OR Mandi) -"US Corn" -"Brazil Corn" -"Chicago Board"
            Maize India ethanol poultry starch demand price
            Maize OR Corn India (site:krishijagran.com OR site:agriwatch.com OR site:igrain.in)
            Maize OR Corn India (site:economictimes.indiatimes.com OR site:thehindu.com OR site:timesofindia.indiatimes.com OR site:tribuneindia.com)
            ("E20" OR "E10" OR "ethanol blending" OR "ethanol mandate" OR "blending mandate" OR "petrol blending") India (maize OR corn OR food security OR feedstock OR grain)
            """,
            isSpecial: false
        ),
        CommoditySeed(
            name: "Paddy",
            searchQueries: """
            ("Paddy" OR "Rice" OR "Basmati" OR "Non-Basmati") AND (India OR FCI OR Procurement OR MSP OR Mandi OR Price OR Export OR Stock OR Levy)
            Paddy rice India sowing procurement kharif season
            Paddy OR Rice OR Basmati India (site:krishijagran.com OR site:agriwatch.com OR site:igrain.in)
            Paddy OR Basmati India (site:economictimes.indiatimes.com OR site:thehindu.com OR site:timesofindia.indiatimes.com OR site:tribuneindia.com OR site:freshplaza.com)
            rice "export rates" India (Vietnam OR Thailand OR Myanmar OR "global demand" OR "global market") -recipe
            """,
            isSpecial: false
        ),
        CommoditySeed(
            name: "Chana",
            searchQueries: """
            ("Chana" OR "Bengal Gram" OR "Desi Chana" OR "Kabuli Chana" OR chickpea) AND (India OR NAFED OR MSP OR Procurement OR Mandi OR Price OR Stock OR Gujarat OR Karnataka OR Rajasthan) -groundnut -peanut -gold -silver
            (gram OR chana OR chickpea OR "green gram") India MSP procurement (Gujarat OR "Andhra Pradesh" OR Karnataka OR Maharashtra OR Rajasthan OR NAFED OR NCCF) -gold -silver
            Chana gram pulse India import buffer stock price arrivals -gold -silver -bullion
            Chana OR "Bengal Gram" India (site:krishijagran.com OR site:agriwatch.com OR site:igrain.in) -gold -silver
            Chana India (site:economictimes.indiatimes.com OR site:thehindu.com OR site:timesofindia.indiatimes.com OR site:tribuneindia.com OR site:livemint.com) -gold -silver
            (chana OR gram OR pulse) India (site:thehansindia.com OR site:lokmattimes.com OR site:telegraphindia.com OR site:deccanherald.com OR site:hindustantimes.com) -gold -silver
            pulses India (import OR export OR "duty-free" OR "duty free" OR policy OR procurement OR NAFED OR NCCF OR stock OR price OR MSP OR ban OR notification) -gold -silver
            """,
            isSpecial: false
        ),
        CommoditySeed(
            name: "Palm Oil",
            searchQueries: """
            ("Palm Oil" OR "Crude Palm Oil" OR CPO OR MPOB OR GAPKI OR "Refined Palm Oil" OR "Palm Olein")
            "Palm Oil" India import edible oil duty tariff price
            "Palm Oil" OR CPO (site:economictimes.indiatimes.com OR site:agriwatch.com OR site:thehindu.com OR site:freshplaza.com)
            "Palm Oil" (site:freshplaza.com OR site:freshfruitportal.com OR site:krishijagran.com)
            "vegetable oil" India buyers import price (Iran OR rally OR market OR duty OR tariff OR edible)
            ("edible oil" OR "vegetable oil") India import buyers Iran war rally (site:economictimes.indiatimes.com OR site:thehindu.com OR site:businessline.com OR site:livemint.com)
            """,
            isSpecial: false
        ),
        CommoditySeed(
            name: "Potato",
            searchQueries: """
            (Potato OR Aloo OR "Potato Market") AND (India OR Mandi OR Retail OR Wholesale OR Price OR Market) -recipe -cook
            Potato India cold storage supply price Agra UP
            Potato India (site:krishijagran.com OR site:agriwatch.com OR site:igrain.in)
            Potato India (site:economictimes.indiatimes.com OR site:thehindu.com OR site:timesofindia.indiatimes.com OR site:tribuneindia.com)
            """,
            isSpecial: false
        ),
        CommoditySeed(
            name: "Sugar",
            searchQueries: """
            ("Sugar" OR "Sugarcane" OR "Ethanol" OR FRP) AND (India OR ISMA OR NFCSF OR Mill OR Mandi OR Price OR Stock OR Export OR Quota)
            Sugar India mill production export diversion ethanol
            ("sugar MSP" OR "sugar federation" OR "NFCSF" OR "FRP" OR "cane price" OR "fair remunerative price") India
            Sugar India MSP subsidy government intervention quintal price policy
            Sugar India (site:krishijagran.com OR site:agriwatch.com OR site:igrain.in)
            Sugar India (site:economictimes.indiatimes.com OR site:thehindu.com OR site:timesofindia.indiatimes.com OR site:tribuneindia.com)
            Sugar India (site:indianexpress.com OR site:livemint.com OR site:businessline.com OR site:financialexpress.com OR site:hindustantimes.com)
            """,
            isSpecial: false
        ),
        CommoditySeed(
            name: "Ethanol / DDGS",
            searchQueries: """
            Ethanol India blending policy production OMC price target mandate
            ("E20" OR "E10" OR "20 per cent blend" OR "20% blend" OR "blending mandate" OR "blending target") India ethanol (industry OR OMC OR government OR "crude import" OR petrol OR cost)
            Ethanol India (industry OR producers OR distillery OR OMC OR "oil marketing") (push OR demand OR advocate OR target OR increase OR expand OR "higher blend")
            ("flex fuel" OR "flex-fuel" OR "E100" OR "E-100" OR "higher blending" OR "biofuel policy") India ethanol petrol OMC
            ("ethanol blending" OR "blending roadmap" OR "AIDA" OR "distillery" OR "sugarcane ethanol" OR "grain ethanol") India
            DDGS India import poultry feed price distillers grain supply
            Ethanol OR DDGS India (site:economictimes.indiatimes.com OR site:thehindu.com OR site:timesofindia.indiatimes.com OR site:krishijagran.com)
            Ethanol OR DDGS India (site:agriwatch.com OR site:igrain.in OR site:ibef.org OR site:livemint.com)
            Ethanol India (site:telegraphindia.com OR site:hindustantimes.com OR site:indianexpress.com OR site:businessline.com OR site:financialexpress.com)
            Ethanol India (site:chinimandi.com OR site:sugaronline.com OR site:bioenergytimes.com OR site:ndtv.com)
            """,
            isSpecial: false
        ),
        CommoditySeed(
            name: "Rice bran oil",
            searchQueries: """
            "Rice Bran Oil" India price production export refinery
            "Rice Bran Oil" market edible oil India demand
            "Rice Bran Oil" India (site:agriwatch.com OR site:krishijagran.com OR site:economictimes.indiatimes.com OR site:thehindu.com)
            """,
            isSpecial: false
        ),
        CommoditySeed(
            name: "Soyabean / Oil",
            searchQueries: """
            ("Soybean Oil" OR "Soy Oil" OR CBOT OR "Soybean Price" OR "Brazil Soybean" OR "Argentina Soybean" OR "USDA Soybean")
            Soybean India import crushing price edible oil
            Soybean OR "Soy Oil" India (site:agriwatch.com OR site:igrain.in OR site:krishijagran.com OR site:freshplaza.com)
            Soybean India (site:economictimes.indiatimes.com OR site:thehindu.com OR site:timesofindia.indiatimes.com)
            """,
            isSpecial: false
        ),
        CommoditySeed(
            name: "Sunflower oil",
            searchQueries: """
            "Sunflower Oil" India price import edible oil duty tariff
            "Sunflower Oil" Ukraine Black Sea supply global price
            "Sunflower Oil" India (site:agriwatch.com OR site:krishijagran.com OR site:economictimes.indiatimes.com OR site:thehindu.com)
            """,
            isSpecial: false
        ),
        CommoditySeed(
            name: "Cotton seed oil",
            searchQueries: """
            "Cottonseed Oil" OR "Cotton seed oil" India price production demand
            Cottonseed India oil crushing market price
            "Cottonseed Oil" India (site:agriwatch.com OR site:krishijagran.com OR site:economictimes.indiatimes.com OR site:thehindu.com)
            """,
            isSpecial: false
        ),
        CommoditySeed(
            name: "Cashew",
            searchQueries: """
            Cashew India trade policy export import tariff mandi price kernel
            Cashew India USA bilateral trade agreement deal
            "All India Cashew Association" OR AICA OR "cashew association" India
            Cashew Africa Vietnam kernel processing market supply chain
            Cashew illegal import India enforcement quality surge
            Cashew Andhra Pradesh OR Karnataka OR Kerala OR Goa market price arrivals
            Cashew India (site:agriwatch.com OR site:igrain.in OR site:krishijagran.com OR site:freshplaza.com)
            Cashew India (site:economictimes.indiatimes.com OR site:thehindu.com OR site:timesofindia.indiatimes.com OR site:tribuneindia.com)
            """,
            isSpecial: false
        ),
        CommoditySeed(
            name: "Almond",
            searchQueries: """
            Almond India import price mandi market trade tariff
            Almond California production crop yield harvest season forecast outlook
            Almond California groundwater water orchards sustainability removal acreage
            Almond California bloom weather rain frost pollination
            Almond Australia China export demand supply global trade
            Almond "Blue Diamond" OR "Almond Board of California" OR USDA crop estimate
            Almond India (site:agriwatch.com OR site:igrain.in OR site:krishijagran.com OR site:ibef.org)
            Almond (site:freshplaza.com OR site:freshfruitportal.com OR site:economictimes.indiatimes.com OR site:thehindu.com)
            """,
            isSpecial: false
        ),
        CommoditySeed(
            name: "Raisins",
            searchQueries: """
            ("Raisins" OR "Kishmish" OR "Dried Grapes") AND (India OR Sangli OR Nashik OR Price OR Mandi OR Export)
            Raisins India import price Afghanistan Iran quality
            Raisins India (site:agriwatch.com OR site:igrain.in OR site:krishijagran.com)
            Raisins India (site:economictimes.indiatimes.com OR site:thehindu.com OR site:freshplaza.com OR site:tribuneindia.com)
            """,
            isSpecial: false
        ),
        CommoditySeed(
            name: "Oats",
            searchQueries: """
            Oats India price import breakfast cereal market
            Oats India production crop demand
            Oats India (site:economictimes.indiatimes.com OR site:krishijagran.com OR site:thehindu.com OR site:agriwatch.com)
            """,
            isSpecial: false
        ),
        CommoditySeed(
            name: "Psyllium / Isabgol",
            searchQueries: """
            Psyllium OR Isabgol India price export Unjha Gujarat production
            Psyllium husk India demand pharmaceutical export quality
            Psyllium OR Isabgol India (site:agriwatch.com OR site:igrain.in OR site:krishijagran.com OR site:economictimes.indiatimes.com)
            """,
            isSpecial: false
        ),
        CommoditySeed(
            name: "Milk / Dairy",
            searchQueries: """
            Milk Dairy India price AMUL procurement inflation farmer
            "Milk price" OR "dairy sector" India production import export
            Milk OR Dairy India (site:economictimes.indiatimes.com OR site:thehindu.com OR site:timesofindia.indiatimes.com OR site:tribuneindia.com)
            Milk OR Dairy India (site:krishijagran.com OR site:agriwatch.com OR site:ibef.org)
            Milk OR Dairy India (site:thehansindia.com OR site:telegraphindia.com OR site:hindustantimes.com OR site:livemint.com OR site:ndtv.com)
            FSSAI milk dairy India (producer OR quality OR safety OR standard OR regulation OR certificate OR licence)
            """,
            isSpecial: false
        ),
        CommoditySeed(
            name: "Cocoa",
            searchQueries: """
            ("Cocoa" OR "Cacao") AND (India OR ICCO OR Price OR "Ivory Coast" OR Ghana OR Arrival)
            Cocoa India import chocolate demand processing
            Cocoa (site:agriwatch.com OR site:freshplaza.com OR site:krishijagran.com OR site:ibef.org)
            Cocoa Ghana "Ivory Coast" price supply (site:economictimes.indiatimes.com OR site:thehindu.com OR site:timesofindia.indiatimes.com)
            """,
            isSpecial: false
        ),
        CommoditySeed(
            name: "Chilli powder",
            searchQueries: """
            Chilli India price mandi Guntur Kheda Warangal export
            "Chilli" OR "Red pepper" India crop arrival market
            ("Indian chilli" OR "red chilli" OR "chilli export" OR "chilli crop") India (demand OR supply OR price OR output OR domestic OR overseas)
            Chilli India (site:agriwatch.com OR site:igrain.in OR site:krishijagran.com)
            Chilli India (site:economictimes.indiatimes.com OR site:thehindu.com OR site:timesofindia.indiatimes.com OR site:tribuneindia.com)
            Chilli India (site:thehindubusinessline.com OR site:businessline.com OR site:financialexpress.com OR site:indianexpress.com OR site:livemint.com)
            """,
            isSpecial: false
        ),
        CommoditySeed(
            name: "Turmeric",
            searchQueries: """
            Turmeric India price Nizamabad Sangli Erode Nanded export arrival
            Turmeric India crop sowing demand export quality
            Turmeric India (site:agriwatch.com OR site:igrain.in OR site:krishijagran.com)
            Turmeric India (site:economictimes.indiatimes.com OR site:thehindu.com OR site:tribuneindia.com OR site:freshplaza.com)
            """,
            isSpecial: false
        ),
        CommoditySeed(
            name: "Black pepper",
            searchQueries: """
            "Black Pepper" India Kerala price export mandi Kochi
            "Black Pepper" India Vietnam global supply price
            "Black Pepper" India (site:agriwatch.com OR site:igrain.in OR site:krishijagran.com)
            "Black Pepper" India (site:economictimes.indiatimes.com OR site:thehindu.com OR site:freshplaza.com)
            """,
            isSpecial: false
        ),
        CommoditySeed(
            name: "Cardamom",
            searchQueries: """
            Cardamom India Kerala auction price export arrival
            Cardamom India crop production demand global
            Cardamom India (site:agriwatch.com OR site:igrain.in OR site:krishijagran.com)
            Cardamom India (site:economictimes.indiatimes.com OR site:thehindu.com OR site:tribuneindia.com)
            """,
            isSpecial: false
        ),
        CommoditySeed(
            name: "Cabbage / Carrot",
            searchQueries: """
            Cabbage OR Carrot India price market wholesale retail vegetable
            Cabbage OR Carrot India supply shortage glut demand
            Cabbage OR Carrot India (site:krishijagran.com OR site:agriwatch.com OR site:thehindu.com OR site:timesofindia.indiatimes.com)
            """,
            isSpecial: false
        ),
        CommoditySeed(
            name: "Ring beans",
            searchQueries: """
            "Ring bean" OR "Kidney bean" OR Rajma India price mandi import
            Rajma OR "kidney bean" India crop market price
            Rajma OR "ring bean" India (site:agriwatch.com OR site:krishijagran.com OR site:economictimes.indiatimes.com)
            """,
            isSpecial: false
        ),
        CommoditySeed(
            name: "Onion",
            searchQueries: """
            ("Onion") AND (India OR NAFED OR NCCF OR Buffer OR "Export Duty" OR Mandi OR Price OR Stock)
            Onion India export ban duty price storage Nashik Lasalgaon
            Onion India (site:agriwatch.com OR site:igrain.in OR site:krishijagran.com)
            Onion India (site:economictimes.indiatimes.com OR site:thehindu.com OR site:timesofindia.indiatimes.com OR site:tribuneindia.com)
            """,
            isSpecial: false
        ),
        CommoditySeed(
            name: "Potato (Mandi)",
            searchQueries: """
            (Potato OR Aloo OR "Potato Market") AND (India OR Mandi OR Retail OR Wholesale OR Price OR Market) -recipe -cook
            Potato mandi arrival India Agra UP cold storage price
            Potato mandi India (site:agriwatch.com OR site:igrain.in OR site:krishijagran.com OR site:timesofindia.indiatimes.com)
            """,
            isSpecial: false
        ),
        CommoditySeed(
            name: "Groundnut",
            searchQueries: """
            Groundnut OR Peanut India price MSP NAFED export Saurashtra Rajkot
            Groundnut India oil crushing edible demand crop
            Groundnut OR Peanut India (site:agriwatch.com OR site:igrain.in OR site:krishijagran.com)
            Groundnut India (site:economictimes.indiatimes.com OR site:thehindu.com OR site:timesofindia.indiatimes.com OR site:tribuneindia.com)
            """,
            isSpecial: false
        ),
    ]

    // MARK: - Special commodities (ported from server/routes.ts lines 69-75)

    static let special: [CommoditySeed] = [
        CommoditySeed(
            name: "Agri Weather",
            searchQueries: """
            ("IMD" OR "India Meteorological Department" OR "Skymet") (forecast OR warning OR alert OR rainfall OR monsoon) India
            ("Southwest Monsoon" OR "Northeast Monsoon" OR "Monsoon India" OR "Indian monsoon" OR "monsoon 2025" OR "monsoon 2026") (crop OR farmer OR agriculture OR sowing OR harvest)
            ("Kharif" OR "Rabi" OR "zaid") (weather OR rainfall OR "dry spell" OR flood OR drought OR heatwave) India
            (heatwave OR drought OR flood OR "cold wave" OR cyclone OR "rainfall deficit" OR "excess rainfall") India (farmer OR crop OR agriculture OR "food production")
            ("El Nino" OR "El-Nino" OR "La Nina" OR "La-Nina" OR ENSO OR "Indian Ocean Dipole" OR IOD) (India OR monsoon OR rainfall OR crop OR agriculture OR sowing OR kharif OR rabi)
            """,
            isSpecial: true
        ),
        CommoditySeed(
            name: "PIB Updates",
            searchQueries: """
            site:pib.gov.in (wheat OR rice OR paddy OR maize OR corn OR chana OR pulses OR dal)
            site:pib.gov.in (sugar OR sugarcane OR edible oil OR palm oil OR oilseed OR groundnut OR soybean)
            site:pib.gov.in (onion OR potato OR vegetable OR horticulture OR tomato OR spice OR turmeric OR chilli)
            site:pib.gov.in (milk OR dairy OR farmer OR kisan OR agriculture OR msp OR procurement OR fci)
            site:pib.gov.in (export ban OR import duty OR food inflation OR food security OR crop OR grain storage)
            site:pib.gov.in (cashew OR almond OR raisin OR cocoa OR cardamom OR pepper OR fertilizer)
            """,
            isSpecial: true
        ),
        CommoditySeed(
            name: "Packaging",
            searchQueries: """
            "food packaging" India
            "flexible packaging" India
            "packaging industry" India
            laminates India packaging
            "BOPP" OR "BOPET" India packaging
            "multilayer packaging" India
            "agri packaging" OR "agricultural packaging" India
            "packaging material" India food
            "pouch" OR "sachet" India food packaging
            "rigid packaging" OR "glass packaging" OR "tin packaging" India food
            "glass bottle" OR "can makers" OR "aluminium can" OR "tin can" India shortage supply
            brewers India glass bottle can shortage supply chain Iran war
            """,
            isSpecial: true
        ),
        CommoditySeed(
            name: "DGFT Updates",
            searchQueries: """
            site:dgft.gov.in
            "DGFT" notification India export import
            "DGFT" circular "edible oil" OR "food" OR "agri"
            "Director General of Foreign Trade" India commodity
            "DGFT" export import policy India wheat OR rice OR sugar OR oil
            "DGFT" trade notice India
            """,
            isSpecial: true
        ),
        CommoditySeed(
            name: "IMD / Advisories",
            searchQueries: """
            "IMD" India agricultural advisory crop
            "India Meteorological Department" advisory farmer agriculture
            "IMD" heatwave OR flood OR drought India crop impact
            "IMD" monsoon forecast India 2026 agriculture
            "ICAR" advisory India crop
            "ICAR" research India wheat OR rice OR maize OR pulses
            site:icar.org.in
            "National Research Centre" India crop advisory
            "agromet" advisory India
            "crop advisory" India IMD OR ICAR OR state
            "Krishi Vigyan Kendra" advisory India
            "KVK" advisory crop India
            """,
            isSpecial: true
        ),
    ]

    // MARK: - Market commodities (ported from server/routes.ts lines 95-98)

    static let market: [CommoditySeed] = [
        CommoditySeed(
            name: "Crude",
            searchQueries: """
            Brent crude oil price WTI NYMEX OPEC supply demand barrel
            India crude oil import price Brent WTI energy market (site:economictimes.indiatimes.com OR site:thehindu.com OR site:businessline.com OR site:livemint.com)
            ("Crude Palm Oil" OR CPO) price MPOB Malaysia export import daily market
            OPEC crude oil production cut quota barrel price supply demand
            crude oil energy market price today (site:reuters.com OR site:oilprice.com)
            """,
            isSpecial: false
        ),
        CommoditySeed(
            name: "Precious Metals",
            searchQueries: """
            gold price India today MCX bullion market rate
            silver price India today MCX bullion market rate
            ("Gold price" OR "Silver price") (India OR international OR comex OR LBMA) today market
            gold OR silver (site:economictimes.indiatimes.com OR site:thehindu.com OR site:livemint.com OR site:financialexpress.com) price today rate
            ("Gold futures" OR "Silver futures" OR "COMEX gold" OR "LBMA gold" OR "MCX gold" OR "MCX silver") price market today
            """,
            isSpecial: false
        ),
        CommoditySeed(
            name: "Currency",
            searchQueries: """
            ("Indian rupee" OR "INR" OR "rupee") (dollar OR USD OR "exchange rate" OR forex) today
            rupee (falls OR slides OR drops OR "record low" OR weakens OR depreciation OR pressure) dollar India
            RBI intervention rupee forex market dollar (site:economictimes.indiatimes.com OR site:thehindu.com OR site:livemint.com OR site:businessline.com)
            rupee dollar (site:ndtv.com OR site:moneycontrol.com OR site:financialexpress.com OR site:reuters.com OR site:upstox.com)
            ("USD/INR" OR "INR/USD" OR "rupee-dollar" OR "rupee dollar") exchange rate RBI forex market
            rupee (imported inflation OR remittance OR oil import OR current account) India impact
            ("RBI" OR "Reserve Bank of India") (forex intervention OR dollar sales OR rupee support OR currency swap) India
            """,
            isSpecial: false
        ),
    ]

    // MARK: - Equity commodities (ported from Commodity-Watcher-2 server/routes.ts lines 309-335)

    static let equity: [CommoditySeed] = [
        CommoditySeed(
            name: "Indian Equity",
            searchQueries: """
            ("Nifty" OR "Sensex" OR "NSE" OR "BSE" OR "Dalal Street") India stock market today
            India equity (FII OR DII OR "foreign investor" OR "institutional" OR "domestic investor") market flows
            ("Nifty 50" OR "Bank Nifty" OR "Midcap" OR "IPO" OR "Sensex" OR "Smallcap") India market today
            India stock market (site:economictimes.indiatimes.com OR site:livemint.com OR site:financialexpress.com OR site:thehindu.com)
            India market (site:ndtv.com OR site:business-standard.com OR site:zeebiz.com OR site:moneycontrol.com)
            India (SEBI OR IPO OR "market cap" OR "block deal" OR "bulk deal" OR "circuit breaker" OR "upper circuit") equity today
            """,
            isSpecial: false
        ),
        CommoditySeed(
            name: "Global Equity",
            searchQueries: """
            ("Dow Jones" OR "S&P 500" OR "Nasdaq" OR "Wall Street") stock market today
            Global equity (market OR stocks OR rally OR correction OR bull OR bear OR gains OR losses) today
            ("FTSE" OR "Nikkei" OR "DAX" OR "Hang Seng" OR "Shanghai Composite" OR "CAC 40") stock market
            US market today stocks (site:reuters.com OR site:cnbc.com OR site:bloomberg.com OR site:wsj.com)
            Global stock market (site:economictimes.indiatimes.com OR site:livemint.com OR site:thehindu.com OR site:financialexpress.com)
            ("Federal Reserve" OR "Fed rate" OR "interest rate" OR "US economy" OR "recession") market impact stocks
            """,
            isSpecial: false
        ),
        CommoditySeed(
            name: "Crypto",
            searchQueries: """
            ("Bitcoin" OR "BTC") price today market crypto
            ("Ethereum" OR "ETH" OR "crypto" OR "cryptocurrency") price market today
            Crypto India (RBI OR SEBI OR tax OR regulation OR investment OR exchange OR "virtual digital asset")
            (site:coindesk.com OR site:cointelegraph.com) crypto Bitcoin Ethereum market today
            Crypto market (site:economictimes.indiatimes.com OR site:livemint.com OR site:thehindu.com OR site:ndtv.com OR site:financialexpress.com)
            ("Bitcoin" OR "Ethereum" OR "crypto") India (price OR market OR rally OR crash OR regulation OR tax) today
            """,
            isSpecial: false
        ),
        CommoditySeed(
            name: "Mutual Funds",
            searchQueries: """
            ("Mutual fund" OR "NAV" OR "SIP") India performance returns today
            Mutual fund India (AMFI OR SEBI OR "fund house" OR "NFO" OR "AUM" OR "expense ratio" OR returns OR performance)
            ("SIP" OR "Systematic Investment Plan" OR "Mutual Fund") India (site:economictimes.indiatimes.com OR site:livemint.com OR site:moneycontrol.com)
            Mutual fund India (site:financialexpress.com OR site:thehindu.com OR site:business-standard.com OR site:ndtv.com)
            ("equity fund" OR "debt fund" OR "hybrid fund" OR "index fund" OR "ELSS" OR "balanced fund") India returns performance
            Mutual fund India (top OR best OR worst OR ranking OR category OR switch OR redemption OR inflow OR outflow)
            """,
            isSpecial: false
        ),
    ]

    // MARK: - Market groups (matching Replit commodity-groups.ts)

    struct MarketGroup: Identifiable {
        let id: String
        let slug: String
        let label: String
        let subtitle: String
        let icon: String  // SF Symbol
        let commodities: [String]
    }

    static let marketGroups: [MarketGroup] = [
        MarketGroup(id: "grains", slug: "grains", label: "Grains",
                    subtitle: "Wheat · Maize · Paddy · Chana · Ethanol",
                    icon: "leaf.fill",
                    commodities: ["Wheat", "Maize", "Paddy", "Chana", "Ethanol / DDGS"]),
        MarketGroup(id: "edible-oils", slug: "edible-oils", label: "Edible Oils",
                    subtitle: "Palm Oil · Rice Bran · Soyabean · Sunflower · Cotton",
                    icon: "drop.fill",
                    commodities: ["Palm Oil", "Rice bran oil", "Soyabean / Oil", "Sunflower oil", "Cotton seed oil"]),
        MarketGroup(id: "others", slug: "others", label: "Others",
                    subtitle: "Crude · Precious Metals · Currency",
                    icon: "chart.bar.fill",
                    commodities: ["Crude", "Precious Metals", "Currency"]),
        MarketGroup(id: "fresh", slug: "fresh", label: "Fresh",
                    subtitle: "Potato · Cabbage · Ring Beans · Onion",
                    icon: "leaf.circle.fill",
                    commodities: ["Potato", "Cabbage / Carrot", "Ring beans", "Onion", "Potato (Mandi)"]),
        MarketGroup(id: "dry-fruits", slug: "dry-fruits", label: "Dry Fruits",
                    subtitle: "Cashew · Almond · Raisins · Groundnut · Oats · Psyllium",
                    icon: "circle.grid.3x3.fill",
                    commodities: ["Cashew", "Almond", "Raisins", "Groundnut", "Oats", "Psyllium / Isabgol"]),
        MarketGroup(id: "spices", slug: "spices", label: "Spices",
                    subtitle: "Chilli · Turmeric · Black Pepper · Cardamom",
                    icon: "flame.fill",
                    commodities: ["Chilli powder", "Turmeric", "Black pepper", "Cardamom"]),
        MarketGroup(id: "others-1", slug: "others-1", label: "Others-1",
                    subtitle: "Sugar · Milk & Dairy · Cocoa",
                    icon: "shippingbox.fill",
                    commodities: ["Sugar", "Milk / Dairy", "Cocoa"]),
    ]

    static func marketGroup(forSlug slug: String) -> MarketGroup? {
        marketGroups.first { $0.slug == slug }
    }

    // MARK: - Sidebar grouping

    enum Group: String, CaseIterable {
        case command = "Command"
        case grains = "Grains"
        case edibleOils = "Edible Oils"
        case others = "Others"
        case fresh = "Fresh"
        case dryFruits = "Dry Fruits"
        case spices = "Spices"
        case others1 = "Others-1"
        case equity = "Equity"
        case regulatory = "Regulatory"
    }

    static func group(for name: String) -> Group {
        // Check market groups
        for mg in marketGroups {
            if mg.commodities.contains(name) {
                switch mg.slug {
                case "grains": return .grains
                case "edible-oils": return .edibleOils
                case "others": return .others
                case "fresh": return .fresh
                case "dry-fruits": return .dryFruits
                case "spices": return .spices
                case "others-1": return .others1
                default: break
                }
            }
        }
        // Special categories
        switch name {
        case "Agri Weather":
            return .command
        case "DGFT Updates", "Packaging", "PIB Updates", "IMD / Advisories":
            return .regulatory
        case "Indian Equity", "Global Equity", "Crypto", "Mutual Funds":
            return .equity
        default:
            return .grains
        }
    }
}
