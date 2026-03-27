import Foundation

// Ported from server/news.ts

enum KeywordLists {
    // MARK: - India keywords (lines 22-34)
    static let indiaKeywords: [String] = [
        "india", "indian", "new delhi", "delhi", "mumbai", "bangalore", "bengaluru",
        "hyderabad", "pune", "kolkata", "chennai", "ahmedabad", "jaipur", "surat",
        "mandi", "imd", "icar", "nafed", "nccf", "fci", "ncdex", "apmc", "sebi",
        "karnataka", "maharashtra", "punjab", "haryana", "uttar pradesh", "madhya pradesh",
        "tamil nadu", "andhra pradesh", "telangana", "rajasthan", "bihar", "west bengal",
        "gujarat", "kerala", "odisha", "assam", "chhattisgarh", "jharkhand", "goa",
        "himachal", "uttarakhand", "manipur", "nagaland", "tripura", "meghalaya",
        "government of india", "ministry of agriculture", "pib", "cacp", "msp",
        "rupee", "₹", " rs.", "lakh", "crore", "sangli", "nashik", "akola",
        "indore", "bhopal", "ludhiana", "amritsar", "nagpur", "vizag", "kochi",
        "wayanad", "idukki", "nizamabad", "guntur", "nanded", "latur",
        // State abbreviations and government terms
        "chief minister", " cm ", "procurement", "quintal", "metric tonne",
        "rbi", "reserve bank", "apeda", "agmarknet",
        // Additional cities and markets
        "lucknow", "patna", "chandigarh", "agra", "varanasi", "kanpur",
        "coimbatore", "erode", "davangere", "unjha", "lasalgaon", "saurashtra",
        "rajkot", "raipur", "ranchi", "bhubaneswar", "thiruvananthapuram",
    ]

    // MARK: - India-only commodity names (line 57)
    static let indiaOnlyNames: Set<String> = ["Agri Weather"]

    // MARK: - Per-commodity title keywords (lines 60-92)
    static let commodityTitleKeywords: [String: [String]] = [
        "Wheat":              ["wheat", "atta", "durum", "gehun", "grain", "food grain", "foodgrain", "grain stock"],
        "Maize":              ["maize", "corn", "makka", "E20", "e20", "ethanol blend", "blending mandate", "blending target"],
        "Paddy":              ["paddy", "rice", "basmati", "non-basmati", "parboiled", "export rates", "thai", "vietnamese"],
        "Chana":              ["chana", "gram", "bengal gram", "kabuli", "chickpea", "pulses", "pulse", "dal", "tur", "urad", "moong", "masur", "lentil"],
        "Crude":              ["brent", "wti", "crude oil", "crude price", "nymex", "opec", "barrel", "crude palm oil", "cpo price", "oil price", "crude futures", "light crude"],
        "Precious Metals":    ["gold price", "silver price", "gold rate", "silver rate", "gold futures", "silver futures", "bullion", "comex gold", "mcx gold", "gold per gram", "gold ounce", "precious metal", "gold market", "silver market", "gold today", "silver today"],
        "Palm Oil":           ["palm oil", "crude palm oil", "palm olein", "palm kernel", "mpob", "gapki"],
        "Potato":             ["potato", "aloo"],
        "Sugar":              ["sugarcane", "molasses", "jaggery", "isma", "nfcsf", "sugar mill", "sugar price", "sugar output", "sugar export", "sugar import", "sugar production", "sugar market", "sugar stock", "raw sugar", "white sugar", "refined sugar"],
        "Ethanol / DDGS":     ["ethanol", "ddgs", "biofuel", "blending mandate", "distillers grain"],
        "Rice bran oil":      ["rice bran"],
        "Soyabean / Oil":     ["soybean", "soyabean", "soy oil", "soya", "soymeal"],
        "Sunflower oil":      ["sunflower oil", "sunflower"],
        "Cotton seed oil":    ["cottonseed", "cotton seed"],
        "Cashew":             ["cashew"],
        "Almond":             ["almond"],
        "Raisins":            ["raisin", "kishmish", "dried grape"],
        "Oats":               ["oats", "oat"],
        "Psyllium / Isabgol": ["psyllium", "isabgol"],
        "Milk / Dairy":       ["milk", "dairy", "amul", "skimmed milk", "full cream milk"],
        "Cocoa":              ["cocoa", "cacao"],
        "Chilli powder":      ["chilli", "chili", "capsicum", "mirchi", "red pepper"],
        "Turmeric":           ["turmeric", "haldi"],
        "Black pepper":       ["black pepper", "pepper"],
        "Cardamom":           ["cardamom", "elaichi"],
        "Cabbage / Carrot":   ["cabbage", "carrot"],
        "Ring beans":         ["ring bean", "kidney bean", "rajma"],
        "Onion":              ["onion"],
        "Potato (Mandi)":     ["potato", "aloo"],
        "Groundnut":          ["groundnut", "peanut"],
        "Agri Weather":       ["monsoon", "rainfall", "drought", "flood", "weather", "imd", "cyclone", "heatwave", "cold wave", "crop advisory", "forecast", "kharif", "rabi", "el nino", "el-nino", "la nina", "la-nina", "enso", "indian ocean dipole", "iod", "skymet"],
        "Indian Equity":      ["nifty", "sensex", "bse", "nse", "dalal street", "stock market", "fii", "dii", "ipo", "sebi", "midcap", "smallcap", "large cap", "largecap", "equity market", "indian market", "bank nifty"],
        "Global Equity":      ["dow jones", "s&p 500", "nasdaq", "wall street", "ftse", "nikkei", "dax", "hang seng", "global equity", "us market", "us stocks", "global market", "global stock", "s&p"],
        "Crypto":             ["bitcoin", "btc", "ethereum", "eth", "crypto", "cryptocurrency", "blockchain", "altcoin", "defi", "nft", "web3", "binance", "coinbase", "usdt", "stablecoin", "digital asset"],
        "Mutual Funds":       ["mutual fund", "nav", "sip", "amfi", "nfo", "fund house", "equity fund", "debt fund", "hybrid fund", "aum", "fund manager", "systematic investment"],
        "Currency":           ["indian rupee", "rupee", "inr", "usd/inr", "inr/usd", "rupee dollar", "rupee-dollar", "forex", "rbi intervention", "rupee falls", "rupee slides", "rupee drops", "rupee weakens", "rupee depreciation", "exchange rate", "currency market", "imported inflation", "remittance", "dollar reserves"],
    ]

    // MARK: - Noise patterns (lines 95-111)
    static let noisePatterns: [String] = [
        "word of the day", "horoscope", "recipe", "exfoliat", "skin care", "skincare",
        "weight loss", "diet tip", "data center", "semiconductor", "ai chip",
        "co-packaged optics", "celebrity", "bollywood", "cricket match", "ipl ",
        "movie review", "film review", "tv show", "web series", "ott", "stock market tip",
        "personal finance", "credit card", "loan emi", "home loan", "travel tip",
        "cornstarch", "vet-reviewed", "vet-approved", "cats eat", "dogs eat", "pets eat",
        "can cats", "can dogs", "for cats", "for dogs", "cat food", "dog food",
        "opium crop found", "opium field", "opium cultivation", "drug haul",
        "ganja field", "cannabis field", "narcotics hidden",
        "face pack", "on the face", "for your skin", "home remedy for",
        "beauty secret", "beauty routine", "beauty tip", "skin brightening",
        "for your hair", "ayurvedic remedy",
        // Additional patterns from Replit
        "gram panchayat", "gram sabha", "grampanchayat",
        "the 'gram", "'gram for", "from the 'gram", "on the 'gram",
        "vpn", "adult website", "age verification", "dating app",
        "test match", "odi match", "t20 match", "world cup final", "isl match",
        "high court overturns", "arrested for", "shot dead", "drug trafficking",
    ]

    // MARK: - Chana-specific metal exclusions (line 121-123)
    static let chanaMetalExclusions: [String] = [
        "gold", "silver", "antam", "karat", "bullion", "platinum", "jewelry", "jewellery", "precious metal",
    ]

    // MARK: - Commodity-specific exclusions (from Replit server/news.ts)
    static let commoditySpecificExclusions: [String: [String]] = [
        "Maize": ["cornrow", "cornea", "cornet", "corner kick", "cornerstone"],
        "Wheat": ["grain of salt", "wood grain", "grain leather", "film grain"],
        "Black pepper": ["pepper spray", "dr pepper", "dr. pepper", "pepper jack"],
        "Chilli powder": ["red hot chili peppers", "chilli con carne", "chili con carne", "chilli cheese"],
        "Cardamom": ["cardamom latte recipe", "cardamom tea recipe"],
        "Onion": ["the onion", "onion ring recipe", "onion soup recipe"],
        "Potato": ["couch potato", "hot potato", "potato chip recipe"],
    ]

    // MARK: - PIB commodity keywords (from pib.ts lines 7-25)
    static let pibCommodityKeywords: [String] = [
        "agri", "farm", "farmer", "kisan", "crop", "harvest", "yield", "sowing",
        "rabi", "kharif", "msp", "minimum support price", "procurement",
        "fci", "nafed", "nccf", "apmc", "apeda", "mandi",
        "wheat", "rice", "paddy", "maize", "corn", "jowar", "bajra", "barley",
        "sugar", "sugarcane", "ethanol", "frp",
        "cotton", "jute",
        "pulses", "chana", "tur", "urad", "moong", "masur", "lentil",
        "oilseed", "soybean", "groundnut", "mustard", "sunflower", "sesame", "palm",
        "onion", "tomato", "potato", "vegetable", "horticulture", "fruit",
        "cashew", "spice", "turmeric", "pepper", "guar",
        "fertilizer", "urea", "dap",
        "food", "grain", "storage", "buffer stock", "food security",
        "food processing", "food corporation",
        "irrigation", "soil", "seed", "pesticide",
        "pm-kisan", "pmkisan", "kisaan",
        "cooperative", "credit society",
        "fisheries", "animal husbandry",
    ]
}
