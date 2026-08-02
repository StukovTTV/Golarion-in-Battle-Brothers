local gNMale = [
	"Aerodus", "Akorian", "Akrem", "Alamander", "Alexite", "Alezandaru", "Andrezi", "Arioch",
	"Barek", "Belor", "Birger", "Dines", "Dolok", "Doritian", "Dortlin", "Dron", "Eilif",
	"Ellismus", "Erodel", "Eudonius", "Eugeni", "Gabradon", "Ganef", "Gannak", "Garidan",
	"Gellius", "Grachius", "Gruckalus", "Gurog", "Hargev", "Henric", "Holg", "Hyglak",
	"Iacobus", "Illsmus", "Iogorian", "Ionacu", "Iozif", "Ixiolander", "Jokum", "Kazallin",
	"Kjell", "Kriger", "Krojun", "Kronug", "Lurconarr", "Manius", "Marcellano", "Marduzi",
	"Menas", "Morvius", "Narsius", "Nonek", "Olhas", "Olytrius", "Origen", "Ostarian",
	"Ostog", "Othollo", "Pavo", "Pellius", "Petronicus", "Ragnar", "Roga", "Rutilus",
	"Shadfrar", "Silvui", "Skender", "Solangus", "Sterk", "Stichilo", "Svalk", "Takek",
	"Tallak", "Theodric", "Tiberiu", "Udhomar", "Ureste", "Ursion", "Vachedi", "Varg",
	"Viorec", "Vors", "Xantrian", "Zandu", "Zoresk", "Zstelian"
];
local gNFemale = [
	"Adula", "Ahalak", "Aliandara", "Alika", "Alinza", "Amesducias", "Anca", "Annik",
	"Asmodia", "Aspexia", "Asta", "Aswaithe", "Aula", "Belende", "Belka", "Beshkee",
	"Bordana", "Boudra", "Carmelizzia", "Chammady", "Charito", "Dagny", "Dagur", "Drulia",
	"Emalliandra", "Estrude", "Eudomia", "Euphemi", "Fesha", "Gerda", "Gunda", "Hege",
	"Iaome", "Ileosa", "Ilinica", "Imenda", "Imperia", "Ingirt", "Inkit", "Iolana",
	"Iomestria", "Ionnia", "Jalket", "Jorun", "Kala", "Kale", "Komana", "Korva", "Lesit",
	"Luminita", "Mirelinda", "Nalket", "Nalmida", "Narcizia", "Nicinniana", "Noravia",
	"Novennia", "Ommarra", "Oviento", "Pasara", "Pavanna", "Piousa", "Pontia", "Quinta",
	"Rulla", "Runa", "Salvianella", "Selka", "Shelen", "Signe", "Tanjah", "Tekrakai", "Tine",
	"Udarrin", "Ulionestria", "Valeria", "Valki", "Varka", "Vibia", "Viniana", "Xemne",
	"Yala", "Yavenee", "Zeldana", "Zova", "Zriorica"
];
local gSMale = [
	"Aakif", "Akkuya", "Amare", "Arasmes", "Bahram", "Bala", "Barid", "Dadshi", "Dahrehn",
	"Darvan", "Hava", "Ik-Teshup", "Irizati", "Jaali", "Jawara", "Jirani", "Jiri", "Khair",
	"Kito", "Kobad", "Krama", "Manujyestha", "Melaku", "Omari", "Ormizd", "Parumartish",
	"Pratavh", "Rani", "Rubani", "Rusmanya", "Sefu", "Sumna", "Warezana", "Xoshak", "Yantur",
	"Zahur", "Zuri"
];
local gSFemale = [
	"Abha", "Akina", "Amara", "Amestri", "Artazostra", "Ashia", "Barezata", "Deka", "Eshe",
	"Hasina", "Hema", "Hirati", "Isa", "Iuni", "Izora", "Jayazi", "Jini", "Kahina",
	"Kamaria", "Khismia", "Kyra", "Leyli", "Malkia", "Naadhira", "Nanya", "Nigana", "Pendah",
	"Raziya", "Revhi", "Sahba", "Sajna", "Shirin", "Utana", "Vilama", "Waajida", "Xemestra",
	"Zaci", "Zalika", "Zarishu"
];
local gNorseF = [
	"Annik", "Asta", "Belende", "Belka", "Dagny", "Dagur", "Fesha", "Gerda", "Gunda", "Hege",
	"Ingirt", "Inkit", "Jalket", "Jorun", "Kala", "Lesit", "Nalket", "Runa", "Selka",
	"Shelen", "Signe", "Tine", "Valki", "Varka", "Yala"
];
local gNHMale = [
	"Abroshtor", "Adesha", "Aerel", "Agiz", "Aja", "Ak", "Akaash", "Alk", "Amarandlon",
	"Andanan", "Antal", "Aoukar", "Arasheg", "Arcavato", "Arim", "Aritian", "Arkkak",
	"Arkus", "Aronok", "Ashka", "Ashpaka", "Athraz", "Ausk", "Aven", "Bankanir", "Barashk",
	"Baru", "Bastarger", "Beltin", "Bokker", "Boram", "Bouzaglu", "Brihz", "Calondrel",
	"Carangal", "Carrug", "Carruth", "Cavathes", "Cernan", "Chichipi", "Chimon", "Chuko",
	"Crinto", "Cronwier", "Davor", "Dellisar", "Denat", "Dharak", "Djir", "Dolgra",
	"Dolgrin", "Dorduken", "Dorodara", "Dorsavnil", "Drewan", "Drosil", "Drovic", "Duardlon",
	"Dyrtrax", "Edal", "Edrukk", "Efit", "Eitsanara", "Elum", "Elun", "Encinal", "Enshuk",
	"Eomva", "Eran", "Erevel", "Espes", "Essaru", "Eydan", "Fazij", "Felaelrel", "Felzak",
	"Fentanas", "Ferrus", "Ferus", "Firyin", "Frum", "Garija", "Gerran", "Ghiv", "Gishkim",
	"Gorumax", "Gouard", "Grunyar", "Grur", "Grytnok", "Guln", "Guzmuk", "Haangeno",
	"Hagors", "Hakak", "Hakon", "Halhat", "Halungalom", "Hamako", "Hanuun", "Haohiko",
	"Harsk", "Hasa", "Hazi", "Heldalel", "Huanu", "Igmar", "Ikyamek", "Ilamin", "Inishish",
	"Iradli", "Izkrael", "Jalij", "Jamash", "Jamir", "Jaraerdrel", "Jegan", "Jekkajak",
	"Jeydavu", "Kaelmourn", "Kaidynn", "Kakkariel", "Kaleb", "Kalmant", "Kana", "Karum",
	"Kaya", "Kazmuk", "Keegyn", "Kirrok", "Kitsukou", "Kizziar", "Kon", "Kora", "Krajasik",
	"Kremernesh", "Krobby", "Krolmnite", "Kutak", "Kuwana", "Kwan-la", "Kyras", "Lanliss",
	"Lem", "Liek", "Lirtae", "Loohi", "Losk", "Lumrolur", "Maakor", "Makoa", "Maldrek",
	"Malgroar", "Maqej", "Marrak", "Maudril", "Mazmord", "Meirdrarel", "Mentys", "Meotrai",
	"Merlokrep", "Mirn", "Mirrendier", "Molos", "Morgrym", "Mossarah", "Murdut", "Nammem",
	"Narinso", "Narnel", "Narrin", "Nasha", "Nassaler", "Neeka", "Neg", "Nesteruk", "Ninnec",
	"Nulrakgrult", "Nydryn", "Nyktan", "Nyktox", "Odol", "Okrin", "Omgot", "Ondir", "Onok",
	"Oret", "Otoniel", "Padrym", "Parant", "Paravata", "Passag", "Pharnox", "Poshment",
	"Prabur", "Pularrka", "Quiray", "Quokgol", "Radid", "Ranzak", "Rarorel", "Rerdahl",
	"Rickle", "Rikkan", "Rocur", "Rogar", "Roprutu", "Rouqar", "Ruk", "Ruun", "Ryzztyl",
	"Sarvin", "Sarzuket", "Satinder", "Seldlon", "Seltyiel", "Sevastin", "Sheni",
	"Shiradahz", "Shoremoth", "Shukuris", "Shulkuru", "Siival", "Sithundan", "Skivven",
	"Slatark", "Somar", "Sorsul", "Stigmar", "Sumak", "Syrendross", "Tak-Tak", "Takasha",
	"Talaro", "Talathel", "Talogan", "Tamoq", "Tasi", "Temerith", "Tenzekil", "Tespa",
	"Thathona", "Tizkar", "Tongtokl", "Torphrex", "Troxell", "Truddig", "Tsadok",
	"Tsukotarra", "Tup", "Tural", "Turenne", "Ulu", "Unglert", "Unulu", "Urah", "Urtar",
	"Utakish", "Variel", "Varknarnost", "Varrann", "Vasaam", "Vaski", "Vivatu", "Voren",
	"Vreknog", "Wakla", "Woiak", "Wyran", "Xahndyg", "Xurshuklo", "Yetar", "Yonk", "Yonsol",
	"Yulbin", "Zaigan", "Zakkar", "Zathra", "Zatqualmie", "Zelkekek", "Zibini", "Zirul",
	"Zithembe", "Zoka", "Zokaratz", "Zordlon", "Zoren", "Zov"
];
local gNHFemale = [
	"Acera", "Adesha", "Afzara", "Agna", "Ahmmra", "Ak", "Alayi", "Allizsah", "Alyara",
	"Amelisce", "Amrunelara", "Anafa", "Anjaz", "Arasheg", "Arinet", "Arken", "Arkkak",
	"Arsinoe", "Ashka", "Ashpaka", "Ava", "Azzlyn", "Baarah", "Bani", "Barashk", "Bellis",
	"Belmarniss", "Besh", "Bessel", "Besthana", "Bodill", "Bokker", "Butoi", "Calah",
	"Cannan", "Cathlessra", "Cathran", "Chandira", "Chichipi", "Chuko", "Crinto",
	"Cylellinth", "Dalbra", "Dardlara", "Davina", "Dei", "Dolgra", "Dorodara", "Drinma",
	"Drogeda", "Duline", "Durra", "Eandi", "Echane", "Eireen", "Eitsanara", "Elneth",
	"Eloqi", "Emraeal", "Enga", "Enshuk", "Eomva", "Erigga", "Eskani", "Espes", "Essaru",
	"Etun", "Etwa", "Faunra", "Ferrus", "Fhar", "Fijit", "Filiu", "Frum", "Gant", "Garija",
	"Ghatiyara", "Giama", "Gishkim", "Gonild", "Goruza", "Grillgiss", "Grymwyr", "Guzmuk",
	"Gynnezz", "Haangeno", "Halhat", "Hamako", "Haohiko", "Hasa", "Hazi", "Horinnia", "Hoya",
	"Huanu", "Iandoli", "Ikyamek", "Ilvaria", "Ilyat", "Ilyin", "Imdlara", "Imesah", "Inam",
	"Indranna", "Ingra", "Inishish", "Inva", "Irice", "Iryani", "Jathal", "Jilyana", "Jix",
	"Johysis", "Jynnjun", "Kakkariel", "Kana", "Kasidra", "Kaya", "Keeya", "Kieyanna",
	"Kifah", "Kilarra", "Kitch", "Kitsukou", "Komtri", "Kon", "Kora", "Korumun", "Kregnaan",
	"Krobby", "Krugga", "Kubi", "Kutak", "Kuwana", "Kwan-la", "Leffit", "Liada", "Lim",
	"Lini", "Lirtae", "Lissa", "Lissi", "Loohi", "Lorceli", "Loscivia", "Lupp", "Lyrtrahk",
	"Maarin", "Maddeva", "Majet", "Maqan", "Maraedlara", "Marra", "Marrak", "Masozi",
	"Mazmord", "Mazon", "Mellisan", "Melrynn", "Meotrai", "Merisiel", "Mihalyi", "Milah",
	"Miniri", "Moranassa", "Mordren", "Moritla", "Morstra", "Mossarah", "Nadkarni",
	"Nahmias", "Nammem", "Nasha", "Nava", "Neeka", "Nefi", "Nehm", "Nijena", "Nimanisi",
	"Niramour", "Nisha", "Noranillim", "Nordlara", "Nylgune", "Nysene", "Olbin", "Omgot",
	"Onana", "Ondrea", "Onok", "Oparal", "Pai", "Paldna", "Pantoja", "Paravata", "Pari",
	"Pashe", "Petrahk", "Piria", "Praeldral", "Pularrka", "Qari", "Queck", "Radabeh",
	"Radaya", "Ranzak", "Rarorel", "Reda", "Renza", "Rhialla", "Rickle", "Rilla", "Rissi",
	"Roprutu", "Ruk", "Rusilka", "Ruun", "Ryzzntyg", "Rzonca", "Sami", "Saroun", "Sevastin",
	"Shalelu", "Sheni", "Shirish", "Shulkuru", "Siphelele", "Sistra", "Skyxa", "Sophone",
	"Sorsul", "Soumral", "Stinna", "Sucheta", "Suzhen", "Tak-Tak", "Takasha", "Talaro",
	"Tamarie", "Tasi", "Tena", "Tespa", "Tessarda", "Tevaga", "Thathona", "Thikka", "Tiyeri",
	"Tizkar", "Torra", "Trin", "Trisgrak", "Tsukotarra", "Tup", "Tyrrell", "Tyvorhan",
	"Ulrikka", "Ulu", "Ulumbralya", "Unulu", "Urdahna", "Urriona", "Utakish", "Vaga",
	"Valtyra", "Varaera", "Varshez", "Vaski", "Vivatu", "Volundeil", "Vortiga", "Vregma",
	"Wakla", "Yalandlara", "Yamyra", "Yangrit", "Yonk", "Yonsol", "Yulbin", "Zaitherin",
	"Zakkar", "Zarrnyl", "Zathra", "Zeljka", "Zelkekek", "Zetaya", "Zheit", "Zibini",
	"Zokaratz"
];
local HSHARE = 0.8;
local function gBlend(human, nonhuman) {
	local k = 1;
	if (human.len() > 0)
		k = (((HSHARE / (1.0 - HSHARE)) * nonhuman.len()) / human.len() + 0.5).tointeger();
	if (k < 1) k = 1;
	local a = [];
	for (local i = 0; i < k; i++) a.extend(human);
	a.extend(nonhuman);
	return a;
}
::Const.Strings.CharacterNames           = gBlend(gNMale,   gNHMale);
::Const.Strings.CharacterNamesFemale     = gBlend(gNFemale, gNHFemale);
::Const.Strings.CharacterNamesFemaleNorse= gBlend(gNorseF,  gNHFemale);
::Const.Strings.SouthernNames            = gBlend(gSMale,   gNHMale);
::Const.Strings.SouthernFemaleNames      = gBlend(gSFemale, gNHFemale);
